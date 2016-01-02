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
my %runList = generateRunList($hostData);

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

sub initHost{
	(my $tree, my $host) = @_;
	my $hostNode = $tree->findnodes("/run/host[\@name=\"$host\"]");
	die("Host $host should have a single node in the runfile") if $hostNode->size() != 1;
	return $hostNode->get_node(1);
}

sub parseRunfile{
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}
