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
  # Redirect stdderr temporary to prevent annoying warning of ssh :/
  open OLDSTDERR, ">&STDERR" or die "Couldn't redirect OLDSTDERR: $!";
  open STDERR, ">/dev/null" or die "Couldn't redirect STDERR: $!";
  my $stdout_file = "/tmp/stsbl-iserv-openssh-".$random->string_from('0123456789', 10);
  my $stderr_file = "/tmp/stsbl-iserv-openssh-".$random->string_from('0123456789', 10);
  my $known_hosts_file = "/tmp/stsbl-iserv-openssh-".$random->string_from('0123456789', 10);
  $touch->touch($stdout_file) or die "Couldn't touch file $stdout_file: $!";
  $touch->touch($stderr_file) or die "Couldn't touch file $stderr_file: $!";
  $touch->touch($known_hosts_file) or die "Couldn't touch file $known_hosts_file: $!";
  # protect files from world-wide access
  chmod 00600, $stdout_file or die "Couldn't chmod file $stdout_file: $!";
  chmod 00600, $stderr_file or die "Couldn't chmod file $stderr_file: $!";
  chmod 00600, $known_hosts_file or die "Couldn't chmod file $known_hosts_file: $!";

  open my $stdout_fh, ">>", $stdout_file;
  open my $stderr_fh, ">>", $stderr_file;

  my $ssh = Net::OpenSSH->new(
    $ip,
    master_opts => [-i => "/var/lib/iserv/config/id_rsa", -o => "StrictHostKeyChecking=no", -o => "UserKnownHostsFile=$known_hosts_file"],
    user => "root",
    default_stdout_fh => $stdout_fh
  );

  if (not $ssh->error)
  {
    $ssh->system(@cmd);
    if ($ssh->error) 
    {
      push @err, "Could not execute cmd!";
    }
  } else {
    push @err, "Could not connect to Port 22!";
  }
  # close connection and write output
  undef $ssh;
  
  # restore stderr
  open STDERR, ">&OLDSTDERR" or die "Couldn't redirect STDERR: $!";;
  close OLDSTDERR or die "Couldn't close OLDSTDERR: $!";;

  if (@err > 0)
  {
    print STDERR @err;
  }

  my %ret;
  $ret{stdout} = getfile $stdout_file;
  $ret{stderr} = getfile $stderr_file;
  
  # clean up
  unlink $stdout_file or warn "Couldn't unlink file $stdout_file: $!";
  unlink $stderr_file or warn "Couldn't unlink file $stderr_file: $!";
  unlink $known_hosts_file or warn "Couldn't unlink file $known_hosts_file: $!";

  return %ret;
}

1;
