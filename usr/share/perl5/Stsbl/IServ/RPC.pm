# StsBl IServ RPC Perl Library

package Stsbl::IServ::RPC;
use warnings;
use strict;
use Encode qw(encode);
use IServ::RPC;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(rcp_message_unicode);
}

sub rpc_message_unicode($$)
{
  my ($ip, $msg) = @_;
  $msg =~ s/\r?\n/\r/g;
  my @err;
  # NO decoding here, it already breaks special chars like umlauts!
  # Just encode to iso-8859-2 here and set the code page of
  # cmd on client to utf-8 (code page 65001).
  $msg = encode("iso-8859-2", $msg);
  # real limit seems to be at about 4320 chars:
  if (length $msg > 4096)
  {
    @err = "rpc_message_unicode: message too long\n";
  }
  else
  {
    @err = IServ::RPC::winexe $ip, "cmd", "/c", "chcp 65001", ">NUL", "&", IServ::RPC::netlogon "exe\\start", "iserv-msg", $msg;
  }
  wantarray? @err: print STDERR @err;
}

1;
