#!/usr/bin/perl

use strict;
use warnings;
use v5.20;

my $CONTAINERS_PATH = '/home/spydemon/depots/floday/src/containers/';

use Getopt::Long;
use XML::LibXML;
use FLib::RunList;

my $runFile;
my $host = '';
GetOptions(
  "run=s" => \$runFile,
  "host=s" => \$host
);

my $containersToLauch = FLib::RunList->new($runFile, $host);
do {
	fire($containersToLauch);
} while ($containersToLauch->getNextContainer());

sub getContainerDefinition{
	my ($containerType) = @_;
	my $containerConfigurationFile = $CONTAINERS_PATH.$containerType.'/config.xml';
	my $containerConfigurationTree = initializeXml($containerConfigurationFile);
	my %containerConfiguration;
	my %parent = fetchContainerConfiguration('depends/*', $containerConfigurationTree);
	$containerConfiguration{'configuration'} = {fetchContainerConfiguration('configuration/*', $containerConfigurationTree)};
	$containerConfiguration{'setup'} = {fetchContainerConfiguration('setup/*', $containerConfigurationTree)};
	$containerConfiguration{'startup'} = {fetchContainerConfiguration('startup/*', $containerConfigurationTree)};
	$containerConfiguration{'shutdown'} = {fetchContainerConfiguration('shutdown/*', $containerConfigurationTree)};
	$containerConfiguration{'uninstall'} = {fetchContainerConfiguration('uninstall/*', $containerConfigurationTree)};
	foreach (keys %parent) {
		my %parentContainerConfiguration = getContainerDefinition($_);
		mergeConfiguration(\%containerConfiguration, \%parentContainerConfiguration);
	}
	return %containerConfiguration;
}

sub fetchContainerConfiguration{
	my ($n1, $configurationTree) = @_;
	my $n2 = $configurationTree->findnodes("/config/$n1");
	my %configuration;
	foreach my $n3 ($n2->get_nodelist) {
		my %currentConfigurationNodeValues;
		my @n4 = $n3->findnodes('*')->get_nodelist;
		foreach (@n4) {
			$currentConfigurationNodeValues{$_->getName} = $_->textContent;
		}
		$configuration{$n3->getName} = {%currentConfigurationNodeValues};
	}
	return %configuration;
}

sub fire{
	my ($container) = @_;
	my %containerConfiguration = $container->getCurrentContainerConfiguration();
	my %containerChildren = $container->getCurrentContainerChildren();
	my $containerName = $container->getCurrentContainerName();
	my %containerDefinition = getContainerDefinition($containerName);
	say "We are firering $containerName container !";
}

sub initializeXml{
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}

sub mergeConfiguration{
	my ($hashA, $hashB) = @_;
	foreach (keys %$hashB) {
		if (exists $hashA->{$_}) {
			mergeConfiguration($hashA->{$_}, $hashB->{$_}) if ref $hashA->{$_} eq 'HASH';
		} else {
			$hashA->{$_} = $hashB->{$_};
		}
	}
}
