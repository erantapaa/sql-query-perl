package d;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = ('d');

use Data::Dumper;

sub d {
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Useqq = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Sortkeys = 1;
  Dumper( shift );
}

1;

