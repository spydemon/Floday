#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup ('ALLOW_UNDEF');
use Log::Any::Adapter('File', 'log.txt');

my $application = Floday::Setup->new('instancePath' => $ARGV[1]);
my $lxc = $application->getLxcInstance;
my $data_in = $application->getParameter('data_in', ALLOW_UNDEF);
my $data_out = $application->getParameter('data_out', ALLOW_UNDEF);

if (defined $data_in && defined $data_out) {
	$lxc->start if $lxc->isStopped;
	$lxc->put($data_in, $data_out);
}
