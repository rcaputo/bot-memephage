# $Id$

# Manage the link database.

package Util::Database;

use strict;
use Exporter;

use POE;
use Util::Conf;

use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);

my %conf  = get_items_by_name('db');
my $database_class = "Database::\u\L$conf{type}";
eval "use $database_class";
die "Can't load specified database '$database_class': $@" if ($@);
{ 
    no strict "refs";
    push @EXPORT, @{"${database_class}::EXPORT"};
}

#------------------------------------------------------------------------------
1;
