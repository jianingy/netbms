#!/usr/bin/env perl

# filename   : netbms.pl
# created at : 2012-12-04 19:04:51
# author     : Jianing Yang <jianingy.yang AT gmail DOT com>

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use strict;
use warnings;

sub err
{
    print STDERR "ERROR: ".(shift)."\n";
    exit(1);
}


##############################################################################
#
# main loop
#
##############################################################################
while (<>) {
    chomp;

    last unless $_;

    my ($module_name, $routine_name, $args) = split /\s+/, $_, 3;

    my $module = "NetBMS::".ucfirst($module_name);
    eval {
        (my $path = $module) =~ s#::#/#g;
        require 'modules/' . $path . '.pm';
        $module->import();
        1;
    } or err("module does not exist: $@");

    $routine_name = 'default' unless $routine_name;
    my $routine = $module."::".$routine_name;
    err('routine does not exist') unless (defined &{$routine});

    # execute routine
    eval "$routine(\$args)";

    # exit after routine executed
    last;
}
