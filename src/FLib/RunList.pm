package FLib::RunList;

#{{{PDO
=pod

=head1 NAME

FLib::RunList - Parse Floday XML runfile.

=head1 SYNOPSYS

 use FLib::RunList;
 my $runList = FLib::LibXML->new(<runfile>);
 $runList->getNextContainer();
 my %children = $runList->getCurrentContainerChildren();
 my %configuration = $runList->getCurrenContainerConfiguration();
 my $name = $runList->getCurrentContainerName();
 my $type = $runList->getCurrentContainerType();

=head1 DESCRIPTION

The purpose of this module is to manage everything concerning Floday runfile.
An object of this module is a representation of all containers in the higher level of given runfile.

Runfile can be I<multihosts> or I<monohost>.
Usually user wrote always multi-hosts ones but Floday automatically generate mono-host ones internally.
The principal difference between both is that multi-hosts ones contain a single or several I<host> node that manage the functionality to control several physical hosts with a single runfile.

This object act with states.
The B<getNextContainer> function can be used for navigating between each containers.
This function returns I<1> if next container exists and I<0> otherwise for being easily used in loops.
Every other functions are always acting on the given current container.

=head2 Methods

=head3 new($xmlFile, $host)

Create a new XML::LibXML object for managing a given runfile.

=over 15

=item $xmlFile

Path of the file to use as runfile.
It can be on the XML or DBM format.

=item $host

Optional host name to use.
Should be null for mono-host runfile.

=item return

Hash containing all configuration, children containers and current container.

=back

=head3 getCurrrentContainerChildren()

Get a hash with all children of the given current container.
These nodes are always directly present in the current one, and with a attribute I<container=true> (this will change).

=over 15

=item retrun

Hash with all children of the current container.

=back

=head3 getCurrentContainerConfiguration()

Get a hash will all configurations of the given current container.
Configuration container are all parameters existing in the node corresponding to the container.

=over 15

=item return

Hash with the configuration name as key, and the value as configuration value.

=back

=head3 getCurrentContainerName()

Return the name of the current container.

=over 15

=item return

String with the container name.

=back

=head3 getCurrentContainerType()

Retrun the type of the current container.

=over 15

=item return

String with the container type.

=back

=head3 getNextContainer()

Increment the internal cursor defining which child to use as the "current" one.

=over 15

=item retrun

I<1> if the next container exists in the runfile, I<0> otherwise.

=back

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Wiki and bug tracker of the entire Floday project can be found at : https://dev.spyzone.fr/floday.

=cut
#}}}

use XML::LibXML;
use v5.20;

sub new {
	my ($class, $xmlFile, $host) = @_;
	my $tree = _initializeXml($xmlFile);
	my $xmlNodes;
	my %this;
	bless(\%this, $class);
	if ($host ne '') {
		$xmlNodes= _initHost($tree, $host);
	} else {
		$xmlNodes= _initContainers($tree);
	}
	my %runList;

	foreach ($xmlNodes->get_nodelist) {
		%runList = (%runList, (_getNodeName($_) => {_generateRunList($_)}));
	};

	$this{containerChildren} = {_getChildren(\%runList)};
	$this{containerConfiguration} = {_getConfiguration(\%runList)};
	$this{currentContainer} = 0;

	return \%this;
}

sub getCurrentContainerChildren {
	my ($this) = @_;
	my @keysSorted = sort keys $this->{containerChildren};
	return _getChildren($this->{containerChildren}{$this->getCurrentContainerName()});
}

sub getCurrentContainerConfiguration {
	my ($this) = @_;
	my @keysSorted = sort keys $this->{containerChildren};
	return _getConfiguration($this->{containerChildren}{$this->getCurrentContainerName()});
}

sub getCurrentContainerName {
	my ($this) = @_;
	my @keysSorted = sort keys $this->{containerChildren};
	return $keysSorted[$this->{currentContainer}];
}

sub getCurrentContainerType {
	my ($this) = @_;
	my $currentContainer = $this->{containerChildren}{$this->getCurrentContainerName()};
	return $currentContainer->{type} or die ("Container $currentContainer->{name} has no type.");
}

sub getNextContainer {
	my ($this) = @_;
	$this->{currentContainer} += 1;
	return 1 if keys $this->{containerChildren} > $this->{currentContainer};
	return 0;
}

sub _getChildren {
	(my $runList) = @_;
	my %children;
	foreach (keys %$runList) {
		$children{$_} = $runList->{$_} if ref $runList->{$_} eq 'HASH';
	}
	return %children;
}

sub _getConfiguration {
	(my $runList) = @_;
	my %configuration;
	foreach (keys %$runList) {
		$configuration{$_} = $runList->{$_} if ref $runList->{$_} ne 'HASH';
	}
	return %configuration;
}

sub _generateRunList {
	(my $xmlNodes) = @_;
	my %runList;
	foreach ($xmlNodes->findnodes('@*')) {
		$runList{$_->getName} = $_->getValue;
	}
	foreach ($xmlNodes->findnodes('*')) {
		$runList{_getNodeName($_)} = {_generateRunList($_)};
	}
	$runList{action} = $xmlNodes->getName;
	return %runList;
}

sub _getNodeName {
	(my $node) = @_;
	return $node->getAttributeNode('name')->getValue;
}

sub _initContainers {
	(my $tree) = @_;
	my $containers = $tree->findnodes('/run/container');
	die("No containers was found in runfile") if $containers->size() < 1;
	return $containers;
}

sub _initHost {
	(my $tree, my $host) = @_;
	my $hostNode = $tree->findnodes("/run/host[\@name=\"$host\"]/*");
	die("Host $host doesn't exists in the runfile") if $hostNode->size() < 1;
	return $hostNode;
}

sub _initializeXml {
	(my $plainFile) = @_;
	my $file = XML::LibXML->new->parse_file($plainFile);
	my $nodes = XML::LibXML::XPathContext->new($file);
	return $nodes;
}

1
