#!perl

# $Id$
use strict;
use LWP::UserAgent ();

# the submission url to use
my $url = 'http://64.53.6.49:8888/post';

# we need <> to return a scalar here
local $/;

# and here we post the entirety of STDIN to memephage
my $response = LWP::UserAgent->new->post($url, message => <>);

# explode if the post failed for some reason
die "FAILURE!" unless $response->is_success;

# ah, the sweet taste of success. give the shell a true return code.
exit 0;
