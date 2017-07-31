#!/usr/bin/env perl

use v5.20;
use warnings;
use experimental 'smartmatch';

BEGIN {
	push @ARGV, qw/--container integration-web/;
}

use Cwd;
use Floday::Setup ('$APP', 'ALLOW_UNDEF');
use Test::More;
use Test::Exception;
use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');

my $lxc = $APP->getLxcInstance;
$lxc->destroy if $lxc->is_existing;
$lxc->set_template($APP->getParameter('template'));
$lxc->deploy;

my $iface = $APP->getParameter('iface');

like($iface, qr/eth0/, 'Application parameter fetched.');
throws_ok { $APP->getParameter('invalid name'); }
	qr/Parameter "invalid name" asked has an invalid name/, 'Espaces in parameter name is invalid.';
throws_ok { $APP->getParameter('invalid~~{name'); }
	qr/Parameter "invalid~~{name" asked has an invalid name/, 'All non alphanumeric chars should be invalid';
throws_ok { $APP->getParameter('yolooo'); }
	qr/undefined "yolooo" parameter asked for integration-web application./, 'Error throwed when unexsting parameter is asked.';
$APP->getParameter('yolooo', ALLOW_UNDEF);
like($lxc->get_utsname, qr/integration-web/, 'Linux::LXC instance fetched seems good.');

my $parentType = $APP->getParentApplication->getParameter('type');
like($parentType, qr/riuk/, 'Parent fetch seems to work.');

$APP->generateFile('riuk/children/web/children/php/setups/test/test.tt', {$APP->getParameters}, '/tmp/test.txt');
like(`cat /var/lib/lxc/integration-web/rootfs/tmp/test.txt`, qr/Hello web !/, 'generateFile seems to work.');

like ($APP->getRootPath(), qr#/var/lib/lxc/integration-web/rootfs#, 'getRootPath seems to work');

for ($APP->getApplications()) {
	ok($_->getInstancePath() ~~ ['integration-web-test', 'integration-web-secondtest'], 'Test getApplications seems to work');
}

$lxc->destroy;
done_testing;
