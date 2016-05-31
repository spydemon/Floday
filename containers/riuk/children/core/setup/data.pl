#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use YAML::Tiny;
use Data::Dumper;
use Getopt::Long;
use File::Temp;
use Virt::LXC;
use Template::Alloy;
use strict;

$Data::Dumper::Indent = 1;

## Get the definition of the current container
my $runlist = YAML::Tiny->read('/var/lib/floday/runlist.yml');
my $c;
GetOptions(
	"container=s" => \$c
);
my ($h, $a) = $c =~ /(.*?)-(.*)/;
my $definition = $runlist->[1]->{$h};
for (split /-/, $a) {
	$definition = $definition->{applications}->{$_};
}

## Get directly a container object
my $container = Virt::LXC->new($definition->{parameters}{name});
$container->start if $container->isStopped;

## Real action of the setup
$container->put($definition->{parameters}{data_in}, $definition->{parameters}{data_out});
