# StsBl IServ SCP Perl Library  

package Stsbl::IServ::SCP;
use strict;
use warnings;
use utf8;
use Net::SCP::Expect;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(scp);
}

sub scp($$$)
{
  my ($host, $source, $destination) = @_;
  
  system "ssh-keygen", "-f", "/root/.ssh/known_hosts", "-R", $host;

  my $scp = Net::SCP::Expect->new(
    identity_file => "/var/lib/iserv/config/id_rsa",
    verbose => 1, 
    auto_yes => 1,
    timeout => 30,
    timeout_auto => 30,
    timeout_err => 30
  );
  $scp->host($host);
  $scp->login("root");
  $scp->scp($source, $destination);

  system "ssh-keygen", "-f", "/root/.ssh/known_hosts", "-R", $host;
}

1;
