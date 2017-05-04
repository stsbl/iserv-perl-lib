# Linux client control using OpenSSH Library
# with support for reading stdout/stderr

package Stsbl::IServ::OpenSSH;
use strict;
use utf8;
use warnings;
use Bytes::Random::Secure;
use File::Touch;
use IServ::IO;
use Net::OpenSSH;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(openssh_run);
}

sub openssh_run($@)
{
  my ($ip, @cmd) = @_;
  my @err;
  my $random = new Bytes::Random::Secure();
  my $touch = new File::Touch();

  my $stdout_file = "/tmp/stsbl-iserv-openssh-".$random->string_from('0123456789', 10);
  my $stderr_file = "/tmp/stsbl-iserv-openssh-".$random->string_from('0123456789', 10);
  $touch->touch($stdout_file);
  $touch->touch($stderr_file);
  # protect *out files from world-wide access
  chmod 00600, $stdout_file;
  chmod 00600, $stderr_file;

  open my $stdout_fh, '>>', $stdout_file;
  open my $stderr_fh, '>>', $stderr_file;

  my $ssh = Net::OpenSSH->new(
    $ip,
    master_stderr_fh => $stderr_fh,
    master_stdout_fh => $stdout_fh,
    user => "root",
    key_path => "/var/lib/iserv/config/id_rsa"
  );

  if (not $ssh->error)
  {
    $ssh->system(@cmd);
    if ($ssh->error) 
    {
      push @err, "Could not execute cmd @cmd: $ssh->error";
    }
  } else {
    push @err, "Could not connect to Port 22: $ssh->error";
  } 
  return wantarray ? @err : print STDERR @err;
  print STDERR @err;
  
  my %ret;
  $ret{stdout} = IServ::IO::getfile $stdout_file;
  $ret{stderr} = IServ::IO::getfile $stderr_file;
  unlink $stdout_file;
  unlink $stderr_file;

  return %ret;
}

1;
