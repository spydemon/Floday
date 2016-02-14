package FLib::Init::Model::RunList;

use v5.20;

use FLib::Init::Helper::RunFileParser;
use FLib::Init::Model::Container;

sub new {
	my ($class, $runFileName, $hostName) = @_;
	my %this;
	$this{currentContainerPath} = $hostName;
	$this{containers} = [];
	bless(\%this, $class);
	my $runFile = FLib::Init::Helper::RunFileParser->new($runFileName, $hostName);
	_generateRunList(\%this, $runFile, $hostName);
	return \%this;
}

sub getCurrentContainerPath {
	my ($this) = @_;
	return $this->{currentContainerPath};
}

sub _generateRunList {
	my ($this, $runFile, $hostName) = @_;
	my $currentContainer = $runFile->getContainer($this->getCurrentContainerPath);
	push @$this{containers}, FLib::Init::Model::Container->new($currentContainer, $hostName);
}

1
