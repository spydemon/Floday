#!/usr/bin/perl

use strict;
use warnings;
use v5.20;

use Getopt::Long;
use XML::LibXML;

my $runFile;
my $host = '';
GetOptions(
  "run=s" => \$runFile,
  "host=s" => \$host
);

my $tree = parseRunfile($runFile);
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

sub fire{
	my ($runfileConfiguration, $childrens) = @_;
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

sub parseRunfile{
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}
