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
my $hostNode = initHost($tree, $host);

sub initHost{
	my $hostNode = $_[0]->findnodes("/run/host[\@name=\"$_[1]\"]");
	die("Host $_[1] should have a single node in the runfile") if $hostNode->size() != 1;
	return $hostNode;
}

sub parseRunfile{
	my $file = XML::LibXML->new->parse_file($_[0]);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}
