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

my $container = Virt::LXC->new($definition->{parameters}{name});
$container->start if $container->isStopped;

my $interface = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);
$t->process('/opt/floday/containers/riuk/children/core/setup/network.tt', $definition->{parameters}, $interface) or die $t->error;
die 'The container doesn\'t exist' if !$container->isExisting;
$container->put($interface, '/etc/network/interfaces');
$container->exec('rc-update add networking');

$container->stop;
