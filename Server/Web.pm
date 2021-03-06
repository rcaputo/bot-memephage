# The PerlMud web server portion of our program.

use strict;

package Server::Web;

use Socket;
use HTTP::Response;

use POE::Session;
use POE::Preprocessor;
use POE::Component::Server::TCP;
use POE::Filter::HTTPD;

use Util::Conf;
use Util::Web;
use Util::Link;

# Dumps the request to stderr.
sub DUMP_REQUEST () { 0 }

sub WEBLOG_TYPE () { "weblog" }

macro table_method (<header>) {
  "<tr><td><header></td><td>" . $request-><header>() . "</td></tr>"
}

macro table_header (<header>) {
  "<tr><td><header></td><td>" . $request->header('<header>') . "</td></tr>"
}

#------------------------------------------------------------------------------
# A web server.

# Start an HTTPD session.  Note that this handler receives both the
# local bind() address ($my_host) and the public server address
# ($my_ifname).  It uses $my_ifname to build HTML that the outside
# world can see.

sub httpd_session_started {
  my ( $heap,
       $socket, $remote_address, $remote_port,
       $my_name, $my_host, $my_port, $my_ifname, $login, $passwd,
     ) = @_[HEAP, ARG0..ARG8];

  # TODO: I think $my_host is obsolete.  Maybe it can be removed, and
  # $my_ifname can be used exclusively?

  $heap->{my_host} = $my_host;
  $heap->{my_port} = $my_port;
  $heap->{my_name} = $my_name;
  $heap->{my_inam} = $my_ifname;
  $heap->{login}   = $login;
  $heap->{passwd}  = $passwd;

  $heap->{remote_addr} = inet_ntoa($remote_address);
  $heap->{remote_port} = $remote_port;

  $heap->{wheel} = new POE::Wheel::ReadWrite
    ( Handle       => $socket,
      Driver       => new POE::Driver::SysRW,
      Filter       => new POE::Filter::HTTPD,
      InputEvent   => 'got_query',
      FlushedEvent => 'got_flush',
      ErrorEvent   => 'got_error',
    );
}

# An HTTPD response has flushed.  Stop the session.
sub httpd_session_flushed {
  delete $_[HEAP]->{wheel};
}

# An HTTPD session received an error.  Stop the session.
sub httpd_session_got_error {
  my ($session, $heap, $operation, $errnum, $errstr) =
    @_[SESSION, HEAP, ARG0, ARG1, ARG2];
  warn( "connection session ", $session->ID,
        " got $operation error $errnum: $errstr\n"
      );
  delete $heap->{wheel};
}

