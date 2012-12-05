#!/usr/bin/env perl

# filename   : User.pm
# created at : 2012-12-04 19:06:51
# author     : Jianing Yang <jianingy.yang AT gmail DOT com>

package NetBMS::User;

use JSON::RPC::Client;
use Data::Dumper;

my $account_server = 'http://192.168.1.111:80/postgres/';

sub sync
{
      my %users; 
      my $client = new JSON::RPC::Client;

      $client->prepare($account_server, ['acct']);
      foreach (@{$client->acct({_node => 'wm001.adt100.net'})}) {
	  my %user = %{$_};
	  my @entry = getpwnam($user{acctname});

          $users{$user{acctname}} = 1; # log canonical user;

	  if (@entry) {  # if user exists on this box
              # update user info
              my $uid = $entry[2];
              print STDERR "WARN: uid doesn't match ($uid <-- $user{acctuid})\n"
                  if $uid != $user{acctuid};
              my $out = qx#/usr/sbin/usermod 2>&1 -u '$user{acctuid}' -g 500 -p '$user{acctpass}' '$user{acctname}'#;
              print "ERROR: usermod failed: $out\n" if $?;
	  } else {
              # add new user 
              print STDERR "INFO: newuser $user{acctname}\n";
              my $out = qx#/usr/sbin/useradd 2>&1 -u '$user{acctuid}' -g 500 -p '$user{acctpass}' '$user{acctname}'#;
              print STDERR "ERROR: useradd failed: $out\n" if $?;
	  }
      }

      # get all user names
      open PASSWD, '<', '/etc/passwd';
      while(<PASSWD>) {
        my ($user, $uid) = (split /:/)[0,2];
        next if $uid < 500;
        if (not defined($users{$user})) {
            print STDERR "WARN: rogue user $user $uid\n";
        }
      }
      close PASSWD;
}


1;
