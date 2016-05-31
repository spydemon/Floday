#!/usr/bin/env perl

use v5.20;
use Virt::LXC;

my $test = Virt::LXC->new('test');
#my $test = Virt::LXC->new();
$test->setTemplate('alpine');
$test->deploy();
#$test->deploy();
