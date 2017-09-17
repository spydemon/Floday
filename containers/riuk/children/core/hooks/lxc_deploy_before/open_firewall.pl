#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;

use Floday::Setup;

my $FILE = '/tmp/floday/test_lxc_hooks';
my $path = $APP->get_application_path();
`mkdir -p /tmp/floday/`;
die ("The $FILE file should not be already existing") if -r $FILE;
`echo $path > /tmp/floday/test_lxc_hooks`;
sleep 5;
