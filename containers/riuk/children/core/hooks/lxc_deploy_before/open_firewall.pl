#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;

my $FILE = '/tmp/floday/test_lxc_hooks';
`mkdir -p /tmp/floday/`;
die ("The $FILE file should not be already existing") if -r $FILE;
`touch /tmp/floday/test_lxc_hooks`;
sleep 5;