# Process HTTP requests.
sub httpd_session_got_query {
  my ($heap, $request) = @_[HEAP, ARG0];

  ### Log the request.

  # Space-separated list:
  # Remote address (client address)
  # -
  # -
  # [GMT date in brackets: DD/Mon/CCYY:HH:MM:SS -0000]
  # "GET url HTTP/x.y"  <-- in quotes
  # response code
  # response size
  # referer
  # user-agent string

  ### Responded with an error.  Send it directly.

  if ($request->isa("HTTP::Response")) {
    $heap->{wheel}->put($request);
    return;
  }

  ###---------------------------------------------
  ### These requests don't require authentication.
  ###---------------------------------------------

  my $url = $request->url() . '';

  ### Root page.

  if ($url eq '/') {
    my $response = HTTP::Response->new(200);
    $response->push_header( 'Content-type', 'text/html' );

    $response->content
      ( "<html><head><title>$heap->{my_name} main menu</title></head>" .
        "<body>" .
        "<ul>" .
        "<li><a href='/recent/5'>Five most recent links</a>" .
        "<li><a href='/recent/10'>Ten most recent links</a>" .
        "<li><a href='/recent/25'>Twenty-five most recent links</a>" .
        "<li><a href='/recent/50'>Fifty most recent links</a>" .
        "<li><a href='/recent/100'>Hundred most recent links</a>" .
	"<li><a href='/since/'>Links from the last hour</a>" .
        "</ul>" .
        "<p>" .
        "To make submissions easier, this javascript link will add " .
        "whatever page is currently visible in your browser.  If your " .
        "browser supports it, the confirmation page will appear in a " .
        "new window." .
        "</p>" .
        "<a href=\"javascript:void(window.open('http://" .
        "$heap->{my_inam}:$heap->{my_port}/add?'+location.href))" .
        "\">" .
        "Send link to $heap->{my_name}</a>." .
        "</p>" .
        "It's really convenient as a bookmark, especially in a toolbar."
      );

    $heap->{wheel}->put( $response );
    return;
  }

  ### Deny robots.

  if ($url eq '/robots.txt') {
    my $response = HTTP::Response->new(200);
    $response->push_header( 'Content-type', 'text/plain' );
    $response->content
      ( "User-agent: *\x0d\x0a" .
        "Disallow: /\x0d\x0a"
      );
    $heap->{wheel}->put($response);
    return;
  }

  ### Add a link via the web.  For example, via a javascript bookmark.

  if ($url =~ /^\/add\?(.+?)\s*$/) {
    my $link = $1;

    my $response = HTTP::Response->new(200);
    $response->push_header( 'Content-type', 'text/html' );

    if ($link =~ s/(http:\/\/\S*)/$1/) {
      $_[KERNEL]->yield( do => sub {
        get_link_id( "web", @_[ARG0..ARG1], "[link]" );
      }, "$heap->{remote_addr}:$heap->{remote_port}", $1 );

      $response->content
        ( "<html><head><title>$heap->{my_name} thanks you</title></head>" .
          "<body>" .
          "<p>" .
          "Thanks for submitting <tt>$link</tt> to " .
          "<a href='/'>$heap->{my_name}</a>." .
          "</p>" .
          "</body>" .
          "</html>"
        );
    }
    else {
      $response->content
        ( "<html><head><title>$heap->{my_name} thanks you</title></head>" .
          "<body>" .
          "<p>" .
          "Thanks for submitting <tt>$link</tt> to " .
          "<a href='/'>$heap->{my_name}</a>.  However, it cannot accept " .
          "this type of link at this time." .
          "</p>" .
          "</body>" .
          "</html>"
        );
    }

    $heap->{wheel}->put( $response );
    return;
  }

  if ($url =~ /^\/post$/) {

    # spawn off a session to do the actual parsing
    $_[KERNEL]->yield( do => sub {
      my $content = $_[ARG0];
      $content =~ tr/+/ /;
      $content =~ s/%([a-fA-F0-9]{2})/pack("C", hex($1))/eg;
      $content =~ s/^\w+=//;
      my ($description, @links) = parse_link_from_message($content);
      $description = "(none)"
        unless defined $description and length $description;

      foreach my $link (@links) {
        next unless defined $link and length $link;
        # spawn off a session to do the actual link fetching
        $_[KERNEL]->yield( do => sub {
          get_link_id("web", @_[ARG0..ARG1], "[email]");
        }, $_[ARG1], $link );
      }
    }, $request->content, "$heap->{remote_addr}:$heap->{remote_port}" );

    my $response = HTTP::Response->new(200);
    $response->content(
      'Thanks!'
    );

    $heap->{wheel}->put( $response );
    return;
  }

  ### Do basic authentication if specified in config file.

  my $do_auth = (defined($heap->{login}) and defined($heap->{passwd}));
  my ($login, $password) = $request->authorization_basic() if $do_auth;

  unless ( ! $do_auth or
	   (defined($login) and ($login eq $heap->{login}) and
	    defined($password) and ($password eq $heap->{passwd}))
         )
  {
    my $response = new HTTP::Response(401);
    $response->push_header('WWW-Authenticate', 'Basic realm="memephage"');
    $response->push_header('Server', 'memephage/1.0');
    $response->push_header('Content-Type', 'text/html');
    $response->content
      ( '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN"> ' .
        '<html>' .
        '<head>' .
        '<title>WARNING: You are in a restricted area.</title>' .
        '<link rev="made" href="mailto:troc@netrus.net">' .
        '</head>' .
        '<body bgcolor="#C00000" text="#FFFFFF" link="#00FF00" ' .
        'vlink="#00FF00">' .
        '<table border=0 cellspacing=0 width="100%" height="100%">' .
        '<tr>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '<td align=center colspan=7><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#FFFF00" width="6%"><font size="7">&#160;</font></td>' .
        '<td align=center colspan=7><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '<td align=center valign=middle colspan=7 rowspan=3>'  .
        '<tt><font size="7"><b>* WARNING *<br>'  .
        '<br>You are in a restricted area.</b></font></tt></td>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#FFFF00" width="6%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#FFFF00" width="6%"><font size="7">&#160;</font></td>' .
        '<td align=center colspan=7><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '<td align=center colspan=7><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="6%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#000000" width="11%"><font size="7">&#160;</font></td>' .
        '<td bgcolor="#FFFF00" width="11%"><font size="7">&#160;</font></td>' .
        '</tr>' .
        '<tr>' .
        '<td colspan=9 align=right>' .
        '<p>' .
        '<font size="1">' .
        '<a href="http://sourceforge.net/projects/memephage">Memephage</a>' .
        ' is powered by <a href="http://poe.perl.org/">POE</a>.' .
        '</font>' .
        '</td>'  .
        '</tr>'  .
        '</table>' .
        '</body>' .
        '</html>'
      );
    $heap->{wheel}->put($response);
    return;
  }

  ### Link redirection.

  if ($url =~ /^\/link\/(\d+)/) {

    my $big_link = get_link_by_id($1);
    if (defined $big_link) {
      #$big_link = url_encode($big_link);

      my $response = HTTP::Response->new(301);
      $response->push_header( 'Location', $big_link );
      $response->push_header( 'Content-type', 'text/html' );
      $response->content
        ( "<html><head><title>Redirecting to a longer link...</title></head>" .
          "<body><h1>Here you go...</h1>" .
          "<a href='$big_link'>$big_link</a>" .
          "</body></html>"
        );
      $heap->{wheel}->put( $response );
      return;
    }

    my $response = HTTP::Response->new(404);
    $response->push_header( 'Content-type', 'text/html' );
    $heap->{wheel}->put( $response );
    return;
  }

  ### New since TIME.

  if ($url =~ /^\/since(?:\/(\d*))?/) {
    my $oldest_time = $1;

    my $min_time = time() - 3600;
    $oldest_time = $min_time
      unless defined $oldest_time and length $oldest_time;
    $oldest_time = $min_time if $oldest_time < $min_time;

    my @recent = get_links_since($oldest_time);
    my $title = "New links since " . gmtime($oldest_time) . " GMT...";

    my $response = build_log($title, \@recent);

    $heap->{wheel}->put( $response );
    return;
  }

  ### Recent N.

  if ($url =~ /^\/recent(?:\/(\d+))?/) {
    my $max_links = $1;
    $max_links = 10 unless defined $max_links;
    $max_links = 100 if $max_links > 100;

    my @recent = get_recent_links($max_links);
    my $title = "$max_links most recent links...";

    my $response = build_log($title, \@recent);

    $heap->{wheel}->put( $response );
    return;
  }

  ### Stale N.  For debugging.

  if ($url =~ /^\/stale\/?$/) {
    my @stale = get_stale_links( 3600 * 24 * 7 );
    my $title = "Stale links...";
    my $response = build_log($title, \@stale);
    $heap->{wheel}->put($response);
    return;
  }

  ### Default handler dumps everything it can about the request.

  my $response = HTTP::Response->new( 200 );
  $response->push_header( 'Content-type', 'text/html' );

  # Many of the headers dumped here are undef.  We turn off warnings
  # here so the program doesn't constantly squeal.

  local $^W = 0;

  $response->content
    ( "<html><head><title>test</title></head>" .
      "<body>Your request was strange:<table border=1>" .

      {% table_method authorization             %} .
      {% table_method authorization_basic       %} .
      {% table_method content_encoding          %} .
      {% table_method content_language          %} .
      {% table_method content_length            %} .
      {% table_method content_type              %} .
      {% table_method content                   %} .
      {% table_method date                      %} .
      {% table_method expires                   %} .
      {% table_method from                      %} .
      {% table_method if_modified_since         %} .
      {% table_method if_unmodified_since       %} .
      {% table_method last_modified             %} .
      {% table_method method                    %} .
      {% table_method protocol                  %} .
      {% table_method proxy_authorization       %} .
      {% table_method proxy_authorization_basic %} .
      {% table_method referer                   %} .
      {% table_method server                    %} .
      {% table_method title                     %} .
      {% table_method url                       %} .
      {% table_method user_agent                %} .
      {% table_method www_authenticate          %} .

      {% table_header Accept     %} .
      {% table_header Connection %} .
      {% table_header Host       %} .

      {% table_header username  %} .
      {% table_header opaque    %} .
      {% table_header stale     %} .
      {% table_header algorithm %} .
      {% table_header realm     %} .
      {% table_header uri       %} .
      {% table_header qop       %} .
      {% table_header auth      %} .
      {% table_header nonce     %} .
      {% table_header cnonce    %} .
      {% table_header nc        %} .
      {% table_header response  %} .

      "</table>" .

      &dump_content($request->content()) .

      "<p>Request as string=" . $request->as_string() . "</p>" .

      "</body></html>"
    );

  # A little debugging here.
  if (DUMP_REQUEST) {
    my $request_as_string = $request->as_string();
    warn unpack('H*', $request_as_string), "\n";
    warn "Request has CR.\n" if $request_as_string =~ /\x0D/;
    warn "Request has LF.\n" if $request_as_string =~ /\x0A/;
  }

  $heap->{wheel}->put( $response );
  return;
}

