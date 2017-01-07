#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Data::Dumper;
use Floday::Deploy;
use Floday::Helper::Config;
use Getopt::Long;
use Log::Any::Adapter('File', 'log.txt');

$Data::Dumper::Indent = 1;

my $host;
my $runfile;

GetOptions('host=s', \$host, 'runfile=s', \$runfile);
$host // die('Host to launch is missing');
$runfile //= Floday::Helper::Config->new()->getFlodayConfig('floday', 'runfile');
-r $runfile or die('Runfile is not readable');

my $floday = Floday::Deploy->new(runfile => $runfile, hostname => $host);
$floday->startDeployment;
