# $Id$

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

      _default => sub {
        my ($state, $event, $args) = @_[STATE, ARG0, ARG1];
        $args ||= [ ];
        print "default $state = $event @$args\n";
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
        print "ctcp version from $who\n";
        $kernel->post( $server => ctcpreply => $who, "VERSION $conf{cver}" );
      },

      irc_ctcp_clientinfo => sub {
        my ($kernel, $sender) = @_[KERNEL, ARG0];
        my $who = (split /!/, $sender)[0];
        print "ctcp clientinfo from $who\n";
        $kernel->post( $server => ctcpreply =>
                       $who, "CLIENTINFO $conf{ccinfo}"
                     );
      },

      irc_ctcp_userinfo => sub {
        my ($kernel, $sender) = @_[KERNEL, ARG0];
        my $who = (split /!/, $sender)[0];
        print "ctcp userinfo from $who\n";
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
        print "$who was kicked from $where: $reason\n";
        # $kernel->delay( join => 15 => $where );
      },

      irc_disconnected => sub {
        my ($kernel, $server) = @_[KERNEL, ARG0];
        print "Lost connection to server $server.\n";
        $kernel->delay( connect => 60 );
      },

      irc_error => sub {
        my ($kernel, $error) = @_[KERNEL, ARG0];
        print "Server error occurred: $error\n";
        $kernel->delay( connect => 60 );
      },

      irc_socketerr => sub {
        my ($kernel, $error) = @_[KERNEL, ARG0];
        print "IRC client ($server): socket error occurred: $error\n";
        $kernel->delay( connect => 60 );
      },

      irc_public => sub {
        my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0..ARG2];
        $who = (split /!/, $who)[0];
        $where = $where->[0];
        print "<$who:$where> $msg\n";

        soak_up_links($conf{logto}, $who, $msg);
      },

      irc_msg => sub {
        my ($kernel, $who, $msg) = @_[KERNEL, ARG0, ARG2];

        $who = (split /!/, $who)[0];
        print "<$who:msg> $msg\n";

        soak_up_links($conf{logto}, $who, $msg);
      },
    },
  );
}

sub soak_up_links {
  my ($logto, $who, $msg) = @_;

  my ($description, @links) = parse_link_from_message($msg);
  $description = "(none)"
    unless defined $description and length $description;

  foreach my $link (@links) {
    next unless defined $link and length $link;
    get_link_id($logto, $who, $link, $description );
  }
}

#------------------------------------------------------------------------------
1;
