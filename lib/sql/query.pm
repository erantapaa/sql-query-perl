
use strict;
use warnings;

use sql::fragment;

package sql::query;

sub new {
  my $self = bless {}, shift;
  $self->{parent} = shift;

  # $self->{selects}      - an ARRAY of fragments
  # $self->{conditions}   - an ARRAY of fragments
  # $self->{joins}        - an ARRAY of fragments

  $self;
}

sub parent { shift->{parent} }

sub statement {
  my $self = shift;
  my $select_clause = $self->select_clause;
  my $from_clause = $self->from_clause;
  my $where_clause = $self->where_clause;
  my $order_clause = $self->order_clause;

  sql::fragment::concat(
    "SELECT ",
       ($select_clause->not_empty ? $select_clause : "*"),
    " ",
    "FROM ",
       ($from_clause->not_empty ? $from_clause : "DUAL"),
    ($where_clause->not_empty ? (" WHERE ", $where_clause) : ()),
    ($order_clause->not_empty ? (" ORDER BY ", $order_clause) : ())
  );
}

sub select_clause {
  my $self = shift;
  my @list = $self->select_fragments;
  sql::fragment::join(",", \@list);
}

sub select_fragments {
  my $self = shift;
  my @list;
  if (my $p = $self->parent) {
    @list = $p->select_fragments;
  }
  push(@list, @{ $self->{select_fragments} }) if $self->{select_fragments};
  @list;
}

sub where_clause {
  my $self = shift;
  my @list = $self->where_fragments;
  sql::fragment::join(" AND ", \@list, "(", ")");
}

sub where_fragments {
  my $self = shift;
  my @list;
  if (my $p = $self->parent) {
    @list = $p->where_fragments;
  }
  push(@list, @{ $self->{where_fragments} }) if $self->{where_fragments};
  @list;
}

sub from_clause {
  my $self = shift;
  my @list = $self->from_fragments;

  sql::fragment::join(" ", \@list);
}

sub from_fragments {
  my $self = shift;

  my @list;
  if (my $p = $self->parent) {
    @list = $p->from_fragments;
  }

  if (my $f = $self->{from_fragment}) {
    my ($join, $table, $cond) = @{ $self->{from_fragment} };

    if (@list == 0 && $join ne "JOIN") {
      die "first table must be a JOIN, not $join";
    }

    my @on_clause = $cond->not_empty ? (" ON (", $cond, ")") : ();
    my $join_phrase = @list ? "$join $table" : $table;
  
    push(@list, sql::fragment::concat($join_phrase, @on_clause));
  }

  @list;
}

sub order_clause {
  my $self = shift;
  my @list = $self->order_fragments;

  sql::fragment::join(",", \@list);
}

sub order_fragments {
  my $self = shift;

  my @list;
  if (my $p = $self->parent) {
    @list = $p->order_fragments;
  }

  if ($self->{order_fragment}) {
    push(@list, $self->{order_fragment});
  }

  @list;
}

# query constructor methods

sub select {  # add selections
  my $self = shift;

  my $new = sql::query->new($self);
  $new->{select_fragments} = sql::fragment::build_array(@_);
  $new;
}

sub join {
  my $self = shift;
  my $table = shift;

  my $new = sql::query->new($self);

  $new->{from_fragment} = [ "JOIN", $table, sql::fragment::concat(@_) ];
  $new;
}

sub left_join {
  my $self = shift;
  my $table = shift;

  my $new = sql::query->new($self);

  $new->{from_fragment} = [ "LEFT JOIN", $table, sql::fragment::concat(@_) ];
  $new;
}

sub search {
  my $self = shift;

  my $new = sql::query->new($self);

  $new->{where_fragments} = sql::fragment::build_array(@_);
  $new;
}

sub order_by {
  my $self = shift;

  my $new = sql::query->new($self);
  $new->{order_fragment} = sql::fragment::join(", ", \@_);
  $new;
}

1;

