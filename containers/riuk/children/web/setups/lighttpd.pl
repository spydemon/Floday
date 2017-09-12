#!/usr/bin/env perl

use v5.20;
use strict;
use Floday::Setup;
use YAML::Tiny;
use Log::Any::Adapter('File', 'log.txt');

my $lxc = $APP->get_lxc_instance;
my $definition = $APP->get_definition;
$lxc->start if $lxc->is_stopped;

my $hostIp = $APP->get_parent_application()->get_parameter('external_ipv4');

my @websites;
for (values %{$definition->{applications}}) {
	push @websites, $_->{parameters} if $_->{parameters}{container_path} eq 'riuk-web-php';
}
my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'rc-update add lighttpd');
for (@cmd) {
	$lxc->exec($_);
}
my $ipv4 = $APP->get_parameter('ipv4');
`iptables -t nat -A PREROUTING -d $hostIp -p tcp --dport 80 -j DNAT --to-destination $ipv4`;

my $data = {
	'containers' => \@websites
};
$APP->generate_file('riuk/children/web/setups/lighttpd/lighttpd.conf.tt', $data, '/etc/lighttpd/lighttpd.conf');

