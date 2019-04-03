# StsBl IServ Log Perl Library

package Stsbl::IServ::Log;
use strict;
use warnings;
use Encode qw(decode);
use IServ::DB;

our $logip;
our $logipfwd;
our $logname;

sub write_for_module($$)
{
  my ($text, $module) = @_;
  my %row;
  $row{module} = $module;

  $text = $text;
  IServ::DB::Log $text, %row;
}

sub log_store($;%)
{
  my ($text, %row) = @_;
  $logname = (getpwuid ((!$< and %ENV and defined $ENV{'SUDO_UID'}) ? $ENV{'SUDO_UID'} : $<))[6] unless defined $logname;
  $row{"name"} = $logname;
  $row{"ip"} = $logip;
  $row{"ipfwd"} = $logipfwd;
  $row{"text"} = $text;
  IServ::DB::Store "log", \%row;
}

1;
