#!/bin/perl

use strict;
use warnings;
use v5.20;

use feature qw(signatures);
no warnings qw(experimental::signatures);

use Getopt::Long;

my $action = '';
GetOptions(
	"a=s" => \$action
);

my $APPLICATION_PATH = '..';
my $TEST_PATH = '../t';

my $CURRENT_PATH = `pwd`;
chomp $CURRENT_PATH;

my $command = "perl floday.pl --run ../samples/run.xml --host spyzone";
if ($action eq 'inspect') {
	$command = "perl /opt/keepalive.pl";
} elsif ($action eq 'test') {
	$command = "perl ../t/harness.pl";
}

sub run($msg, $cmd){
	say "\033[32m$msg\033[0m";
	open my $exec, '|-', $cmd or die $!;
}

`whereis docker` =~ /:$/
	and die ("Docker is need for runing dev instance of Floday.");

`docker images` !~ /dev_floday/
	and run
	  "Cretion of the Docker image.",
	  "docker build -t dev_floday floday"
;

run
  "Launching Floday.",
  "docker run "
    ."--cap-add SYS_ADMIN "
    ."--cap-add NET_ADMIN "
    ."--volume $CURRENT_PATH/$APPLICATION_PATH:/opt/floday "
    ."--env FLODAY_CONTAINERS=/opt/floday/src/containers/ "
    ."--env FLODAY_T_SRC=/opt/floday/src/ "
    ."--env FLODAY_T=/opt/floday/t/ "
    ."--name floday dev_floday "
    .$command
;

$action ne "inspect"
	and run
	  "Destroying Floday container.",
	  "docker rm floday"
;
