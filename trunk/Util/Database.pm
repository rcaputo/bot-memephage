# $Id$

# Manage the link database.

package Util::Database;

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
              get_link_id get_link_by_id get_link_obj_by_id
	      get_recent_links get_stale_links get_unchecked_links
	      get_links_since
              link_set_status link_set_title link_set_meta_desc
              link_set_meta_keys link_set_head_time link_set_head_size
              link_set_head_type link_set_redirect
              link_get_head_size
            );

# XXX: Use the config file here someday.
use Database::File;
push @EXPORT, @Database::File::EXPORT;

#------------------------------------------------------------------------------
1;
