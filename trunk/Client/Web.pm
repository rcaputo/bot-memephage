# $Id$

# The PerlMud web client portion of our program.

use strict;

package PoeWebClient;

use lib '/home/troc/perl/poco/jobqueue/blib/lib';
use lib '/home/troc/perl/poco/client-dns/blib/lib';
use lib '/home/troc/perl/poco/client-http/blib/lib';

use POE;

use URI;
use URI::Heuristic qw(uf_uri);

use HTTP::Date;
use HTTP::Request;

use POE::Component::JobQueue;
use POE::Component::Client::DNS;
use POE::Component::Client::HTTP;

use PoeLinkManager;

sub MAX_GET_SIZE   () { 4096 }
sub CHECK_PERIOD   () { 3600 }           # seconds between staleness checks
sub MAX_FRESH_AGE  () { 3600 * 24 * 7 }  # seconds between link recheckes

#------------------------------------------------------------------------------
# Set up components that will help us out.

# Fetch DNS records for each domain so we know they resolve.
# Sometimes resolver activity is the longest thing to wait for; this
# pre-fetches hosts into our nameserver cache.  Asynchronously.

POE::Component::Client::DNS->spawn
  ( Alias   => 'resolver',
    Timeout => 60,
  );

# Fetch HTTP requests.

POE::Component::Client::HTTP->spawn
  ( Alias   => 'fetcher',
    Agent   =>
    "Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:0.9.4) Gecko/20010928",
    MaxSize => MAX_GET_SIZE,
  );

# Job queue to limit the number of simultaneous links to check.

POE::Component::JobQueue->spawn
  ( Alias       => 'linkchecker',
    WorkerLimit => 1,
    Passive     =>
    {
    },
    Worker      => sub {
      my ($postback, $link) = @_;
      POE::Session->create
        ( inline_states =>
          { _start   => \&check_start,
            got_name => \&check_got_dns,
            got_head => \&check_got_head,
            got_body => \&check_got_body,
          },
          args => [ $postback, $link ]
        );
    },
  );

sub check_start {
  my ($kernel, $heap, $postback, $link) = @_[KERNEL, HEAP, ARG0, ARG1];

  $heap->{link}     = $link;
  $heap->{redirect} = $link;
  $heap->{postback} = $postback;
  $heap->{loop}     = { $link => 1 };

  # This doesn't handle the login@pass form of hostname.  Use URI or
  # something that parses these right.

  my ($host) = ($link =~ m{//([^:/]+)});
  unless (defined $host) {
    link_set_status( $link, "Could not determine hostname to resolve." );
    return;
  }

  $kernel->post( resolver => resolve => got_name => $host => 'ANY' );
}

sub check_got_dns {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my ($response_packet, $response_error) = @{$_[ARG1]};

  unless (defined $response_packet) {
    link_set_status( $heap->{link}, "Resolver error: $response_error" );
    return;
  }

  # The actual responses don't matter.
  my $head_request = HTTP::Request->new( HEAD => $heap->{link} );
  my $url = URI->new( $heap->{link} );
  $url = uf_uri($url);
  $head_request->url( $url );

  $kernel->post( fetcher => request => got_head => $head_request );
}

sub check_got_head {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $request  = $_[ARG0]->[0];
  my $response = $_[ARG1]->[0];

  my $link = $heap->{link};

  link_set_status( $link, "HEAD " .
                   ( defined($response->code())
                     ? $response->code()
                     : "(undef)"
                   ) . ": " .
                   ( defined($response->message())
                     ? $response->message()
                     : "(undef)"
                   )
                 );

  # It's a redirect?!  Redirect!
  my $code = $response->code();
  if ( defined $code and
       ( $code == 301 or # moved permamently
         $code == 302 or # found (see here)
         $code == 303 or # see other
         $code == 307    # temporary redirect
       )
     ) {
    my $location = $response->header('Location');
    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
    my $base = $response->base;
    $location = URI->new($location, $base)->abs($base);
    $location = uf_uri($location);

    return if exists $heap->{loop}->{$location};

    my $referral = $request->clone();
    $referral->url($location);

    $heap->{redirect} = $location;
    $heap->{loop}->{$location} = 1;

    $kernel->post( fetcher => request => got_head => $referral );
    return;
  }

  return unless defined $response->code();
  return unless $response->is_success;

  if (defined $response->last_modified()) {
    link_set_head_time($link, str2time($response->date(), 'GMT'));
  }

  my $type = $response->content_type();
  if (defined $type) {
    link_set_head_type($link, $response->content_type());
  }
  else {
    $type = 'text';
  }

  my $size = $response->content_length();
  if (defined $size) {
    link_set_head_size($link, $response->content_length());
  }
  else {
    $size = MAX_GET_SIZE;
  }

  if (defined $response->title()) {
    link_set_title($link, $response->title());
  }

  # Build a partial request thing.
  if ($type =~ /text/i) {
    my $get = HTTP::Request->new( GET => $heap->{redirect} );
    my $max_get_size = $size;
    $max_get_size = MAX_GET_SIZE if $max_get_size > MAX_GET_SIZE;
    $get->push_header( Range => "bytes=0-$max_get_size" );

    $kernel->post( fetcher => request => got_body => $get );
  }
}

sub check_got_body {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $request  = $_[ARG0]->[0];
  my $response = $_[ARG1]->[0];

  my $link = $heap->{link};
  my $redirect = $heap->{redirect};

  link_set_status( $link, "GET " . $response->code() . ": " .
                   $response->message()
                 );
  return unless $response->is_success;

  my $content = $response->content();
  $content =~ s/\s+/ /g;

  if ($content =~ m{< *title *> *(.+?) *< */ *title *>}i) {
    link_set_title($link, $1);
  }

  if ( $content =~
       m{< *meta *name *= *"description" *content *= *\" *([^\"<>]+) *\" *>}i
     ) {
    link_set_meta_desc($link, $1);
  }

  if ( $content =~
       m{< *meta *name *= *"keywords" *content *= *\" *([^\"<>]+) *\" *>}i
     ) {
    link_set_meta_keys($link, $1);
  }

  if ($link ne $redirect) {
    link_set_redirect($link, $redirect);
  }
}

#------------------------------------------------------------------------------
# Periodically check stuff.  First when the server is started, and
# then every hour.

POE::Session->new
  ( _start => sub {
      my $heap = $_[HEAP];
      $heap->{pending} = { };

      # Gather unchecked links.
      my @unchecked = get_unchecked_links();
      foreach (@unchecked) {
	$heap->{pending}->{$_} = 1;
      }

      # Add stale links into the mix.
      $_[KERNEL]->yield( 'check_stale' );
    },
    check => sub {
      my $heap = $_[HEAP];

      # Gather pending links to check, and clear the pending buffer.
      my @pending = keys %{$heap->{pending}};
      $heap->{pending} = { };

      # Enqueue a check task for each.
      foreach (@pending) {
        $_[KERNEL]->post( linkchecker => enqueue => 'ignore' => get_link($_) );
      }

      # Check for stale links again in a little while.
      $_[KERNEL]->delay( check_stale => CHECK_PERIOD );
    },
    check_stale => sub {
      my $heap = $_[HEAP];

      # Gather stale links (older than MAX_FRESH_AGE).
      my @stale = get_stale_links( MAX_FRESH_AGE );
      foreach (@stale) {
	$heap->{pending}->{$_} = 1;
      }

      # Do the actual check.
      $_[KERNEL]->yield( 'check' );
    },
  );

#------------------------------------------------------------------------------
1;
