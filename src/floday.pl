#!/usr/bin/perl

use strict;
use warnings;
use v5.20;

use Getopt::Long;
use FLib::RunList;
use FLib::ConfigurationManager;

my $runFile;
my $host = '';
GetOptions(
  "run=s" => \$runFile,
  "host=s" => \$host
);

my $containersToLaunch = FLib::RunList->new($runFile, $host);
do {
	fire($containersToLaunch);
} while ($containersToLaunch->getNextContainer());

sub fire{
	my ($containersFromRunList) = @_;
	my $container = FLib::ConfigurationManager->new($containersFromRunList->getCurrentContainerName());
	my %configuration = $containersFromRunList->getCurrentContainerConfiguration();
	$container->mergeConfiguration(\%configuration);
	my %containerConfiguration = $container->getCurrentContainerExportedConfiguration();
	my $containerName = $containersFromRunList->getCurrentContainerName();
	say "We are firering $containerName container !";
}
