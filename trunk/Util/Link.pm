# $Id$

# Manage links.

package PoeLinkManager;

use strict;
use Exporter;

use POE;
use PoeWebStuff;
use PoeConfThing;

use vars qw(@ISA @EXPORT);
@ISA    = qw(Exporter);
@EXPORT = qw( get_link_id get_link
	      get_recent_links get_stale_links get_unchecked_links
	      get_links_since
              get_link_table_header get_link_as_table_row
              parse_link_from_message
              link_set_status link_set_title link_set_meta_desc
              link_set_meta_keys link_set_head_time link_set_head_size
              link_set_head_type link_set_redirect
            );

#------------------------------------------------------------------------------
# Helper function to record links.

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

my (%id_by_link, %link_by_id, $link_seq, @recent, $log_file);

BEGIN {
  $log_file = './links.list';

  unless (-e $log_file) {
    open LOG_FILE, ">$log_file" or die "can't create $log_file: $!";
    close LOG_FILE;
  }

  open LOG_FILE, "<$log_file" or die "can't read $log_file: $!";
  while (<LOG_FILE>) {
    chomp;
    my @link = split /\t/;
    my $id   = shift @link;

    # Fix up late things.
    $link[USER] =~ s/\,$//;
    $link[MENTION_COUNT] = 1
      unless $link[MENTION_COUNT];
    $link[FORA] = 'global'
      unless defined($link[FORA]) and length($link[FORA]);

    # Store the link by its unique ID.
    $link_by_id{$id} = \@link;

    # Record ID by link, but partition links by fora.  This is where
    # forum partitioning comes in.
    $id_by_link{$link[LINK]} = $id;

    # So new links are added with new IDs.
    $link_seq = $id;
  }
  close LOG_FILE;
}

sub flush_links {
  my $backup = $log_file . ".backup";

  unlink $backup;
  rename $log_file, $backup;

  if (open LOG_FILE, ">$log_file") {
    local $^W = 0;

    foreach my $id (sort { $a <=> $b } keys %link_by_id) {
      my $link = $link_by_id{$id};
      print LOG_FILE join("\t", $id, @$link), "\n";
    }
    close LOG_FILE;
  }
  else {
    rename $backup, $log_file;
  }
}

END {
  flush_links();
}

#------------------------------------------------------------------------------
# Get an ID for a link.  It may store the link if it's new.

sub get_link_id {
  my ($fora, $user, $link, $description) = @_;

  if (exists $id_by_link{$link}) {
    my $link_seq = $id_by_link{$link};
    $link_by_id{$link_seq}->[MENTION_COUNT]++;
    return $id_by_link{$link};
  }

  $id_by_link{$link} = ++$link_seq;

  $link_by_id{$link_seq} =
    [ $link,         # LINK
      $description,  # DESC
      $user,         # USER
      time(),        # TIME
      undef,         # PAGE_TITLE
      undef,         # PAGE_DESC
      undef,         # PAGE_KEYS
      undef,         # PAGE_TIME
      undef,         # PAGE_SIZE
      undef,         # PAGE_TYPE
      undef,         # CHECK_TIME
      undef,         # CHECK_STATUS
      1,             # MENTION_COUNT
      undef,         # REDIRECT
    ];

  # Blow away caches.
  undef @recent;

  # Request a lookup.
  $poe_kernel->post( linkchecker => enqueue => 'ignore this' => $link );

  return $link_seq;
}

#------------------------------------------------------------------------------
# Get a link by its ID.  Creates a link record 

sub get_link {
  my $id = shift;
  return $link_by_id{$id}->[LINK] if exists $link_by_id{$id};
  return undef;
}

#------------------------------------------------------------------------------
# Fetch stale links.

sub get_stale_links {
  my $age = shift;
  my @stale =
    ( sort { $link_by_id{$b}->[TIME] <=> $link_by_id{$a}->[TIME] }
      grep { ( defined($link_by_id{$_}->[CHECK_TIME]) and
	       (time() - $link_by_id{$_}->[CHECK_TIME] >= $age)
	     )
	   } keys %link_by_id
    );
  return @stale;
}

