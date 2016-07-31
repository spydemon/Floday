#!/usr/bin/env perl

use v5.20;
use strict;
use Floday::Setup;
use YAML::Tiny;
use Log::Any::Adapter('File', 'log.txt');

my $container = Floday::Setup->new('containerName', $ARGV[1]);
my $lxc = $container->getLxcInstance;
my $definition = $container->getDefinition;
$lxc->start if $lxc->isStopped;

my ($h, $a) = $ARGV[1] =~ /(.*?)-(.*)/;
## Get the definition of the current container.
my $runlist = YAML::Tiny->read('/var/lib/floday/runlist.yml');

## Get with a user-friendly way configuration of the parent.
my $hostIp = $runlist->[1]->{$h}->{parameters}->{external_ipv4};

my @websites;
for (values %{$definition->{applications}}) {
	push @websites, $_->{parameters} if $_->{parameters}{type} eq 'riuk-http-php';
}
my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'rc-update add lighttpd');
for (@cmd) {
	$lxc->exec($_);
}
my $ipv4 = $container->getParameter('ipv4');
`iptables -t nat -A PREROUTING -d $hostIp -p tcp --dport 80 -j DNAT --to-destination $ipv4`;

my $data = {
	'containers' => \@websites
};
$container->generateFile('/opt/floday/containers/riuk/children/web/setups/lighttpd/lighttpd.conf.tt', $data, '/etc/lighttpd/lighttpd.conf');

