package FLib::Init::Model::RunList;

use v5.20;

use FLib::Init::Helper::RunFileParser;
use FLib::Init::Model::Container;

sub new {
	my ($class, $runFileName, $currentContainerPath) = @_;
	my %this;
	$this{containers} = {};
	$this{currentContainerPath} = $currentContainerPath;
	bless(\%this, $class);
	my $runFile = FLib::Init::Helper::RunFileParser->new($runFileName, $currentContainerPath);
	_generateRunList(\%this, $runFile, $currentContainerPath);
	return \%this;
}

sub _generateRunList {
	my ($this, $runFile, $containerPath) = @_;
	my $currentContainer = $runFile->getContainer($containerPath);
	my $hostContainer = FLib::Init::Model::Container->new($currentContainer, $containerPath);
	$this->{containers}{$containerPath} = $hostContainer;
	foreach ($runFile->getContainerChildrenPath($containerPath)) {
		$this->_generateRunList($runFile, $_);
	}
}

1
