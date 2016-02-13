#!/usr/bin/perl

#{{{POD
=pod

=head1 NAME

Floday - LXC launcher

=head1 SYNOPSIS

 floday --run <runfile> [--host <hostname>]

=head1 DESCRIPTION

The purpose of Floday is to easily configure LXC containers that should be deployed in one ore several hosts.
More info at https://dev.spyzone.fr/floday/wiki.

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Git repository : ssh://git@spyzone.fr:122/floday

Bug tracker : https://dev.spyzone.fr/floday
=cut
#}}}

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
my $applications = $containersToLaunch->getApplications();
foreach (keys %$applications) {
	fireApplication($applications->{$_});
}

do {
	fire($containersToLaunch);
} while ($containersToLaunch->getNextContainer());

sub fire{
	my ($containersFromRunList) = @_;
	my $container = FLib::ConfigurationManager->new($containersFromRunList->getCurrentContainerType());
	my %configuration = $containersFromRunList->getCurrentContainerConfiguration();
	$container->mergeConfiguration(\%configuration);
	my %containerConfiguration = $container->getCurrentContainerExportedConfiguration();
	my $containerName = $containersFromRunList->getCurrentContainerName();
	say "We are firering $containerName container !";
}

sub fireApplication {
	(my $application) = @_;
	say "We are fiering $application->{name} application !";
	my $test = 1;
}
