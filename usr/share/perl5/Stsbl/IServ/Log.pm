# StsBl IServ Log Perl Library

package Stsbl::IServ::Log;
use strict;
use warnings;
use IServ::DB;
use Stsbl::IServ::Security;

sub write_for_module($$)
{
  my ($text, $module) = @_;
  my %row;
  $row{module} = $module;

  IServ::DB::Log $text, %row;
}

1;
