#!/usr/bin/env perl

use v5.20;
use strict;
use Floday::Setup;
use YAML::Tiny;
use Log::Any::Adapter('File', 'log.txt');

my $lxc = $APP->getLxcInstance;
my $definition = $APP->getDefinition;
$lxc->start if $lxc->is_stopped;

my $hostIp = $APP->getParentApplication()->getParameter('external_ipv4');

my @websites;
for (values %{$definition->{applications}}) {
	push @websites, $_->{parameters} if $_->{parameters}{container_path} eq 'riuk-web-php';
}
my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'rc-update add lighttpd');
for (@cmd) {
	$lxc->exec($_);
}
my $ipv4 = $APP->getParameter('ipv4');
`iptables -t nat -A PREROUTING -d $hostIp -p tcp --dport 80 -j DNAT --to-destination $ipv4`;

my $data = {
	'containers' => \@websites
};
$APP->generateFile('/opt/floday/containers/riuk/children/web/setups/lighttpd/lighttpd.conf.tt', $data, '/etc/lighttpd/lighttpd.conf');

