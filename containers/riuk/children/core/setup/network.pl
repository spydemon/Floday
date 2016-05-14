#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use YAML::Tiny;
use Data::Dumper;
use Getopt::Long;
use File::Temp;
use Virt::LXC;
use strict;

$Data::Dumper::Indent = 1;

my $runlist = YAML::Tiny->read('/usr/lib/floday/runlist.yml');
my $c;
GetOptions(
	"container=s" => \$c
);

my ($h, $a) = $c =~ /(.*?)-(.*)/;
my $definition = $runlist->[1]->{$h};

for (split /-/, $a) {
	$definition = $definition->{applications}->{$_};
}

open INT, '</opt/floday/containers/riuk/children/core/setup/network.tmpl';
my $interface = File::Temp->new();
open OUT, '>', $interface;

while(<INT>) {
	$_ =~ s/\{\{(.*)\}\}/$definition->{parameters}{$1}/g;
	print OUT $_;
}

my $container = Virt::LXC->new($definition->{parameters}{name});
die 'The container doesn\'t exist' if !$container->isExisting;
$container->put($interface, '/etc/network/interfaces');

say $definition->{parameters}{ech};
say Dumper $definition;

$c =~ s/-/}->{children}->{/g;
$c = '{'.$c.'}';
