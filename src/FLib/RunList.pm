package FLib::RunList;

use XML::LibXML;

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
		%runList = (%runList, ($_->getName => {_generateRunList($_)}));
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
		$runList{$_->getName} = {_generateRunList($_)};
	}
	$runList{name} = $xmlNodes->getName;
	return %runList;
}

sub _initContainers {
	(my $tree) = @_;
	my $containers = $tree->findnodes('/run/*[@container="true"]');
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
