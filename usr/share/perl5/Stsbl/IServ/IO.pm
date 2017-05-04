# StsBl IServ IO Perl Library

package Stsbl::IServ::IO;
use strict;
use warnings;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(error);
}

sub error($) {
  my ($error) = @_;
  print STDERR $error."\n";
  exit(1);
}

1;
