#!perl

use strict;

http://64.53.6.49:8888/email

LWP::UserAgent->new->post($url, message => $msg)

<TorgoX> coral -- so you want to do like:  die "WHAAT? ", $response->status_line unless $response->is_success;   print "Whee, I got ", $response->content, "\n";
