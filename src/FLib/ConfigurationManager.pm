package FLib::ConfigurationManager;

use XML::LibXML;

my $CONTAINERS_PATH = '/home/spydemon/depots/floday/src/containers/';

sub new {
	my ($class, $containerType) = @_;
	my $containerFile = $CONTAINERS_PATH.$containerType.'/config.xml';
	my $containerTree = _initializeXml($containerFile);
	my %this;
	bless(\%this, $class);
	my %parent = _fetchConfiguration('depends/*', $containerTree);
	$this{'configuration'} = {_fetchConfiguration('configuration/*', $containerTree)};
	$this{'setup'} = {_fetchConfiguration('setup/*', $containerTree)};
	$this{'startup'} = {_fetchConfiguration('startup/*', $containerTree)};
	$this{'shutdown'} = {_fetchConfiguration('shutdown/*', $containerTree)};
	$this{'uninstall'} = {_fetchConfiguration('uninstall/*', $containerTree)};
	foreach (keys %parent) {
		my $parentConfiguration = FLib::ConfigurationManager->new($_);
		_mergeConfiguration(\%this, $parentConfiguration);
	}
	return \%this;
}

sub getCurrentContainerExportedConfiguration {
	#TODO
}

sub mergeConfiguration {
	my ($this, $configuration) = @_;
	foreach (keys %$configuration) {
		$this->{configuration}{$_}{value} = $configuration->{$_};
	}
}

sub _fetchConfiguration{
	my ($n1, $configurationTree) = @_;
	my $n2 = $configurationTree->findnodes("/config/$n1");
	my %configuration;
	foreach my $n3 ($n2->get_nodelist) {
		my %currentConfigurationNodeValues;
		my @n4 = $n3->findnodes('*')->get_nodelist;
		foreach (@n4) {
			$currentConfigurationNodeValues{$_->getName} = $_->textContent;
		}
		$configuration{$n3->getName} = {%currentConfigurationNodeValues};
	}
	return %configuration;
}

sub _initializeXml {
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}

sub _mergeConfiguration{
	my ($hashA, $hashB) = @_;
	foreach (keys %$hashB) {
		if (exists $hashA->{$_}) {
			_mergeConfiguration($hashA->{$_}, $hashB->{$_}) if ref $hashA->{$_} eq 'HASH';
		} else {
			$hashA->{$_} = $hashB->{$_};
		}
	}
}

1
