package FLib::ConfigurationManager;

#{{{POD
=pod

=head1 NAME

FLib::ConfigurationManager - Fetch Floday container configuration.

=head1 SYNOPSYS

 use Flib::ConfigurationManager;
 $config = Flib::ConfigurationManager->new(<container_type>);
 $config->mergeConfiguration(<configuration_to_merge>);

=head1 DESCRIPTION

This module is in charge of all actions relevant to container configuration fetching: parsing configuration files and process to all inheritance merges.
The inheritance can be done by container relations ("web" container extends "core") or by runfile overrides.

=head2 Methods

=head3 new($containerType)

Create a new FLib::ConfigurationManager for managing a container.

=over 15

=item $containerType

Indicate which kind of container we should invocate.
This is technically done by parsing the I<< container/<$containerType>/config.xml >> file in the Floday root folder.

=item return

A FLib::ConfigurationManager object.

=back

=head3 mergeConfiguration($extConf)

Merge the container configuration with an external one.
This mean that the hash representing the current container configuration will be fused with the hash I<extConf>.
In the case of "conflict" (an attribute is declared in both hash) the one coming from external hash well be kept.
This function is usually used for applying runfile attributes configuration to the container.

=over 15

=item $extConf

A pointer on a hash representing the external configuration to merge.
The key of a hash item is an attribute name, and his value, the attribute value.

=item return

Nothing. The merge result will be stored inside the FLib::ConfigurationManager object.

=back

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Wiki and bug tracker of the entire Floday project can be found at : https://dev.spyzone.fr/floday.

=cut
#}}}

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
