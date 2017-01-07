#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Log::Any::Adapter('+Floday::Helper::Logging');
use Log::Any;

my $logger = Log::Any->get_logger('category', 'test', 'log_level', 'tracefuck');
$logger->debugf('It is just a test %s.', 'oz');

