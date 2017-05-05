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
  my $known_hosts_file = "/tmp/stsbl-iserv-openssh-".$random->string_from('0123456789', 10);

  # untain variables (TODO why is this neccessary?!)
  if ($stdout_file =~ /^(.*)$/) {
    $stdout_file = $1;
  } else {
    die "Failed to untain data!";
  }
  if ($stderr_file =~ /^(.*)$/) {
    $stderr_file = $1;
  } else {
    die "Failed to untain data!";
  }
  if ($known_hosts_file =~ /^(.*)$/) {
    $known_hosts_file = $1;
  } else {
    die "Failed to untain data!";
  }

  foreach my $file (($stdout_file, $stderr_file, $known_hosts_file))
  {
    $touch->touch($file) or die "Couldn't touch file $file: $!";
    chmod 00600, $file or die "Couldn't chmod file $file: $!";
  }

  open my $stdout_fh, ">>", $stdout_file;
  open my $stderr_fh, ">>", $stderr_file;

  my $ssh = Net::OpenSSH->new(
    $ip,
    master_opts => [-i => "/var/lib/iserv/config/id_rsa", -o => "StrictHostKeyChecking=no", -o => "UserKnownHostsFile=$known_hosts_file"],
    user => "root",
    default_stdout_fh => $stdout_fh,
    default_stderr_fh => $stderr_fh
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
  
  if (scalar @err > 0)
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
