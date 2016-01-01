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
	my %runList;
	foreach my $a ($_[0]->findnodes('@*')) {
		$runList{$a->getName} = $a->getValue;
	}
	foreach my $b ($_[0]->findnodes('*')) {
		$runList{$b->getName} = {generateRunList($b)};
	}
	return %runList;
}

sub initHost{
	my $hostNode = $_[0]->findnodes("/run/host[\@name=\"$_[1]\"]");
	die("Host $_[1] should have a single node in the runfile") if $hostNode->size() != 1;
	return $hostNode->get_node(1);
}

sub parseRunfile{
	my $file = XML::LibXML->new->parse_file($_[0]);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}
