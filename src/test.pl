#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Log::Any::Adapter('+Floday::Helper::Logging');
use Log::Any;

use Data::Dumper;

my $logger = Log::Any->get_logger('category', 'test', 'log_level', 'tracefuck');
$logger->{adapter}{indent} = 4;
$logger->tracef('It is just a test %s.', 'oz');

