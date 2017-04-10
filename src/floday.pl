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
use Log::Any::Adapter('+Floday::Helper::Logging');

my $host;
my $runfile;

GetOptions('host=s', \$host, 'runfile=s', \$runfile);
$host // die('Host to launch is missing');

$0 = "floday --host $host";
my $floday = Floday::Deploy->new(hostname => $host);
$floday->startDeployment;
