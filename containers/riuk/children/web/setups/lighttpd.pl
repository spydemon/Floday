#!/usr/bin/env perl

use v5.20;
use strict;
use Floday::Setup;
use YAML::Tiny;
use Log::Any::Adapter('File', 'log.txt');

my $application = Floday::Setup->new('instancePath', $ARGV[1]);
my $lxc = $application->getLxcInstance;
my $definition = $application->getDefinition;
$lxc->start if $lxc->is_stopped;

my ($h, $a) = $ARGV[1] =~ /(.*?)-(.*)/;
## Get the definition of the current application.
my $runlist = YAML::Tiny->read('/var/lib/floday/runlist.yml');

## Get with a user-friendly way configuration of the parent.
my $hostIp = $runlist->[1]->{$h}->{parameters}->{external_ipv4};

my @websites;
for (values %{$definition->{applications}}) {
	push @websites, $_->{parameters} if $_->{parameters}{container_path} eq 'riuk-web-php';
}
my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'rc-update add lighttpd');
for (@cmd) {
	$lxc->exec($_);
}
my $ipv4 = $application->getParameter('ipv4');
`iptables -t nat -A PREROUTING -d $hostIp -p tcp --dport 80 -j DNAT --to-destination $ipv4`;

my $data = {
	'containers' => \@websites
};
$application->generateFile('/opt/floday/containers/riuk/children/web/setups/lighttpd/lighttpd.conf.tt', $data, '/etc/lighttpd/lighttpd.conf');

