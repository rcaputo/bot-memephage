# $Id$

# Manage the link database.

package PoeLinkDatabase;

use strict;
use Exporter;

use POE;
use Util::Conf;

use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw( FLUSH_FIRST_MINUTES FLUSH_REST_MINUTES
              LINK DESC USER TIME PAGE_TITLE PAGE_DESC
              PAGE_KEYS PAGE_TIME PAGE_SIZE PAGE_TYPE
              CHECK_TIME CHECK_STATUS MENTION_COUNT
              REDIRECT FORA
            );

#------------------------------------------------------------------------------
# exported constants

sub FLUSH_FIRST_MINUTES () { 30 }  # First flush after N minutes.
sub FLUSH_REST_MINUTES  () { 60 }  # Subsequent flushes after N minutes.

sub LINK          () {  0 }
sub DESC          () {  1 }
sub USER          () {  2 }
sub TIME          () {  3 }
sub PAGE_TITLE    () {  4 }
sub PAGE_DESC     () {  5 }
sub PAGE_KEYS     () {  6 }
sub PAGE_TIME     () {  7 }
sub PAGE_SIZE     () {  8 }
sub PAGE_TYPE     () {  9 }
sub CHECK_TIME    () { 10 }
sub CHECK_STATUS  () { 11 }
sub MENTION_COUNT () { 12 }
sub REDIRECT      () { 13 }
sub FORA          () { 14 }

#------------------------------------------------------------------------------
1;
