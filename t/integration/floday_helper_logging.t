#!/usr/bin/env perl

use v5.20;
use warnings;
use strict;

use Log::Any;
use Log::Any::Adapter('+Floday::Helper::Logging');

use Test::More;

my $logger = Log::Any->get_logger();

cmp_ok (
  $ENV{'FLODAY_LOGGING_IDENTIFIER'},
  'eq',
  'floday',
  'Test FLODAY_LOGGING_IDENTIFIER default value.'
);
$logger->{adapter}->identifier_set('ident_test');
cmp_ok (
  $ENV{'FLODAY_LOGGING_IDENTIFIER'},
  'eq',
  'ident_test',
  'Test FLODAY_LOGGING_IDENTIFIER modification.'
);

my $date = time();
$logger->info($date);

open(my $syslog, '<', '/var/log/syslog');
my @lines = grep {/ident_test.*$date/} <$syslog>;
ok (@lines == 1, 'Syslog write with the correct identifier.');

done_testing;
