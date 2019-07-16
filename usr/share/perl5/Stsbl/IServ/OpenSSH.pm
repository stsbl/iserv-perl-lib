# Linux client control using OpenSSH Library
# with support for reading stdout/stderr

package Stsbl::IServ::OpenSSH;
use strict;
use utf8;
use warnings;
use File::Temp qw(tempfile);
use File::Touch;
use Net::OpenSSH;
use Path::Tiny;

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
  my ($stdout_fh, $stdout_file) = tempfile("stsblssh_XXXXXX", OPEN => 1, DIR => "/tmp");
  my ($stderr_fh, $stderr_file) = tempfile("stsblssh_XXXXXX", OPEN => 1, DIR => "/tmp");
  my (undef, $known_hosts_file) = tempfile("stsblssh_XXXXXX", OPEN => 0, DIR => "/tmp");

  for my $file (($stdout_file, $stderr_file, $known_hosts_file))
  {
    touch $file or die "Couldn't touch file $file: $!";
    chmod 00600, $file or die "Couldn't chmod file $file: $!";
  }

  my $ssh = Net::OpenSSH->new(
    $ip,
    master_opts => [
      -i => "/var/lib/iserv/portal/ssh/id_ed25519",
      -i => "/var/lib/iserv/portal/ssh/id_rsa",
      -o => "StrictHostKeyChecking=no",
      -o => "UserKnownHostsFile=$known_hosts_file",
      -o => "ConnectTimeout=30",
      -o => "LogLevel=ERROR",
      -o => "PreferredAuthentications=publickey"
    ],
    user => "root",
    default_stdout_fh => $stdout_fh,
    default_stderr_fh => $stderr_fh
  );

  if (not $ssh->error)
  {
    $ssh->system(@cmd);

    if ($ssh->error) 
    {
      push @err, "Could not execute cmd @cmd on host with IP $ip!\n";
    }
  }
  else
  {
    push @err, "Could not connect to port 22 of host with IP $ip!\n";
  }
  # close connection and write output
  undef $ssh;
  
  if (scalar @err > 0)
  {
    print STDERR @err;
  }

  my %ret;
  $ret{stdout} = path($stdout_file)->slurp_utf8;
  $ret{stderr} = path($stderr_file)->slurp_utf8;
  
  # clean up
  unlink $known_hosts_file, $stdout_file, $stderr_file or
      warn "Couldn't unlink temporary files: $!\n";

  %ret;
}

1;
