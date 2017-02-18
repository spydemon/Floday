#!/usr/bin/env perl

use v5.20;
use strict;
use Floday::Setup;

my $lxc = $APP->getLxcInstance();
$lxc->exec('echo "end_setup works" > /etc/endsetup');
