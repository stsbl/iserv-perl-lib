# StsBl IServ SCP Perl Library  

package Stsbl::IServ::SCP;
use strict;
use warnings;
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
  my $scp = Net::SCP::Expect->new(identity_file => "/var/lib/iserv/config/id_rsa", verbose => 1, auto_yes => 1);
  $scp->host($host);
  $scp->login("root");
  $scp->scp($source, $destination);
}

1;
