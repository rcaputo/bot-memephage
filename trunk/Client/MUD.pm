# $Id$

# Rocco's PerlMud bot stuff.

package PoeMudClient;

use strict;

use POE::NFA;

sub MSG_SPOKEN    () { 0x01 }
sub MSG_PAGED     () { 0x02 }
sub MSG_WHISPERED () { 0x04 }
sub MSG_EMOTED    () { 0x08 }

use PoeConfThing;
use PoeLinkManager;
use PoeWebServer;
use PoeUtils;

# Debug stuff.
# test_parser_and_exit();

# ToDo: Configure.

#------------------------------------------------------------------------------
# Everything is in one big NFA session.  Try to tone it down some.

foreach my $mud (get_names_by_type('mud')) {

  my %conf = get_items_by_name($mud);

  POE::NFA->spawn
    ( inline_states =>

      ### CONNECTING

      { connecting =>
        { connect => sub {
            $_[RUNSTATE]->{connector} =
              POE::Wheel::SocketFactory->new
                ( RemoteAddress => $conf{host},
                  RemotePort    => $conf{port},
                  SuccessEvent  => 'connect_success',
                  FailureEvent  => 'connect_error',
                  Reuse         => 'yes',
                );
          },

          # Something caused the need to reconnect.

          connect_error => sub {
            my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
            print( "error connecting:\n",
                   "\t$operation error $errnum: $errstr\n",
                   "\twaiting before next attempt...\n"
                 );
            delete $_[RUNSTATE]->{connector};
            delete $_[RUNSTATE]->{interactor};
            $_[KERNEL]->delay( connect => 60 );
          },

          # Need to reconnect.

          reconnect => sub {
            delete $_[RUNSTATE]->{connector};
            delete $_[RUNSTATE]->{interactor};
            $_[KERNEL]->delay( connect => 60 );
          },

          # A connection succeeded.  Wrap the socket in a ReadWrite
          # wheel, and move to the next state.

          connect_success => sub {
            my ($kernel, $machine, $heap, $socket) =
              @_[KERNEL, MACHINE, RUNSTATE, ARG0];
            delete $heap->{connector};
            $machine->goto_state( logging_in => login => $socket );
          },
        },

        ### LOGGING IN

        logging_in =>
        { login => sub {
            my ($kernel, $machine, $heap, $socket) =
              @_[KERNEL, MACHINE, RUNSTATE, ARG0];

            $heap->{expect_index} = 0;

            $heap->{interactor} =
              POE::Wheel::ReadWrite->new
                ( Handle       => $socket,
                  Driver       => POE::Driver::SysRW->new(),
                  Filter       => POE::Filter::Line->new(),
                  InputEvent   => 'got_input',
                  ErrorEvent   => 'got_error',
                  FlushedEvent => 'got_flush'
                );
          },

          got_input => sub {
            my ($kernel, $heap, $machine, $input) =
              @_[KERNEL, RUNSTATE, MACHINE, ARG0];

            print "<<< $input\n";

	    if ( index($input, $conf{get}->[$heap->{expect_index}]) >= 0
	       ) {
	      if (defined $conf{put}->[$heap->{expect_index}]) {
		$_[RUNSTATE]->{interactor}->put
		  ( $conf{put}->[$heap->{expect_index}]
		  );
	      }

	      $heap->{expect_index}++;
              $_[MACHINE]->goto_state( existing => 'start' )
		if ( ($heap->{expect_index} > @{$conf{get}}) or
		     !defined($conf{get}->[$heap->{expect_index}])
		   );
            }
          },

          got_error => sub {
            my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
            print( "error logging in:\n",
                   "\t$operation error $errnum: $errstr\n",
                   "\twaiting before next attempt...\n"
                 );
            $_[MACHINE]->goto_state( connecting => 'reconnect' );
          },

          got_flush => sub {
            # do nothing here
          },
        },

        ### EXISTING (connected)

        existing =>
        { start => sub {
            my $kernel = $_[KERNEL];
            $kernel->delay( set_doing => 60 );
          },

          set_doing => sub {
            my ($kernel, $heap) = @_[KERNEL, RUNSTATE];
            $heap->{interactor}->put
              ( "\@doing logging urls at http://combot.dyndns.org:8888/"
              );
            $kernel->delay( set_doing => 60 );
          },

          got_input => sub {
            my ($kernel, $machine, $input) = @_[KERNEL, MACHINE, ARG0];
            my $mud = $_[RUNSTATE]->{interactor};

            print "<<< $input\n";

            my ( $type, $speaker, $audience, $message,
                 $topic, $spoofer, $responder
               ) = parse_perlmud($input, $conf{login});

            # Ignore spoofed stuff.
            return if defined $spoofer;
            return unless defined $speaker;
            return if $speaker eq 'You';

            # Sanity checks.
            if (defined $topic) {
              return unless ( $type & MSG_SPOKEN or
                              $type & MSG_EMOTED
                            );
            }

            # Don't do anything with stuff which isn't recognized.
            return unless $type and $responder;

            ### Requested an url?

#            if ($audience eq $conf{login}) {
#              if ($message =~ /^\s*url\s*(\d+)/) {
#                my $last = (defined($1) ? $1 : 1);
#                $last  = 3 if $last > 3;
#
#                if ($last > 1) {
#                }
#              }
#            }

            ### Parse input for useful things.

            my ($description, @links) = parse_link_from_message($message);
	    $description = "(none)"
	      unless defined $description and length $description;

	    foreach my $link (@links) {
	      next unless defined $link and length $link;
              my $link_id = get_link_id( "nerdsholm", $speaker, $link, $description );

              # Make a shorter link if it's too long.
              if (length($link) > 75) {
                my ($host) = ($link =~ m{//(.*?)/});
                if (defined $host) {
                  my $short = $conf{short};
                  $short =~ s/<<id>>/$link_id/g;
                  $mud->put( "${responder}$short" );
                }
              }
            }
          },

          got_flush => sub {
            # do nothing so far
          },

          got_error => sub {
            my ($operation, $errnum, $errstr) = @_[ARG0, ARG1, ARG2];
            $_[KERNEL]->delay( 'set_doing' );
            print( "error existing:\n",
                   "\t$operation error $errnum: $errstr\n",
                   "\twaiting before next attempt...\n"
                 );
            $_[MACHINE]->goto_state( connecting => 'reconnect' );
          },
        },

      },
    )->goto_state( connecting => 'connect' );
}

#------------------------------------------------------------------------------
# Helper function to parse a perlmud line into usable stuff.

sub parse_perlmud {
  my ($input, $nick) = @_;

  # ... (from Xyz)
  my $spoofer;
  if ($input =~ s/\s+\(from\s+(.*?)\s*\)$//) {
    $spoofer = $1;
  }

  # ... <topic>
  my $topic;
  if ($input =~ s/\s+\<\s*(.*?)\s*\>$//) {
    $topic = $1;
  }

  # Xyz says( to Abc), "stuff"
  my ($type, $speaker, $audience, $spoken);
  if ($input =~ /^(\S+) says(?: to (\S+))?, \"(.*?)\"$/) {
    ($type, $speaker, $audience, $spoken) =
      (MSG_SPOKEN, $1, $2, $3);

    # Common directed message convention of saying "audience: etc".
    unless (defined $audience) {
      if ($spoken =~ s/^(\S+):\s+//) {
        $audience = $1;
      }
    }
  }

  # Xyz pages: test
  elsif ($input =~ /^(\S+) pages:\s+(.*?)\s*$/) {
    ($type, $speaker, $audience, $spoken) =
      (MSG_PAGED, $1, $nick, $2);
  }

  # Xyz whispers, "test" to (list)
  elsif ($input =~ /^(\S+) whispers, \"(.*?)\" to\s+(.*?)\s*\.$/) {
    ($type, $speaker, $audience, $spoken) =
      (MSG_WHISPERED, $1, $3, $2);

    # Furthermore, it's possible to include multiple destinations.
    # Parse the audience as a list, replacing "you" with the speaker's
    # nick, and collapsing duplicates through a hash.

    my @audience = split /(?:\s*(?:,|and)\s*)+/, $audience;
    my %audience = map { $_ = $speaker if $_ eq "you";
                         $_ => 1
                       } @audience;
    @audience = sort keys %audience;

    unless (@audience) {
      undef $audience;
    }
    elsif (@audience > 1) {
      $audience = \@audience;
    }
    else {
      $audience = $audience[0];
    }
  }

  # Actions?
  else {
    if ($input =~ /^(\S+?)\,? +(.*?)\s*$/) {
      ($type, $speaker, $spoken) = (MSG_EMOTED, $1, $2);
    }
  }

  # Finally, respond in kind.
  my $responder;

  # If there's a spoofer, all bets are off.
  unless (defined $spoofer) {
    if (defined $type) {

      # If it was a spoken message...
      if ($type & MSG_SPOKEN) {
        # If it was on a topic...
        if (defined $topic) {
          # If it was directed at me...
          if (defined($audience) and $audience eq $nick) {
            $responder = ",$topic $speaker: ";
          }
          # Generic on-topic.
          else {
            $responder = ",$topic ";
          }
        }
        # Not on topic... direct it at the speaker, always.
        else {
          $responder = "..$speaker ";
        }
      }

      # If it was emoted...
      elsif ($type & MSG_EMOTED) {
        if (defined $topic) {
          $responder = ",$topic ";
        }
        else {
          $responder = "..$speaker ";
        }
      }

      # If it was whispered...
      elsif ($type & MSG_WHISPERED) {
        # If there are multiple recipients...
        if (ref($audience) eq 'ARRAY') {
          $responder = '.' . join(',', @$audience) . " ";
        }
        # If there was only one recipient...
        else {
          $responder = ".$audience ";
        }
      }

      # If it was paged...
      elsif ($type & MSG_PAGED) {
        $responder = "p $speaker=";
      }
    }
  }

  ($type, $speaker, $audience, $spoken, $topic, $spoofer, $responder);
}

#------------------------------------------------------------------------------
# Regression tests on the MUD parser.

sub test_parser_and_exit {

  foreach my $input
    ( [ 'from brings up the topic <topic>',
        MSG_EMOTED, 'from', 'undef', 'topic', 'brings up the topic', 'undef'
      ],

      # Normal.

      [ 'from does something.',
        MSG_EMOTED, 'from', 'undef', 'undef', 'does something.', 'undef'
      ],
      [ 'from says, "message"',
        MSG_SPOKEN, 'from', 'undef', 'undef', 'message', 'undef'
      ],
      [ 'from says to audience, "message"',
        MSG_SPOKEN, 'from', 'audience', 'undef', 'message', 'undef'
      ],
      [ 'from says, "audience: message"',
        MSG_SPOKEN, 'from', 'audience', 'undef', 'message', 'undef'
      ],
      [ 'from says to audience, "boogly: message"',
        MSG_SPOKEN, 'from', 'audience', 'undef', 'boogly: message', 'undef'
      ],
      [ 'from pages: message',
        MSG_PAGED, 'from', 'com', 'undef', 'message', 'undef'
      ],
      [ 'from whispers, "message" to you.',
        MSG_WHISPERED, 'from', 'com', 'undef', 'message', 'undef'
      ],
      [ 'from whispers, "message" to her, you and him.',
        MSG_WHISPERED, 'from', 'com her him', 'undef', 'message', 'undef'
      ],

      # Spoofed.

      [ 'from does something. (from spoofer)',
        MSG_EMOTED, 'from', 'undef', 'undef', 'does something.', 'spoofer'
      ],
      [ 'from says, "message" (from spoofer)',
        MSG_SPOKEN, 'from', 'undef', 'undef', 'message', 'spoofer'
      ],
      [ 'from says to audience, "message" (from spoofer)',
        MSG_SPOKEN, 'from', 'audience', 'undef', 'message', 'spoofer'
      ],
      [ 'from says, "audience: message" (from spoofer)',
        MSG_SPOKEN, 'from', 'audience', 'undef', 'message', 'spoofer'
      ],
      [ 'from says to audience, "boogly: message" (from spoofer)',
        MSG_SPOKEN, 'from', 'audience', 'undef', 'boogly: message', 'spoofer'
      ],
      [ 'from pages: message (from spoofer)',
        MSG_PAGED, 'from', 'com', 'undef', 'message', 'spoofer'
      ],
      [ 'from whispers, "message" to you. (from spoofer)',
        MSG_WHISPERED, 'from', 'com', 'undef', 'message', 'spoofer'
      ],
      [ 'from whispers, "message" to her, you and him. (from spoofer)',
        MSG_WHISPERED, 'from', 'com her him', 'undef', 'message', 'spoofer'
      ],

      # Topicked.

      [ 'from does something. <topic>',
        MSG_EMOTED, 'from', 'undef', 'topic', 'does something.', 'undef'
      ],
      [ 'from says, "message" <topic>',
        MSG_SPOKEN, 'from', 'undef', 'topic', 'message', 'undef'
      ],
      [ 'from says to audience, "message" <topic>',
        MSG_SPOKEN, 'from', 'audience', 'topic', 'message', 'undef'
      ],
      [ 'from says, "audience: message" <topic>',
        MSG_SPOKEN, 'from', 'audience', 'topic', 'message', 'undef'
      ],
      [ 'from says to audience, "boogly: message" <topic>',
        MSG_SPOKEN, 'from', 'audience', 'topic', 'boogly: message', 'undef'
      ],
      [ 'from pages: message <topic>',
        MSG_PAGED, 'from', 'com', 'topic', 'message', 'undef'
      ],
      [ 'from whispers, "message" to you. <topic>',
        MSG_WHISPERED, 'from', 'com', 'topic', 'message', 'undef'
      ],
      [ 'from whispers, "message" to her, you and him. <topic>',
        MSG_WHISPERED, 'from', 'com her him', 'topic', 'message', 'undef'
      ],

      # Spoofed topicked stuff.

      [ 'from does something. <topic> (from spoofer)',
        MSG_EMOTED, 'from', 'undef', 'topic', 'does something.', 'spoofer'
      ],
      [ 'from says, "message" <topic> (from spoofer)',
        MSG_SPOKEN, 'from', 'undef', 'topic', 'message', 'spoofer'
      ],
      [ 'from says to audience, "message" <topic> (from spoofer)',
        MSG_SPOKEN, 'from', 'audience', 'topic', 'message', 'spoofer'
      ],
      [ 'from says, "audience: message" <topic> (from spoofer)',
        MSG_SPOKEN, 'from', 'audience', 'topic', 'message', 'spoofer'
      ],
      [ 'from says to audience, "boogly: message" <topic> (from spoofer)',
        MSG_SPOKEN, 'from', 'audience', 'topic', 'boogly: message', 'spoofer'
      ],
      [ 'from pages: message <topic> (from spoofer)',
        MSG_PAGED, 'from', 'com', 'topic', 'message', 'spoofer'
      ],
      [ 'from whispers, "message" to you. <topic> (from spoofer)',
        MSG_WHISPERED, 'from', 'com', 'topic', 'message', 'spoofer'
      ],
      [ 'from whispers, "message" to her, you and him. <topic> (from spoofer)',
        MSG_WHISPERED, 'from', 'com her him', 'topic', 'message', 'spoofer'
      ],
    ) {

      my ($test_input,
          $test_type, $test_speaker, $test_audience, $test_topic,
          $test_spoken, $test_spoofer
         ) = @$input;

      my ($type, $speaker, $audience, $spoken, $topic, $spoofer) =
        &parse_perlmud($test_input);

      $type     = 'undef' unless defined $type;
      $speaker  = 'undef' unless defined $speaker;
      $audience = 'undef' unless defined $audience;
      $topic    = 'undef' unless defined $topic;
      $spoken   = 'undef' unless defined $spoken;
      $spoofer  = 'undef' unless defined $spoofer;

      $audience = "@$audience" if ref($audience) eq 'ARRAY';

      my @bad;
      push @bad, "\tbad type: got $type instead of $test_type\n"
        unless $type eq $test_type;

      push @bad, "\tbad speaker: got $speaker instead of $test_speaker\n"
        unless $speaker eq $test_speaker;

      push @bad, "\tbad audience: got $audience instead of $test_audience\n"
        unless $audience eq $test_audience;

      push @bad, "\tbad topic: got $topic instead of $test_topic\n"
        unless $topic eq $test_topic;

      push @bad, "\tbad spoken: got $spoken instead of $test_spoken\n"
        unless $spoken eq $test_spoken;

      push @bad, "\tbad spoofer: got $spoofer instead of $test_spoofer\n"
        unless $spoofer eq $test_spoofer;

      print "<<< $test_input\n", @bad
        if @bad;
    }

  exit 0;
}

#------------------------------------------------------------------------------
1;

__END__

AnotherBug whispers, "com needs to learn how to hug!" to you.
