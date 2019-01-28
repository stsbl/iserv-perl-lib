# StsBl IServ IO Perl Library

package Stsbl::IServ::IO;

use strict;
use warnings;
use utf8;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(error);
}

sub error($;$) 
{
  my ($error, $exitcode) = @_;
  print STDERR $error."\n";
  exit ($exitcode // 1);
}

1;
