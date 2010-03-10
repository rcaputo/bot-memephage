# Rocco's IRC bot stuff.

package Client::IRC;

use strict;

use POE::Session;
use POE::Component::IRC;

sub MSG_SPOKEN    () { 0x01 }
sub MSG_WHISPERED () { 0x02 }
sub MSG_EMOTED    () { 0x04 }

use Util::Conf;
use Util::Link;
use Server::Web;

#------------------------------------------------------------------------------
# Spawn the IRC session.

foreach my $server (get_names_by_type('irc')) {
  my %conf = get_items_by_name($server);

  POE::Component::IRC->new($server);

  POE::Session->create
    ( inline_states =>
      { _start => sub {
          my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

          $kernel->alias_set( "client_$server" );
          $kernel->post( $server => register => 'all' );

          $heap->{server_index} = 0;

          # Keep-alive timer.
          $kernel->delay( autoping => 60 );

          $kernel->yield( 'connect' );
      },

      # ctcp ping ourselves every minute to generate network traffic so
      # we can detect a broken connection faster
      autoping => sub {
          my $kernel = $_[KERNEL];
          $kernel->post( $server => ctcp => $conf{nick} => "PING 123456789" );
          $kernel->delay( autoping => 60 );
      },

      connect => sub {
          my ($kernel, $heap) = @_[KERNEL, HEAP];

          $kernel->post( $server => connect =>
                         { Debug    => 0,
                           Nick     => $conf{nick},
                           Server   => $conf{server}->[$heap->{server_index}],
                           Port     => 6667,
                           Username => $conf{uname},
                           Ircname  => $conf{iname},
                         }
                       );

          $heap->{server_index}++;
          $heap->{server_index} = 0
            if $heap->{server_index} >= @{$conf{server}};
      },

      join => sub {
        my ($kernel, $channel) = @_[KERNEL, ARG0];
        $kernel->post( $server => join => $channel );
      },

      _stop => sub {
        my $kernel = $_[KERNEL];
        $kernel->post( $server => quit => $conf{quit} );
      },

      # events to be totally ignored
      map({$_ => sub {} } qw(irc_002 irc_003 irc_004 irc_005 irc_250 irc_251
			     irc_254 irc_255 irc_265 irc_266 irc_301 irc_306
			     irc_353 irc_366 irc_372 irc_375 irc_376
			     irc_ctcp_ping irc_mode irc_join irc_quit)),

      _default => sub {
        my ($state, $event, $args) = @_[STATE, ARG0, ARG1];
        $args ||= [ ];
        log_event("default $state = $event @$args)");
        return 0;
      },

      irc_001 => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];

        if (defined $conf{flags}) {
          $kernel->post( $server => mode => $conf{nick} => $conf{flags} );
        }
        $kernel->post( $server => away => $conf{away} );

        foreach my $channel (@{$conf{channel}}) {
          $kernel->yield( join => "\#$channel" );
        }

        $heap->{server_index} = 0;
      },

      irc_ctcp_version => sub {
        my ($kernel, $sender) = @_[KERNEL, ARG0];
        my $who = (split /!/, $sender)[0];
        log_event("ctcp version from $who");
        $kernel->post( $server => ctcpreply => $who, "VERSION $conf{cver}" );
      },

      irc_ctcp_clientinfo => sub {
        my ($kernel, $sender) = @_[KERNEL, ARG0];
        my $who = (split /!/, $sender)[0];
        log_event("ctcp clientinfo from $who");
        $kernel->post( $server => ctcpreply =>
                       $who, "CLIENTINFO $conf{ccinfo}"
                     );
      },

      irc_ctcp_userinfo => sub {
        my ($kernel, $sender) = @_[KERNEL, ARG0];
        my $who = (split /!/, $sender)[0];
        log_event("ctcp userinfo from $who");
        $kernel->post( $server => ctcpreply =>
                       $who, "USERINFO $conf{cuinfo}"
                     );
      },

      irc_invite => sub {
        my ($kernel, $who, $where) = @_[KERNEL, ARG0, ARG1];
        $kernel->yield( join => $where );
      },

      irc_kick => sub {
        my ($kernel, $who, $where, $isitme, $reason) = @_[KERNEL, ARG0..ARG4];
        log_event("$who was kicked from $where: $reason");
        # $kernel->delay( join => 15 => $where );
      },

      irc_disconnected => sub {
        my ($kernel, $server) = @_[KERNEL, ARG0];
        log_event("Lost connection to server $server.");
        $kernel->delay( connect => 60 );
      },

      irc_error => sub {
        my ($kernel, $error) = @_[KERNEL, ARG0];
        log_event("Server error occurred: $error");
        $kernel->delay( connect => 60 );
      },

      irc_socketerr => sub {
        my ($kernel, $error) = @_[KERNEL, ARG0];
        log_event("IRC client ($server): socket error occurred: $error");
        $kernel->delay( connect => 60 );
      },

      irc_public => sub {
        my ($kernel, $heap, $who, $where, $msg) = @_[KERNEL, HEAP, ARG0..ARG2];
        $who = (split /!/, $who)[0];
        $where = $where->[0];
        log_event("<$who:$where> $msg");

        soak_up_links
          ( $conf{logto},
            "$who (irc://$conf{server}->[$heap->{server_index}]/$where)",
            $msg
          );
      },

      irc_private => sub {
        my ($kernel, $heap, $who, $msg) = @_[KERNEL, HEAP, ARG0, ARG2];
        $who = (split /!/, $who)[0];
        log_event("<$who:msg> $msg");

        soak_up_links
          ( $conf{logto},
            "$who (irc://$conf{server}->[$heap->{server_index}]/privmsg)",
            $msg
          );
      },
    },
  );
}

sub soak_up_links {
  my ($logto, $who, $msg) = @_;

  # Indigoid supplied these regexps to extract colors.
  $msg =~ s/[\x02\x0F\x11\x12\x16\x1d\x1f]//g;    # Regular attributes.
  $msg =~ s/\x03[0-9,]*//g;                       # mIRC colors.
  $msg =~ s/\x04[0-9a-f]+//ig;                    # Other colors.

  my ($description, @links) = parse_link_from_message($msg);
  $description = "(none)"
    unless defined $description and length $description;

  foreach my $link (@links) {
    next unless defined $link and length $link;
    get_link_id($logto, $who, $link, $description );
  }
}

sub log_event {
    my $text = shift;
    # print for now, maybe syslog later
    print $text, "\n";
}

#------------------------------------------------------------------------------
1;