sub get_unchecked_links {
  my @unchecked =
    ( sort { $link_by_id{$b}->[TIME] <=> $link_by_id{$a}->[TIME] }
      grep { my $link = $link_by_id{$_};
	     ( !defined($link->[CHECK_TIME]) or
	       !length($link->[CHECK_TIME]) or
	       !defined($link->[CHECK_STATUS]) or
	       ($link->[CHECK_STATUS] !~ /GET 2/)
	     )
	   } keys %link_by_id
    );
  return @unchecked;
}

#------------------------------------------------------------------------------
# Get up to N of the most recent links.

sub get_recent_links {
  my $limit = shift;

  # Global cached value.
  @recent = ( sort { $link_by_id{$b}->[TIME] <=> $link_by_id{$a}->[TIME] }
              keys %link_by_id
            )
    unless @recent;

  return @recent if @recent < $limit;
  return @recent[0..$limit-1];
}

#------------------------------------------------------------------------------
# Get links changed since a time.

sub get_links_since {
  my $time = shift;

  # Global cached value.
  @recent = ( sort { $link_by_id{$b}->[TIME] <=> $link_by_id{$a}->[TIME] }
              keys %link_by_id
            )
    unless @recent;

  my @since = grep { $link_by_id{$_}->[TIME] >= $time } @recent;
  return @since;
}

#------------------------------------------------------------------------------
# Parse link and description from message.  This is independent of the
# type of chat system.

