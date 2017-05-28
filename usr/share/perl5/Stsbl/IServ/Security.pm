# StsBl IServ Security Perl Library  

package Stsbl::IServ::Security;
use strict;
use warnings;
use IServ::DB;
use IServ::Tools;
use IServ::Valid;
use sessauth;
use Stsbl::IServ::IO;

BEGIN
{
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(sessauth_auth sessauth_login auth_level req_auth req_priv req_priv_or_root req_flag req_group_owner set_credentials set_ips verify_uid);
}

# variables
my $user;
my $password;
my $auth_level;
my $auth_user;
my $login_ip;
my $login_ip_fwd;
my $m_ip = qr/[\d.:]{1,64}/;

sub sessauth_auth($)
{
  my ($service) = @_;
  if (not defined $password or not defined $user) {
    $auth_level = "none";
  } else {
    IServ::Valid::Act $user;
    IServ::Valid::Passwd $password;
    my $res = sessauth::sessauth $user, $password, $service;
    die "wrong session password\n" unless $res =~ /^OK\b/;
    $auth_level = $res =~ /^OK adm\b/? "admin": "user";
    $auth_user = $user;
  }

  $IServ::DB::logname = IServ::Tools::pwname $user;
  $IServ::DB::logip = $login_ip;
  $IServ::DB::logipfwd = $login_ip_fwd;
}

sub sessauth_login($)
{
  my ($service) = @_;
  
  sessauth::login $user, $password, $service or die "sessauth login failed!";
}

sub auth_level
{
  $auth_level = "none" if not defined $auth_level;

  $auth_level;
}

sub auth_user
{
  $auth_user;
}

sub req_auth
{
  Stsbl::IServ::IO::error "need auth"
    unless (auth_level eq "user") || (auth_level eq "admin");
}

sub req_admin
{
  Stsbl::IServ::IO::error "need admin"
    unless auth_level eq "admin";
}

sub req_priv($)
{
  my ($priv) = @_;
  Stsbl::IServ::IO::error "need privilege $priv\n"
  unless IServ::DB::Do "SELECT 1 FROM users_priv
    WHERE (Act = ? AND Privilege = ?) OR EXISTS (SELECT 1 
    FROM role_privileges r WHERE Privilege = ? 
    AND EXISTS (SELECT 1 FROM user_roles u WHERE 
    u.Act = ? AND u.Role = r.Role)) LIMIT 1",
    $user, $priv, $priv, $user;
}

sub req_priv_or_root($)
{
  req_priv shift unless $user eq "root";
}

sub req_flag($$)
{
  my ($group, $flag) = @_;
  Stsbl::IServ::IO::error "group $group needs flag $flag\n"
  unless IServ::DB::Do "SELECT 1 FROM groups_flag
    WHERE Act = ? AND Flag = ?", $group, $flag;
}

sub req_group_owner($)
{
  my ($group) = @_;
  my $user = auth_user;
  Stsbl::IServ::IO::error "group $group is not owned by $user\n"
  unless IServ::DB::Do "SELECT 1 FROM groups
    WHERE Act = ? AND Owner = ?", $group, $user;
}

sub set_credentials($$)
{
  ($user, $password) = @_;
}

sub set_ips($$)
{
  my ($supp_ip, $supp_ip_fwd) = @_;
  
  ($login_ip) = ($supp_ip // "") =~ /^($m_ip)$/; 
  ($login_ip_fwd) = ($supp_ip_fwd // "") =~ /^($m_ip)$/;
}

sub sudo_context()
{
  return (%ENV and defined $ENV{'SUDO_UID'} and $ENV{'SUDO_UID'});
}

sub verify_uid($)
{
  my $act = shift @_;

  my (undef, undef, $uid) = getpwnam $act or die "getpwnam for $act failed: $!\n";  
  $uid >= 500 or die "UID too low\n";
}

1;

