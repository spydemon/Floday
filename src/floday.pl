#!/usr/bin/perl

use strict;
use warnings;
use v5.20;

my $CONTAINERS_PATH = '/home/spydemon/depots/floday/src/containers/';

use Getopt::Long;
use XML::LibXML;

my $runFile;
my $host = '';
GetOptions(
  "run=s" => \$runFile,
  "host=s" => \$host
);

my $tree = initializeXml($runFile);
my $xmlNodes;
if ($host ne '') {
	$xmlNodes= initHost($tree, $host);
} else {
	$xmlNodes= initContainers($tree);
}
my %runList;
foreach ($xmlNodes->get_nodelist) {
	%runList = (%runList, ($_->getName => {generateRunList($_)}));
};
my %containerChildren = getChildren(%runList);

foreach (values %containerChildren) {
	my %containerConfiguration = getConfiguration(%{$_});
	my %containerChildren = getChildren(%{$_});
	fire(\%containerConfiguration, \%containerChildren);
}

sub getContainerDefinition{
	my ($containerType) = @_;
	my $containerConfigurationFile = $CONTAINERS_PATH.$containerType.'/config.xml';
	my $containerConfigurationTree = initializeXml($containerConfigurationFile);
	my %parent = fetchContainerConfiguration('depends', $containerConfigurationTree);
	my %setupScripts = fetchContainerConfiguration('setup/script', $containerConfigurationTree, 'priority', 'path', 'remove');
	my %configuration = fetchContainerConfiguration('configuration/*', $containerConfigurationTree, '*');
	my %startupScripts = fetchContainerConfiguration('startup/script', $containerConfigurationTree, 'priority', 'path', 'remove');
	my %shutdownScripts = fetchContainerConfiguration('shutdown/script', $containerConfigurationTree, 'priority', 'path', 'remove');
	my %uninstallScripts = fetchContainerConfiguration('uninstall/script', $containerConfigurationTree, 'priority', 'path', 'remove');
}

sub fetchContainerConfiguration{
	my ($n1, $configurationTree, @params) = @_;
	my $n2 = $configurationTree->findnodes("/config/$n1");
	my %configuration;
	foreach my $n3 ($n2->get_nodelist) {
		my %currentConfigurationNodeValues;
		foreach (@params) {
			my @n4 = $n3->findnodes($_)->get_nodelist;
			foreach (@n4) {$currentConfigurationNodeValues{$_->getName} = $_->textContent;}
		}
		$configuration{$n3->getAttribute('identifier')} = {%currentConfigurationNodeValues};
	}
	return %configuration;
}

sub fire{
	my ($runfileConfiguration, $childrens) = @_;
	my %containerDefinition = getContainerDefinition($runfileConfiguration->{type});
	say "We are firering $runfileConfiguration->{name} container !";
}

sub generateRunList{
	(my $xmlNodes) = @_;
	my %runList;
	foreach ($xmlNodes->findnodes('@*')) {
		$runList{$_->getName} = $_->getValue;
	}
	foreach ($xmlNodes->findnodes('*')) {
		$runList{$_->getName} = {generateRunList($_)};
	}
	$runList{name} = $xmlNodes->getName;
	return %runList;
}

sub getChildren{
	(my %runList) = @_;
	my %children;
	foreach (keys %runList) {
		$children{$_} = $runList{$_} if ref $runList{$_} eq 'HASH';
	}
	return %children;
}

sub getConfiguration{
	(my %runList) = @_;
	my %configuration;
	foreach (keys %runList) {
		$configuration{$_} = $runList{$_} if ref $runList{$_} ne 'HASH';
	}
	return %configuration;
}

sub initHost{
	(my $tree, my $host) = @_;
	my $hostNode = $tree->findnodes("/run/host[\@name=\"$host\"]/*");
	die("Host $host doesn't exists in the runfile") if $hostNode->size() < 1;
	return $hostNode;
}

sub initContainers{
	(my $tree) = @_;
	my $containers = $tree->findnodes('/run/*[@container="true"]');
	die("No containers was found in runfile") if $containers->size() < 1;
	return $containers;
}

sub initializeXml{
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}
