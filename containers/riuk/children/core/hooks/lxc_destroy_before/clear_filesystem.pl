#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;

my $container_nbr = `lxc-ls -1 | wc -l`;
chomp $container_nbr;
`echo $container_nbr > /tmp/floday/lxc_destroy_before`;
