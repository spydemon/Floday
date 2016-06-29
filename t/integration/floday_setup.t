#!/usr/bin/env perl

use v5.20;
use warnings;
use Floday::Setup;
use Test::More;
use Test::Exception;
use Log::Any::Adapter('File', 'log.txt');
use Data::Dumper;

my $container = Floday::Setup->new('containerName' => 'integration-web-test');
my $iface = $container->getParameter('iface');

like($iface, qr/eth0/, 'Container parameter fetched.');
TODO: {
	throws_ok { $container->getParameter('invalid name'); }
		qr/.*/, 'Espace in parameter name are invalid.';
	throws_ok { $container->getParameter('invalid~~{name'); }
		qr/.*/, 'All non alphanumeric chars should be invalid?';
}
my $lxc = $container->getLxcInstance();
like($lxc->getUtsname, qr/integration-web-test/, 'Virt::LXC instance fetched seems good.');

done_testing;
