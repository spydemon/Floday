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

## Get the definition of the current container.
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
my $container = Virt::LXC->new('utsname' => $definition->{parameters}{name});
$container->start if $container->isStopped;

## Get with a user-friendly way configuration of the parent.
my $hostIp = $runlist->[1]->{$h}->{parameters}->{external_ipv4};

my @websites;
for (values %{$definition->{applications}}) {
	push @websites, $_->{parameters} if $_->{parameters}{type} eq 'riuk-http-php';
}
my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'rc-update add lighttpd');
for (@cmd) {
	$container->exec($_);
}
`iptables -t nat -A PREROUTING -d $hostIp -p tcp --dport 80 -j DNAT --to-destination $definition->{parameters}->{ipv4}`;

## Parse in a user-friendly way a configuration file with an hash.
my $configuration = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);
my $data = {
	'containers' => \@websites
};
$t->process('/opt/floday/containers/riuk/children/web/setup/lighttpd/lighttpd.conf.tt', $data, $configuration) or die $t->error;
$container->put($configuration, '/etc/lighttpd/lighttpd.conf');

