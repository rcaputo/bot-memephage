# $Id$

# The PerlMud web client portion of our program.

use strict;

package Client::Web;

use POE;

use URI;
use URI::Heuristic qw(uf_uri);

use HTTP::Date;
use HTTP::Request;

use POE::Component::JobQueue;
use POE::Component::Client::DNS;
use POE::Component::Client::HTTP;

use PoeLinkManager;

# enable more output
sub DEBUG () { 0 }

sub MAX_GET_SIZE   () { 4096 }
sub CHECK_PERIOD   () { 3600 }           # seconds between staleness checks
sub MAX_FRESH_AGE  () { 3600 * 24 * 7 }  # seconds between link recheckes

sub RESOLVER_TIMEOUT () { 30 }
sub HTTP_TIMEOUT     () { 30 }

#------------------------------------------------------------------------------
# Set up components that will help us out.

# Fetch DNS records for each domain so we know they resolve.
# Sometimes resolver activity is the longest thing to wait for; this
# pre-fetches hosts into our nameserver cache.  Asynchronously.

POE::Component::Client::DNS->spawn
  ( Alias   => 'resolver',
    Timeout => RESOLVER_TIMEOUT,
  );

# Fetch HTTP requests.

POE::Component::Client::HTTP->spawn
  ( Alias   => 'fetcher',
    Agent   =>
    "Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:0.9.4) Gecko/20010928",
    MaxSize => MAX_GET_SIZE,
    Timeout => HTTP_TIMEOUT,
  );

# Job queue to limit the number of simultaneous links to check.

POE::Component::JobQueue->spawn
  ( Alias       => 'linkchecker',
    WorkerLimit => 4,
    Passive     =>
    {
    },
    Worker      => sub {
      my ($postback, $link_id) = @_;
      DEBUG and warn "spawning a worker to handle link \#$link_id";
      POE::Session->create
        ( inline_states =>
          { _start   => \&check_start,
            got_name => \&check_got_name,
            got_head => \&check_got_head,
            got_body => \&check_got_body,
          },
          args => [ $postback, $link_id ]
        );
    },
  );

