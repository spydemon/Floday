package FLib::Init::Helper::RunFileParser;

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

1
