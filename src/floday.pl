#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use FindBin;
use lib ($FindBin::Bin);
chdir $FindBin::Bin;

use Floday::Deploy;
use Floday::Helper::Config;
use Getopt::Long;
use Log::Any;
use Log::Any::Adapter('+Floday::Helper::Logging');

my $host;
my $loglevel;

GetOptions('host=s', \$host, 'loglevel=s', \$loglevel);
$host // die('Host to launch is missing');
$loglevel //= 'info';

Log::Any->get_logger()->{adapter}->reset();
Log::Any->get_logger()->{adapter}->loglevel_set($loglevel);

$0 = "floday --host $host";
my $floday = Floday::Deploy->new(hostname => $host);
$floday->start_deployment;
