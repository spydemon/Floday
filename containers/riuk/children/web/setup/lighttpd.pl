#!/usr/bin/env perl

use v5.20;

use lib '/opt/floday/src/';
use File::Temp;
use Virt::LXC;
use Template::Alloy;
use YAML::Tiny;
use Getopt::Long;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $runlist = YAML::Tiny->read('/usr/lib/floday/runlist.yml');
my $c;
GetOptions(
	"container=s" => \$c
);

my ($h, $a) = $c =~ /(.*?)-(.*)/;
my $definition = $runlist->[1]->{$h};

my $hostIp = $runlist->[1]->{$h}->{parameters}->{external_ipv4};

for (split /-/, $a) {
	$definition = $definition->{applications}->{$_};
}

my @websites;
for (values $definition->{applications}) {
	push @websites, $_->{parameters};
}

my $container = Virt::LXC->new($definition->{parameters}{name});
$container->start if $container->isStopped;

my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'rc-update add lighttpd');
for (@cmd) {
	$container->exec($_);
}

my $configuration = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);

my $data = {
	'containers' => \@websites
};

$t->process('/opt/floday/containers/riuk/children/web/setup/lighttpd/lighttpd.conf.tt', $data, $configuration) or die $t->error;
$container->put($configuration, '/etc/lighttpd/lighttpd.conf');

`iptables -t nat -A PREROUTING -d $hostIp -p tcp --dport 80 -j DNAT --to-destination $definition->{parameters}->{ipv4}`;