# Start the HTTPD server.

foreach my $server (get_names_by_type(WEBLOG_TYPE)) {
  my %conf = get_items_by_name($server);

  POE::Component::Server::TCP->new
    ( Port     => $conf{port},
      ( (defined $conf{iface})
        ? ( Address => $conf{iface} )
        : ()
      ),
      Acceptor =>
      sub {
        POE::Session->new
          ( _start    => \&httpd_session_started,
            got_flush => \&httpd_session_flushed,
            got_query => \&httpd_session_got_query,
            got_error => \&httpd_session_got_error,
            do => sub {goto &{splice(@_, ARG0, 1)} if ref($_[ARG0]) =~ /CODE/},

            # Note the use of ifname here in ARG6.  This gives the
            # responding session knowledge of its host name for
            # building HTML responses.  Most of the time it will be
            # identical to iface, but sometimes there may be a reverse
            # proxy, firewall, or NATD between the address we bind to
            # and the one people connect to.  In that case, ifname is
            # the address the outside world sees, and iface is the one
            # we've bound to.

            [ @_[ARG0..ARG2], $server,
              $conf{iface}, $conf{port}, $conf{ifname},
	      $conf{login}, $conf{passwd},
            ],
          );
      },
    );
}

#------------------------------------------------------------------------------

sub build_log {
  my ($title, $items) = @_;

  my $now   = time();
  my $count = @$items;

  my $response = HTTP::Response->new(200);
  $response->push_header( 'Content-type', 'text/html' );

  my $content =
    ( "<html><head>" .
      "<title>$title</title>" .
      "</head><body>" .
      "<p><a href='/since/$now'>" .
      "Fetch new links since this page was generated." .
      "</a></p>"
    );

  if ($count) {
    foreach (@$items) {
      $content .= get_link_as_table_row($_);
    }
  }
  else {
    $content .= "<h1>Sorry... no links yet.</h1>";
  }

  $content .=
    ( '<p>' .
      '<font size="1">' .
      '<a href="http://sourceforge.net/projects/memephage">Memephage</a>' .
      ' is powered by <a href="http://poe.perl.org/">POE</a>.' .
      '</font>' .
      '</p>' .
      '</body></html>'
    );

  $response->content($content);
  return $response;
}

#------------------------------------------------------------------------------
1;
