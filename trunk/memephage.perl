#!/usr/bin/perl -w

use strict;
use lib '/home/rcc/lib';

use POE::Kernel;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Driver::SysRW;
use POE::Filter::Line;
use POE::Preprocessor;

use PoeConfThing;

#use PoeMudClient;
use PoeIrcClient;

use PoeWebServer;
use PoeWebClient;

$poe_kernel->run();
exit 0;

__END__

###############################################################################

sub respond_mud {
  $sock = $_[0];

  if (&Sock::alive($sock)) {
    while (defined($in = &Sock::getline($sock))) {

      # handle automatic responses

        if (defined($return)) {
          if ($cmd eq "ping") {
            chop($param2 = `d:/usr/bin/date.exe`);
            if (defined($param) && ($param ne "")) {
              $param = $param . " ($param2)";
            }
            else {
              $param = $param2;
            }

            if (($ss = 871592100 - time) >= 0) {
              if (($dd = int($ss / 86400)) > 0) {
                $ss -= ($dd * 86400); $dd .= " day";
                if (($dd+0) != 1) { $dd .= "s"; }
                $dd .= ", ";
              }
              else { $dd = ""; }
              $hh = int($ss / 3600);  $ss -= ($hh * 3600);  $hh = "0".$hh if ($hh<10);
              $mm = int($ss / 60);    $ss -= ($mm * 60);    $mm = "0".$mm if ($mm<10);
              $ss = "0".$ss if ($ss<10);
              $miyume = " ($dd$hh:$mm:$ss)";
            }
            else {
              $miyume = "";
            }

            print $sock $return,"PONG $param$miyume$nl";
          }

          elsif ($cmd eq 'bks') {
            $bookmarks = &bookmark_search($param);
            if ($return =~ /^\"/) {
              print $sock ":whispers something to $whom.$nl";
              $return = "w $whom=";
            }
            print $sock $return, $bookmarks, $nl;
          }

          elsif ($cmd eq 'bka') {
            ($url, $title) = ($param =~ /^\s*(\S+)\s*(.*?)\s*$/);
            print $sock $return, &bookmark_add($whom, $url, $title), $nl;
          }

          elsif ($cmd eq 'bkd') {
            print $sock $return, &bookmark_delete($whom, $param), $nl;
          }

          elsif ($cmd eq 'define') {
            $param =~ s/\s.*//;
            $result = &webster_define($param);
            if ((substr($return, 0, 1) eq '"') && (length($result) > 240)) {
              print $sock $return, "It's too long to say.", $nl;
              $return = "w $whom=";
            }
            print $sock $return, $result, $nl;
          }

          elsif ($cmd eq 'busta') {
            $param =~ s/\s+//g;
            $param =~ s/\W+$//;
            $result = &rhyme($param);
            if ((substr($return, 0, 1) eq '"') && (length($result) > 240)) {
              print $sock $return, "It's too long to say.", $nl;
              $return = "w $whom=";
            }
            print $sock $return, $result, $nl;
          }

          elsif ($cmd eq 'translate') {
            $fromto = '';
            if ($param =~ s/^(in)?to (\w+)\S*\s*//) {
              $fromto = 'to' . lc($2);
              $param =~ s/^\s*[\'\"\`]?\s*(.*?)\s*[\'\"\`]?\s*$/$1/;
            }
            elsif ($param =~ s/^from (\w+)\S*\s*//) {
              $fromto = 'from' . lc($1);
              $param =~ s/^\s*[\'\"\`]?\s*(.*?)\s*[\'\"\`]?\s*$/$1/;
            }
            elsif ($param =~ s/^through (\w+)\S*\s*//) {
              $fromto = 'thru' . lc($1);
              $param =~ s/^\s*[\'\"\`]?\s*(.*?)\s*[\'\"\`]?\s*$/$1/;
            }
            if (exists $from_to{$fromto}) {
              $result = &babeltrans($from_to{$fromto}, $param);
              if (defined $result) {
                if ((substr($return, 0, 1) eq '"') && (length($result) > 240)) {
                  print $sock $return, "It's too long to say.", $nl;
                  $return = "w $whom=";
                }
                print $sock $return, '`', $result, '`', $nl;
              }
              else {
                print $sock $return, "The babelfish is conspicuously silent ($fromto,$from_to{$fromto},$param).", $nl;
              }
            }
            elsif (exists $through{$fromto}) {
              $result = &babelthrough($fromto, $param);
              if (defined $result) {
                if ((substr($return, 0, 1) eq '"') && (length($result) > 240)) {
                  print $sock $return, "It's too long to say.", $nl;
                  $return = "w $whom=";
                }
                print $sock $return, '`', $result, '`', $nl;
              }
              else {
                print $sock $return, "The babelfish is conspicuously silent ($fromto,$through{$fromto},$param).", $nl;
              }
            }
            else {
              if ($fromto eq 'toenglish') {
                print $sock $return, "Maybe you wanted to translate from something instead?", $nl;
              }
              else {
                print $sock $return, "I only know ", $valid_babels, ".", $nl;
              }
            }
          }

          elsif ($cmd eq 'ispell') {
            if ($return =~ /^\"/) {
              print $sock ":whispers something to $whom.$nl";
              $return = "w $whom=";
            }
            if ($param) {
              print ISPWR $param, "\n";
              $word_index = $misspell_count = 0;
              while (<ISPRD>) {
                1 while (chomp());
                last if (/^\s*$/);
                $word_index++;
                $param =~ s/^\s*(\S+)\s*//;
                $misspelled_word = $1;
                if (/^\#/) {
                  $misspell_count++;
                  print $sock $return, '`', $misspelled_word,
                    '` is not recognized by ispell.', $nl;
                }
                elsif (/^\&.*?(\d+).*?\:\s*(.*)$/) {
                  $misspell_count++;
                  print $sock $return, '`', $misspelled_word, '` has ', $1,
                    ' alternate', ($1 == 1) ? '' : 's', ': ', $2, $nl;
                }
                elsif (/^\-/) {
                  $misspell_count++;
                  print $sock $return, '`', $misspelled_word,
                    '` may be a legal compound word.', $nl;
                }
              }
              if ($misspell_count == 0) {
                print $sock $return, "It's okay by ispell.", $nl;
              }
            }
            else {
              print $sock $return, $ispell_version, $nl;
            }
          }

#          elsif ($cmd eq 'pq') {
#            if (defined($param) && ($param ne "")) {
#              @hits = &faq_query($param,3);
#              if (scalar(@hits)) {
#                print $sock $return,"Best matches: ",join('; ',@hits),"$nl";
#              }
#              else {
#                print $sock $return,"Nothing found for \"$param\"$nl";
#              }
#            }
#          }

          elsif (defined($mud_resp{$cmd})) {
            &{$mud_resp{$cmd}}($sock,$return,$param);
          }
        }
      }

#      &{$mud_resp{'_default_'}}($sock,$in);

      if ($in =~ /^You/) {
        &talk("$bm_you$in");
      }

      elsif ($in =~ /^\S+\s+says\,/) {
        &talk("$bm_talk$in");
      }

      elsif ($in =~ /^\S+\s+(whispers\,?|pages\:)/) {
        &talk("$bm_whisper$in");
      }

      elsif ($in =~ / has (arrived|connected)\.$/) {
        &talk("$bm_enter$in");
      }

      elsif ($in =~ / (arrives at home|materializes)\.$/) {
        &talk("$bm_enter$in");
      }

      elsif ($in =~ / has (left|disconnected)\.$/) {
        &talk("$bm_leave$in");
      }

      elsif ($in =~ / (goes home|disappears)\.$/) {
        &talk("$bm_leave$in");
      }

#      elsif ($in =~ /^(\S+) (whispers|says),? \"define\s+(\S+)\"$/) {
#        &talk(" +++ $1 wants a definition for $3");
#      }
#
#      elsif ($in =~ /^(\S+) (whispers|says),? \"spell\s+(\S+)\"$/) {
#        &talk(" +++ $1 wants a spelling for $3");
#      }

      else {
        &talk("$bm_misc$in");
      }
    }
  }
                                        # ooops!
  else {
    &talk("$bm_leave \x0FzzreHI\x0FMUD connection has closed.");
    undef $mudsock;
  }
}
