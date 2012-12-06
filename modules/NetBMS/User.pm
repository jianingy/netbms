#!/usr/bin/env perl

# filename   : User.pm
# created at : 2012-12-04 19:06:51
# author     : Jianing Yang <jianingy.yang AT gmail DOT com>

package NetBMS::User;

use JSON::RPC::Client;
use Data::Dumper;
use Sys::Hostname;

my $account_server = 'http://192.168.1.111:80/postgres/';

sub sync
{
      my %users; 
      my $client = new JSON::RPC::Client;

      $client->prepare($account_server, ['acct']);
      foreach (@{$client->acct({_node => hostname})}) {
	  my %user = %{$_};
	  my @entry = getpwnam($user{acctname});

          $users{$user{acctname}} = 1; # log canonical user;

	  if (@entry) {  # if user exists on this box
              # update user info
              my $uid = $entry[2];
              &main::out('WARN', "uid doesn't match ($uid <-- $user{acctuid})")
                  if $uid != $user{acctuid};
              my $out = qx#/usr/sbin/usermod 2>&1 -u '$user{acctuid}' -g 500 -p '$user{acctpass}' '$user{acctname}'#;
              &main::out('ERROR', "usermod failed: $out") if $?;
	  } else {
              # add new user 
              &main::out('INFO', "newuser $user{acctname}");
              my $out = qx#/usr/sbin/useradd 2>&1 -u '$user{acctuid}' -g 500 -p '$user{acctpass}' '$user{acctname}'#;
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
