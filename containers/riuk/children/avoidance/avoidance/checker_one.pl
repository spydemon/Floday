#!/usr/bin/env perl

use lib '/opt/floday/src/';

use v5.20;
use Floday::Setup ('ALLOW_UNDEF', '$APP');

exit 0 if $APP->get_parameter('check_one') eq 'true';
exit 1;
