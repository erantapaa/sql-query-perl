
# this file should be required, not used

sub is_fragment {
  my $test = shift;
  my ($got, $string, $params);
  if (ref($test)) { # likey $test is $got
    $got = $test;
    $test = "";
    ($string, $params) = @_;
  } else {
    ($got, $string, $params) = @_;
  }

  is($got->string, $string, "$test-string");
  is_deeply( [ $got->params ], $params, "$test-params");
}

1;