sub parse_link_from_message {
  my $message = shift;

  # URLs and descriptions.
  my @link;
  my $description = $message;

  while ( $description =~
	  s/\s*(http:\/\/[^\s\'\"\>]+)[^\s\'\"\>]*/ [link] /
	) {
    push @link, $1;
  }

  $description =~ s/^\s*\[link\]\s*[\.\|\#\:\-]+\s*//;
  $description =~ s/\s*[\.\|\#\:\-]+\s*\[link\]\s*$//;

  return ($description, @link);
}

#------------------------------------------------------------------------------
# Return a formatted HTML table row for a given link.

sub get_link_as_table_row {
  my $link_id = shift;

  return '' unless exists $link_by_id{$link_id};

  my $link = $link_by_id{$link_id};

  my $html =
    ( "<p>" .
      "<table border=0 width='100%' cellspacing=0 cellpadding=3 bgcolor='#e0e0f0'>" .

      "<tr>" .
      "<th align=left valign=top width='1%'>Link:</th>" .
      "<td width='99%'><a href='$link->[LINK]'>$link->[LINK]</a><td>" .
      "</tr>"
    );

  if (defined $link->[REDIRECT] and length $link->[REDIRECT]) {
    $html .=
      ( "<tr>" .
        "<th align=left valign=top width='1%'>Really:</th>" .
        ( "<td width='99%'>" .
          "<a href='$link->[REDIRECT]'>$link->[REDIRECT]</a>" .
          "<td>"
        ) .
        "</tr>"
      );
  }

  $html .=
    ( "<tr>" .
      "<th align=left valign=top width='1%'>From:</th>" .
      ( "<td width='99%'>$link->[USER] -- " .
        scalar(gmtime($link->[TIME])) .
        " GMT -- mentioned $link->[MENTION_COUNT] time" .
        ( ($link->[MENTION_COUNT] == 1) ? '' : 's' ) .
        "</td>"
      ) .
      "</tr>"
    );

  if (defined($link->[DESC]) and $link->[DESC] ne '(none)') {
    $html .=
      ( "<tr>" .
        "<th align=left valign=top width='1%'>Context:</th>" .
        "<td width='99%'>$link->[DESC]</td>" .
        "</tr>"
      );
  }

  if (defined $link->[PAGE_TITLE] and length $link->[PAGE_TITLE]) {
    $html .= ( "<tr>" .
               "<th align=left valign=top width='1%'>Title:</th>" .
               "<td width='99%'>$link->[PAGE_TITLE]</td>" .
               "</tr>"
             );
  }

  if (defined $link->[PAGE_DESC] and length $link->[PAGE_DESC]) {
    $html .= ( "<tr>" .
               "<th align=left valign=top width='1%'>Description:</th>" .
               "<td width='99%'>$link->[PAGE_DESC]</td>" .
               "</tr>"
             );
  }

  if (defined $link->[PAGE_KEYS] and length $link->[PAGE_KEYS]) {
    $html .= ( "<tr>" .
               "<th align=left valign=top width='1%'>Keywords:</th>" .
               "<td width='99%'>$link->[PAGE_KEYS]</td>" .
               "</tr>"
             );
  }


  if (defined $link->[CHECK_TIME] and length $link->[CHECK_TIME]) {
    $html .= ( "<tr>" .
               "<th align=left valign=top width='1%'>Status:</th>" .
               ( "<td width='99%'>" .
                 scalar(gmtime($link->[CHECK_TIME])) .
                 " GMT -- " .
                 "$link->[CHECK_STATUS]</td>"
               ) .
               "</tr>"
             );
  }

  if (defined $link->[PAGE_TIME] and length $link->[PAGE_TIME]) {
    $html .= ( "<tr>" .
               "<th align=left valign=top width='1%'>Updated:</th>" .
               ( "<td width='99%'>" .
                 scalar(gmtime($link->[PAGE_TIME])) .
                 " GMT</td>"
               ) .
               "</tr>"
             );
  }
  if (defined $link->[PAGE_TYPE] and length $link->[PAGE_TYPE]) {
    $html .= ( "<tr>" .
               "<th align=left valign=top width='1%'>Content:</th>" .
               ( "<td width='99%'>$link->[PAGE_TYPE]" .
                 ( $link->[PAGE_SIZE]
                   ? " ($link->[PAGE_SIZE] bytes)"
                   : " (unknown size)" ) .
                 "</td>"
               ) .
               "</tr>"
             );
  }

  $html .= "</table></p>";

  return $html;
}

#------------------------------------------------------------------------------
# Accessors.

sub link_set_status {
  my ($link, $status) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[CHECK_STATUS] = $status;
  $link_rec->[CHECK_TIME]   = time();
}

sub link_set_redirect {
  my ($link, $redirect) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[REDIRECT] = $redirect;
  $link_rec->[CHECK_TIME] = time();
}

sub link_set_title {
  my ($link, $title) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[PAGE_TITLE] = $title;
  $link_rec->[CHECK_TIME] = time();
}

sub link_set_meta_desc {
  my ($link, $desc) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[PAGE_DESC] = $desc;
  $link_rec->[CHECK_TIME] = time();
}

sub link_set_meta_keys {
  my ($link, $keys) = @_;

  my @keys = split(/ *, */, lc($keys));
  my %keys;
  @keys{@keys} = @keys;
  $keys = join(', ', sort keys %keys );

  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[PAGE_KEYS] = $keys;
  $link_rec->[CHECK_TIME] = time();
}

sub link_set_head_time {
  my ($link, $time) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[PAGE_TIME] = $time;
  $link_rec->[CHECK_TIME] = time();
}

sub link_set_head_size {
  my ($link, $size) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[PAGE_SIZE] = $size;
  $link_rec->[CHECK_TIME] = time();
}

sub link_set_head_type {
  my ($link, $type) = @_;
  my $link_rec = $link_by_id{$id_by_link{$link}};
  $link_rec->[PAGE_TYPE] = $type;
  $link_rec->[CHECK_TIME] = time();
}

#------------------------------------------------------------------------------
# Periodically flush links to disk.

POE::Session->new
  ( _start => sub {
      # Flush links in 15 minutes.
      $_[KERNEL]->delay( flush_links => 15 * 60 );
    },

    flush_links => sub {
      # And every half hour thereafter.
      $_[KERNEL]->delay( flush_links => 30 * 60 );
      flush_links();
    },
  );

#------------------------------------------------------------------------------
1;
