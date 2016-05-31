#!/usr/bin/env perl
use v5.20;
use strict;

use Test::More;
$ENV{FLODAY_CONTAINERS} = '/opt/floday/t/floday.d/containers/';

`../src/floday.pl --run floday.d/runfile.xml --host spyzone`;
