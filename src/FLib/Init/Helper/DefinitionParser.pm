package FLib::Init::Helper::DefinitionParser;

use v5.20;
use XML::LibXML;

my $CONTAINERS_PATH = '/opt/floday/src/containers/';

sub new {
	my ($class, $containerType) = @_;
	my %this;
	bless(\%this, $class);
	my $containerDefinitionPath = $CONTAINERS_PATH.$containerType.'/config.xml';
	my $containerXmlTree = _initializeXml($containerDefinitionPath);
	my %parent = _fetchAttributes('depends/*', $containerXmlTree);
	$this{'parameters'} = {_fetchAttributes('parameters/*', $containerXmlTree)};
	$this{'setup'} = {_fetchAttributes('setup/*', $containerXmlTree)};
	$this{'startup'} = {_fetchAttributes('startup/*', $containerXmlTree)};
	$this{'shutdown'} = {_fetchAttributes('shutdown/*', $containerXmlTree)};
	$this{'uninstall'} = {_fetchAttributes('uninstall/*', $containerXmlTree)};
	$this{'applications'} = {_fetchApplications($containerXmlTree)};
	foreach (keys %parent) {
		my $dependencies = FLib::Init::Helper::DefinitionParser->new($_);
		_mergeAttributesWithDependencies(\%this, $dependencies);
	}
	return \%this;
}

sub _fetchApplications {
	my ($attributeTree) = @_;
	my %applications;
	foreach my $n1 ($attributeTree->findnodes('/config/applications/*')->get_nodelist) {
		my %application;
		(my $path) = $n1->getChildrenByTagName('path');
		$application{path} = $path->textContent;
		foreach my $n2 ($n1->findnodes('parameters')) {
			my %parameters;
			foreach my $n3 ($n2->findnodes('*')) {
				my %attributes;
				foreach my $n4 ($n3->findnodes('*')) {
					$attributes{$n4->getName} = $n4->textContent;
				}
				$parameters{$n3->getName} = {%attributes};
			}
			$application{parameters} = {%parameters};
		}
		$applications{$n1->getName} = {%application};
	}
	return %applications;
}

sub _fetchAttributes {
	my ($n1, $attributeTree) = @_;
	my $n2 = $attributeTree->findnodes("/config/$n1");
	my %attributes;
	foreach my $n3 ($n2->get_nodelist) {
		my %currentAttributeNodeValues;
		my @n4 = $n3->findnodes('*')->get_nodelist;
		foreach (@n4) {
			$currentAttributeNodeValues{$_->getName} = $_->textContent;
		}
		$attributes{$n3->getName} = {%currentAttributeNodeValues};
	}
	return %attributes;
}

sub _initializeXml {
	my ($xmlPath) = @_;
	my $file = XML::LibXML->new->parse_file($xmlPath);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}

sub _mergeAttributesWithDependencies{
	my ($hashA, $hashB) = @_;
	foreach (keys %$hashB) {
		if (exists $hashA->{$_}) {
			_mergeAttributesWithDependencies($hashA->{$_}, $hashB->{$_}) if ref $hashA->{$_} eq 'HASH';
		} else {
			$hashA->{$_} = $hashB->{$_};
		}
	}
}

1
