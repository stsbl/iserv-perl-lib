# StsBl IServ SCP Perl Library  

package Stsbl::IServ::SCP;
use strict;
use warnings;
use utf8;
use IPC::Run qw(run);
use Net::SCP::Expect;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(scp);
}

sub CleanupKnownHosts($)
{
  my ($host) = @_;

  # Hides output
  run ["ssh-keygen", "-f", "/root/.ssh/known_hosts", "-R", $host], \my $in,
      \my $out, \my $err;
}

sub scp($$$)
{
  my ($host, $source, $destination) = @_;
  
  CleanupKnownHosts $host;

  my $scp = Net::SCP::Expect->new(
    identity_file => "/var/lib/iserv/config/id_rsa",
    verbose => 0,
    auto_yes => 1,
    timeout => 30,
    timeout_auto => 30,
    timeout_err => 30
  );
  $scp->host($host);
  $scp->login("root");
  $scp->scp($source, $destination);

  CleanupKnownHosts $host;
}

1;
