#!/usr/bin/perl

use strict;
use warnings;
use v5.20;

use Getopt::Long;
use XML::LibXML;

my $runFile;
my $host;
GetOptions(
  "run=s" => \$runFile,
  "host=s" => \$host
);

my $tree = parseRunfile($runFile);
my $hostData = initHost($tree, $host);
my %runList;
foreach ($hostData->get_nodelist) {
	%runList = (%runList, ($_->getName => {generateRunList($_)}));
};
my %containerConfiguration = getConfiguration(%runList);
my %containerChildren = getChildren(%runList);

sub generateRunList{
	(my $hostData) = @_;
	my %runList;
	foreach ($hostData->findnodes('@*')) {
		$runList{$_->getName} = $_->getValue;
	}
	foreach ($hostData->findnodes('*')) {
		$runList{$_->getName} = {generateRunList($_)};
	}
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

sub parseRunfile{
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}
