#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup ('ALLOW_UNDEF', '$APP');

my $application_path = $APP->get_application_path();

`mkdir -p /tmp/floday/avoidance/$application_path`;
`touch /tmp/floday/avoidance/$application_path/always_executed`;

# This avoidance check always flag application as avoidable.
# The meaning of this avoidance script is just to check it it will be executed even if a previous one flags the
# application as avoidable.
exit 0;
