# $Id$

# POE bot helper functions.

package PoeUtils;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(_elapsed);

#------------------------------------------------------------------------------
# Helper function to turn a duration into something humans enjoy
# seeing.

# coral: This could be done in an RFC-compliant form with Reefknot's
#        Net::ICal::Duration.

sub _elapsed {
  my ($s, $p) = @_;
  my ($t, @o);

  # Build an array of time parts.
  if ($t = int($s / 604800)) { $s %= 604800; push(@o, $t . 'w'); }
  if ($t = int($s / 86400 )) { $s %= 86400;  push(@o, $t . 'd'); }
  if ($t = int($s / 3600  )) { $s %= 3600;   push(@o, $t . 'h'); }
  if ($t = int($s / 60    )) { $s %= 60;     push(@o, $t . 'm'); }
  if ($s || !scalar(@o)    ) {               push(@o, $s . 's'); }

  # Reduce precision.
  if ($p) {
    pop(@o) while (scalar(@o) > $p);
  }

  # Return the parts as a string.
  join(' ', @o);
}

#------------------------------------------------------------------------------
1;