sub check_start {
  my ($kernel, $heap, $postback, $link_id) = @_[KERNEL, HEAP, ARG0, ARG1];
  my $link = get_link_by_id($link_id);

  $heap->{link_id}  = $link_id;
  $heap->{link}     = $link;
  $heap->{redirect} = $link;
  $heap->{postback} = $postback;
  $heap->{loop}     = { $link => 1 };

  # This doesn't handle the login@pass form of hostname.  Use URI or
  # something that parses these right.

  my ($host) = ($link =~ m{//([^:/]+)});
  unless (defined $host) {
    link_set_status( $link_id, "Could not determine hostname to resolve." );
    return;
  }

  DEBUG and warn "trying to resolve host <$host>\n";

  $kernel->post( resolver => resolve => got_name => $host => 'ANY' );
}

sub check_got_name {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my ($response_packet, $response_error) = @{$_[ARG1]};

  unless (defined $response_packet) {
    link_set_status( $heap->{link_id}, "Resolver error: $response_error" );
    return;
  }

  DEBUG and warn "host for <$heap->{link}> resolved ok\n";
  link_set_status( $heap->{link_id}, "Host resolved ok." );

  # Build a HEAD request.
  my $head_request = HTTP::Request->new( HEAD => $heap->{link} );
  my $url = URI->new( $heap->{link} );
  $url = uf_uri($url);
  $head_request->url( $url );

  DEBUG and warn "fetching HEAD for <$heap->{link}>\n";

  # Get HEAD from the server.
  $kernel->post( fetcher => request => got_head => $head_request );
}

sub check_got_head {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $request  = $_[ARG0]->[0];
  my $response = $_[ARG1]->[0];

  my $link = $heap->{link};
  my $link_id = $heap->{link_id};

  if (defined $response) {
    link_set_status( $link_id, "HEAD " .
                     ( defined($response->code())
                       ? $response->code()
                       : "(undef)"
                     ) . ": " .
                     ( defined($response->message())
                       ? $response->message()
                       : "(undef)"
                     )
                   );
  }

  return unless defined $response->code();

  # It's a redirect?!  Redirect!
  my $code = $response->code();
  if ( $code == 301 or # moved permamently
       $code == 302 or # found (see here)
       $code == 303 or # see other
       $code == 307    # temporary redirect
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

    link_set_redirect($link_id, $location);

    DEBUG and warn "redirecting from <$heap->{link}> to <$location>\n";

    $kernel->post( fetcher => request => got_head => $referral );
    return;
  }

  my $type = 'text/guessed';
  my $size = "(unknown)";
  if ($response->is_success()) {
    DEBUG and warn "parsing HEAD for <$heap->{redirect}>\n";

    if (defined $response->last_modified()) {
      link_set_head_time($link_id, str2time($response->date(), 'GMT'));
    }

    $type = $response->content_type();
    $type = 'text/guessed' unless defined $type;
    link_set_head_type($link_id, $type);

    $size = $response->content_length();
    $size = '(unknown)' unless defined $size;
    link_set_head_size($link_id, $size);

    if (defined $response->title()) {
      link_set_title($link_id, $response->title());
    }
  }
  else {
    # HEAD 405: Method Not Allowed.  We'll try GET anyway.
    return unless $response->code() == 405;
  }

  # Try to fetch more information from the page's headers.
  if ($type =~ /text/) {
    my $body_request = HTTP::Request->new( GET => $heap->{redirect} );
    my $url = URI->new( $heap->{redirect} );
    $url = uf_uri($url);
    $body_request->url( $url );

    # Limit the request size.
    $body_request->push_header( Range => "bytes=0-" . MAX_GET_SIZE );

    DEBUG and warn "fetching body for <$heap->{redirect}>\n";

    $kernel->post( fetcher => request => got_body => $body_request );
  }
}

sub check_got_body {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $request  = $_[ARG0]->[0];
  my $response = $_[ARG1]->[0];

  my $link = $heap->{link};
  my $link_id = $heap->{link_id};

  link_set_status( $link_id, "GET " .
                   ( defined($response->code())
                     ? $response->code()
                     : "(undef)"
                   ) . ": " .
                   ( defined($response->message())
                     ? $response->message()
                     : "(undef)"
                   )
                 );

  return unless defined $response->code();

  DEBUG and warn "got BODY response for <$heap->{redirect}>\n";

  return unless $response->is_success();

  DEBUG and warn "BODY fetch is successful for <$heap->{redirect}>\n";

  if (defined $response->last_modified()) {
    link_set_head_time($link_id, str2time($response->date(), 'GMT'));
  }

  my $type = $response->content_type();
  $type = 'text/guessed' unless defined $type;
  link_set_head_type($link_id, $response->content_type());

  # Update the response code if this was a successful full GET.  Do it
  # anyway if the previous fetch didn't return a size.

  my $previous_size = link_get_head_size($link_id);
  if ( $response->code() == 200 or
       !defined($previous_size) or
       !$previous_size
     ) {
    link_set_head_size($link_id, "(unknown)");
  }

  if (defined $response->title()) {
    link_set_title($link_id, $response->title());
  }

  my $redirect = $heap->{redirect};

  if ($link ne $redirect) {
    link_set_redirect($link_id, $redirect);
  }

  # Rocco should probably be shot for parsing HTML with regular
  # expressions.

  if ($type =~ /text/i) {
    my $content = $response->content();
    $content =~ s/\s+/ /g;

    if ($content =~ m{< *title *> *(.+?) *< */ *title *>}i) {
      link_set_title($link_id, $1);
    }

    if ( $content =~
	 m{< *meta *name *= *"description" *content *= *\" *([^\"<>]+) *\" *>}i
       ) {
      link_set_meta_desc($link_id, $1);
    }

    if ( $content =~
	 m{< *meta *name *= *"keywords" *content *= *\" *([^\"<>]+) *\" *>}i
       ) {
      link_set_meta_keys($link_id, $1);
    }
  }
}

#------------------------------------------------------------------------------
# Periodically check stuff.  First when the server is started, and
# then every hour.

POE::Session->new
  ( _start => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];
      $heap->{pending} = { };

      # Gather unchecked links.

      my @unchecked = get_unchecked_links();
      foreach my $link_id (@unchecked) {
        unless (exists $heap->{pending}->{$link_id}) {
          $heap->{pending}->{$link_id} = 1;
          $kernel->post( linkchecker => enqueue => got_response =>
                         $link_id,
                       );
        }
      }

      # Add stale links into the mix.
      
      $kernel->yield( 'check_stale' );
    },

    # Periodically check stale links.  This and the got_response state
    # manage a hash of pending links so that links aren't checked more
    # than necessary if the queue is running slowly.

    check_stale => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Gather stale links (older than MAX_FRESH_AGE).

      my @stale = get_stale_links( MAX_FRESH_AGE );
      foreach my $link_id (@stale) {
        unless (exists $heap->{pending}->{$link_id}) {
	  $heap->{pending}->{$link_id} = 1;
          $kernel->post( linkchecker => enqueue => got_response =>
                         $link_id,
                       );
        }
      }

      # Go around again in a little while.
      $kernel->delay( check_stale => CHECK_PERIOD );
    },

    # When linkchecker returns us a response, the query parameter is
    # the ID of the link we asked it to check.  Delete that from the
    # pending hash.

    got_response => sub {
      my $heap = $_[HEAP];
      my $link_id = $_[ARG0]->[0];
      delete $heap->{pending}->{$link_id};
    },
  );

#------------------------------------------------------------------------------
1;
