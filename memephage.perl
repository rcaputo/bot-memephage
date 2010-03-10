#!/usr/bin/perl -w

use strict;

# For dmitri.
use lib '/home/rcc/lib';

# For home.
use lib '/home/troc/perl/poe';
use lib '/home/troc/perl/poco/client-http/blib/lib';
use lib '/home/troc/perl/poco/client-dns/blib/lib';
use lib '/home/troc/perl/poco/jobqueue/blib/lib';

use POE::Kernel;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Driver::SysRW;
use POE::Filter::Line;
use POE::Preprocessor;

use Util::Conf;

# Uncomment to use the MUD client.
#use Client::MUD;

# Uncomment to use the IRC client.
use Client::IRC;

# These should probably be left enabled.
use Server::Web;
use Client::Web;

$poe_kernel->run();
exit 0;
