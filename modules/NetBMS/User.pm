#!/usr/bin/env perl

# filename   : User.pm
# created at : 2012-12-04 19:06:51
# author     : Jianing Yang <jianingy.yang AT gmail DOT com>

package NetBMS::User;

use JSON::RPC::Client;
use Data::Dumper;

my $account_server = 'http://localhost:8080/postgres/';

sub sync
{
      my $client = new JSON::RPC::Client;

      $client->prepare($account_server, ['acct']);
      foreach (@{$client->acct({_node => 'wm001.adt100.net'})}) {
	  my %user = %{$_};
	  my @entry = getpwnam($user{acctname});
	  if (@entry) {
	      print "X:@entry\n";
	  } else {
	      print "X:@entry\n";
	  }
      }
}


1;
