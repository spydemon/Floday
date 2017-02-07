#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;

my $FILE = '/tmp/floday/test_lxc_hooks';
die ("The $FILE file should not be already existing") if -r $FILE;
`touch /tmp/floday/test_lxc_hooks`;
