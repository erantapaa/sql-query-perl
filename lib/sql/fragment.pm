use strict;
use warnings;

package sql::fragment;

use Scalar::Util qw/blessed/;

use d;

sub build {
  my $object = shift;
  if (@_) {
    sql::fragment->_new($object, $_[0]);
  } elsif (blessed($object)) {
    $object;
  } elsif (ref($object) eq "ARRAY") {
    my $params = [ @$object[1..$#$object] ];
    sql::fragment->_new($object->[0] // "", $params);
  } elsif (ref($object) eq "") {
    sql::fragment->_new($object);
  } else {
    die "sql::fragment::convert - cannot convert $object to sql::fragment\n";
  }
}

sub build_array {
  [ map { build($_) } @_ ];
}

sub concat {
  sql::fragments->new( map { build($_) } @_ );
}

sub join {
  my ($separator, $list, $pre, $post) = @_;

  unless (ref($list) eq "ARRAY") {
    die "sql::fragment::join - second argument is not an ARRAY";
  }

  sql::fragments::join->new(
    fragments => [ map { build($_) } @$list ],
    separator => $separator,
    pre => $pre // '',
    post => $post // '',
  );
}

sub empty {
  sql::fragment->_new();
}

sub _new {
  my $self = bless {}, shift;
  $self->{string} = shift // "";
  $self->{params} = shift || [];
  $self;
}

sub string { $_[0]->{string} }
sub params { @{ $_[0]->{params} } }

sub not_empty {
  length($_[0]->{string}) || @{$_[0]->{params}}
}

sub to_string {
  my $self = shift;

  "<" . d($self->string) . " " . d([ $self->params ]) . ">";
}

sub append {
  my $self = shift;
  sql::fragments->new( $self, map { sql::fragment::build($_) } @_ );
}

sub prepend {
  my $self = shift;
  sql::fragments->new( map { sql::fragment::build($_) } @_, $self );
}

# -- all of the dbh methods?

sub prepare_execute {
  my ($self, $dbh) = @_;

  my $string = $self->string;
  my @params = $self->params;
  my $sth = $dbh->prepare($string);
  $sth->execute($self->params);
  $sth;
}

sub selectrow_array {
  my ($self, $dbh, $opts) = @_;
  $dbh->selectrow_array($self->string, $opts, $self->params);
}

sub selectrow_arrayref {
  my ($self, $dbh, $opts) = @_;
  $dbh->selectrow_arrayref($self->string, $opts, $self->params);
}

sub selectrow_hashref {
  my ($self, $dbh, $opts) = @_;
  $dbh->selectrow_hashref($self->string, $opts, $self->params);
}

package sql::fragments;

our @ISA = qw/sql::fragment/;

sub new {
  my $self = bless {}, shift;
  $self->{fragments} = [ @_ ];
  $self;
}

sub string {
  my $self = shift;
  join('', map { $_->string } @{$self->{fragments}});
}

sub params {
  my $self = shift;
  map { $_->params } @{$self->{fragments}};
}

sub not_empty {
  my $self = shift;

  for my $f (@{$self->{fragments}}) {
    $f->not_empty && return 1;
  }
  return;
}

package sql::fragments::join;

our @ISA = qw/sql::fragments/;

sub new {
  my $self = bless {}, shift;
  my %args = @_;
  $self->{fragments} = delete $args{fragments};
  $self->{pre} = delete $args{pre} // '';
  $self->{post} = delete $args{post} // '';
  $self->{separator} = delete $args{separator} // '';

  die "unknown initializer(s): @{[ keys %args ]}" if %args;

  $self;
}

sub string {
  my $self = shift;
  join($self->{separator}, map { $self->{pre} . $_->string . $self->{post} } @{$self->{fragments}});
}

1;

