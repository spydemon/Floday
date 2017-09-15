#!/usr/bin/env perl

use v5.20;
use warnings;
use experimental 'smartmatch';

BEGIN {
	push @ARGV, qw/--application integration-web/;
}

use Cwd;
use Floday::Setup ('$APP', 'ALLOW_UNDEF');
use Test::More;
use Test::Exception;
use Log::Any::Adapter('+Floday::Helper::Logging', 'log_level', 'trace');

my $lxc = $APP->get_lxc_instance;
$lxc->destroy if $lxc->is_existing;
$lxc->set_template($APP->get_parameter('template'));
$lxc->deploy;

my $iface = $APP->get_parameter('iface');

like($iface, qr/eth0/, 'Application parameter fetched.');
throws_ok { $APP->get_parameter('invalid name'); }
	qr/Parameter "invalid name" asked has an invalid name/, 'Espaces in parameter name is invalid.';
throws_ok { $APP->get_parameter('invalid~~{name'); }
	qr/Parameter "invalid~~{name" asked has an invalid name/, 'All non alphanumeric chars should be invalid';
throws_ok { $APP->get_parameter('yolooo'); }
	qr/undefined "yolooo" parameter asked for integration-web application./, 'Error throwed when unexsting parameter is asked.';
$APP->get_parameter('yolooo', ALLOW_UNDEF);
like($lxc->get_utsname, qr/integration-web/, 'Linux::LXC instance fetched seems good.');

my $parentType = $APP->get_parent_application->get_parameter('type');
like($parentType, qr/riuk/, 'Parent fetch seems to work.');

$APP->generate_file('riuk/children/web/children/php/setups/test/test.tt', {$APP->get_parameters}, '/tmp/test.txt');
like(`cat /var/lib/lxc/integration-web/rootfs/tmp/test.txt`, qr/Hello web !/, 'generate_file seems to work.');

like ($APP->get_root_path(), qr#/var/lib/lxc/integration-web/rootfs#, 'get_root_path seems to work');

for ($APP->get_applications()) {
	ok($_->get_application_path() ~~ ['integration-web-test', 'integration-web-secondtest'], 'Test get_applications seems to work');
}

$lxc->destroy;
done_testing;
