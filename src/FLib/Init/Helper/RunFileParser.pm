package FLib::Init::Helper::RunFileParser;

#{{{POD
=pod

=head1 NAME

FLib::Init::Helper::RunFileParser - Parse Floday XML runfile.

=head1 SYNOPSYS

 use FLib::Init::Helper::RunFileParser;
 my $runFile = FLib::Init::Helper::RunFileParser->new(<runfile>, <containerPath>);
 my @childPaths = $runFile->getContainerChildPaths(<containerPath);
 my $container = $runList->getContainer(<containerPath>);

=head1 DESCRIPTION

The purpose of this module is to manage everything concerning Floday runfile.
An object of this module is a representation of all content of the given runfile.

=head2 Methods

=head3 new($runFile, $hostName)

Initialize a RunFileParser object.

=over 15

=item $runFile

Path of the file to use as runfile.
This file has to be in XML format and to respect Floday runfile format.

=item $hostName

The hostName is used for knowing which part of the runfile has to be parsed and also for initialize the root of container paths.

=item return

An Flib::Init::Helper::RunFileParser object.

=back

=head3 getContainerChildPaths($containerPath)

Get the container path of all first level containers presents in the $containerPath container.

=over 15

=item $containerPath

String that represents the container into which we want to find container children.

=item return

A array of string containing all container paths.

=back

=head3 getContainer($containerPath)

Get all parameters concerning the container represented by the given container path.

=over 15

=item $containerPath

String representing the container path to fetch.

=item return

A hash containing all parameters of the given container.

=back

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Wiki and bug tracker of the entire Floday project can be found at: https://dev.spyzone.fr/floday.


=cut
#}}}

use v5.20;
use XML::LibXML;

sub new {
	my ($class, $xmlFileName, $hostName) = @_;
	my %this;
	bless(\%this, $class);
	my $nodes = _initializeNodes($xmlFileName, $hostName);
	my %nodesAsHash = _fetchNodeContent($nodes->get_nodelist);
	$this{runFile} = {$hostName => {%nodesAsHash}};
	return \%this;
}

sub getContainer {
	my ($this, $containerPathString) = @_;
	my @containerPathArray = split /-/, $containerPathString;
	my ($status, $container) = _getContainer(\@containerPathArray, $this->{runFile});
	die ("Container $containerPathString was not found in runfile") if $status eq 'ko';
	return $container;
}

sub getContainerChildPaths {
	my ($this, $rootPath) = @_;
	my @rootPath = $this->_splitPathToArray($rootPath);
	my ($status, $nodes) = _getContainer(\@rootPath, $this->{runFile});
	die ("Container $rootPath was not found in runfile") if $status eq 'ko';
	my %childrens = _getAllContainersIn($nodes);
	my @childPaths;
	foreach (keys %childrens) {
		push @childPaths, $rootPath . '-' . $_;
	}
	return @childPaths;
}

sub _fetchNodeContent {
	my ($nodes) = @_;
	my %hash;
	foreach ($nodes->findnodes('@*')->get_nodelist) {
		$hash{$_->getName} = $_->getValue;
	}
	foreach ($nodes->findnodes('*')->get_nodelist) {
		$hash{_getNodeName($_)} = {_fetchNodeContent($_)};
		$hash{_getNodeName($_)}{action} = $_->getName;
	}
	return %hash;
}

sub _getAllContainersIn {
	my ($nodes) = @_;
	my %containers;
	foreach (keys %$nodes) {
		if (ref $nodes->{$_} eq 'HASH' && $nodes->{$_}->{action} eq 'container') {
			$containers{$nodes->{$_}->{name}} = $nodes->{$_};
		}
	}
	return %containers;
}

sub _getContainer {
	my ($containerPath, $hash) = @_;
	return ('ko') if $hash == 0;
	my $step = shift @$containerPath;
	if (!defined $step) {
		if (ref $hash eq 'HASH') {
			return ('ok', $hash);
		} else {
			return ('ko');
		}
	}
	return _getContainer($containerPath, $hash->{$step});
}

sub _getNodeName {
	my ($node) = @_;
	my $name = $node->getAttributeNode('name');
	die("Node witout name attribute can't exist") if $name == undef;
	return $name->getValue;
}

sub _initializeNodes {
	my ($fileName, $hostName) = @_;
	my $file = XML::LibXML->new->parse_file($fileName);
	my $allNodes = XML::LibXML::XPathContext->new($file);
	my $onlyHostNodes = $allNodes->findnodes("/run/host[\@name=\"$hostName\"]");
	die ("Host $hostName doesn't exists in the runfile") if $onlyHostNodes->size < 1;
	return $onlyHostNodes;
}

sub _splitPathToArray {
	my ($this, $string) = @_;
	split /-/, $string;
}

1
