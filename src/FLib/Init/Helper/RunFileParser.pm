package FLib::Init::Helper::RunFileParser;

use v5.20;

use XML::LibXML;

sub new {
	my ($class, $xmlFileName, $hostName) = @_;
	my %this;
	bless(\%this, $class);
	my $nodes = _initializeNodes($xmlFileName, $hostName);
	my %nodesAsHash = _fetchNodeContent($nodes->get_nodelist);
	$this{runFile} = {%nodesAsHash};
	return \%this;
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
