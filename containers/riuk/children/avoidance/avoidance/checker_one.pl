#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup ('ALLOW_UNDEF', '$APP');

my $application_path = $APP->get_application_path();
`mkdir -p /tmp/floday/avoidance/$application_path && touch /tmp/floday/avoidance/$application_path/avoidance_script_lanched`;

exit 0 if $APP->get_parameter('check_one') eq 'true';
exit 1;
