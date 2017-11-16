#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup ('ALLOW_UNDEF', '$APP');
use Log::Any::Adapter('File', 'log.txt');

my $lxc = $APP->get_lxc_instance;
my $data_in = $APP->get_parameter('data_in', ALLOW_UNDEF);
my $data_out = $APP->get_parameter('data_out', ALLOW_UNDEF);

if (defined $data_in && defined $data_out) {
	$lxc->start if $lxc->is_stopped;
	$lxc->put($data_in, $data_out);
}
