#!/usr/bin/env perl

# filename   : User.pm
# created at : 2012-12-04 19:06:51
# author     : Jianing Yang <jianingy.yang AT gmail DOT com>


# Account Server could be any server honor the following JSON-RPC spec
# 
# 1. required function: acct(node=[nodename])
# 2. required return: acctname, acctuid, acctpass
#
# Here, acctpass is an encrypted password string
#

# Configuration
# create a file named config.pl in the same directory where netbms.pl 
# placed with the following content
#
# $account_server = 'http://[accountserver]'
# $account_default_gid = [default group id]

package NetBMS::User;

use strict;
use warnings;

use JSON::RPC::Client;
use Data::Dumper;
use Sys::Hostname;
use FindBin qw/$Bin/;

our $account_server = undef; 
our $account_default_gid = 100;
our $account_umask = '022';

require "$Bin/conf/config.pl";

sub sync
{

      my %users; 
      my $client = new JSON::RPC::Client;

      &main::err('user module configuration error')
          unless defined($account_server) && defined($account_default_gid);
      print "umask = $account_umask\n";
      $client->prepare($account_server, ['acct']);
      foreach (@{$client->acct({_node => hostname})}) {
	  my %user = %{$_};
          #print STDERR Dumper(\%user);
	  my @entry = getpwnam($user{acctname});

          $users{$user{acctname}} = 1; # log canonical user;

	  if (@entry) {  # if user exists on this box
              # update user info
              my $uid = $entry[2];
              &main::out('WARN', "uid doesn't match ($uid <-- $user{acctuid})")
                  if $uid != $user{acctuid};
              my $out = qx#/usr/sbin/usermod 2>&1 -u '$user{acctuid}' -g $account_default_gid -p '$user{acctpass}' '$user{acctname}'#;
              &main::out('ERROR', "usermod failed: $out") if $?;
	  } else {
              # add new user 
              &main::out('INFO', "newuser $user{acctname}");
              my $out = qx#/usr/sbin/useradd 2>&1 -u '$user{acctuid}' -g $account_default_gid -p '$user{acctpass}' -K 'UMASK=$account_umask' '$user{acctname}'#;
              &mainLLout('ERROR', "useradd failed: $out") if $?;
	  }
      }

      # get all user names
      open PASSWD, '<', '/etc/passwd';
      while(<PASSWD>) {
        my ($user, $uid) = (split /:/)[0,2];
        next if $uid < 500;
        if (not defined($users{$user})) {
            &main::out('WARN', "rogue user $user $uid");
        }
      }
      close PASSWD;
}


1;


#vim: ts=4 sw=4 ai et
