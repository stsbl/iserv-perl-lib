# StsBl IServ IO Perl Library

package Stsbl::IServ::IO;
use strict;
use warnings;

sub error($) {
  my ($error) = @_;
  print STDERR $error."\n";
  exit(1);
}

1;
