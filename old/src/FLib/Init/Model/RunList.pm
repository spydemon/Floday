package FLib::Init::Model::RunList;

#{{{POD
=pod

=head1 NAME

FLib::Init::Model::RunList - Manage a Floday runlist.

=head1 SYNOPSYS

 use FLib::Init::Model::RunList;
 my $runList = FLib::Init::Model::RunList->new(<runfileName>, <hostName>);
 my $container = $runList->getContainer('spyzone-php-blog');
 $runList->boot();

=head1 DESCRIPTION

This module manage a Floday runlist.

=head2 Methods

=head3 new($runfileName, $hostName)

Initialize a RunList object.

=over 15

=item $runfileName

Path to the runfile to use.

=item $hostName

The hostName is used for knowing which part of the runfile has to be parsed and also for initialize the root of container paths.

=item return

A FLib::Init::Model::RunList object.

=back

=head3 boot()

Boot the curent container.

=over 15

=item return

Nothing.

=back

=head3 getContainer($containerPath)

Return the container corresponding to the given path, or die if the container was not found.

=over 15

=item $containerPath

Container path to get, as string.

=item return

A FLib::Init::Model::Container object.

=back

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Wiki and bug tracker of the entire Floday project can be found at: https://dev.spyzone.fr/floday.

=cut
#}}}

use v5.20;
use FLib::Init::Helper::RunFileParser;
use FLib::Init::Model::Container;

sub new {
	my ($class, $runFileName, $hostName) = @_;
	my %this;
	$this{containers} = {};
	$this{currentContainerPath} = $hostName;
	bless(\%this, $class);
	my $runFile = FLib::Init::Helper::RunFileParser->new($runFileName, $hostName);
	_generateRunList(\%this, $runFile, $hostName);
	return \%this;
}

sub boot {
	my ($this) = @_;
	$this->{containers}->{$this->{currentContainerPath}}->boot();
}

sub getContainer {
	my ($this, $name) = @_;
	$this->{containers}{$name}
	  or die ("Container $name is not exisiting.");
}

sub _generateRunList {
	my ($this, $runFile, $containerPath) = @_;
	my $currentContainer = $runFile->getContainer($containerPath);
	my $hostContainer = FLib::Init::Model::Container->new($currentContainer, $containerPath);
	$this->{containers}{$containerPath} = $hostContainer;
	foreach ($runFile->getContainerChildPaths($containerPath)) {
		$this->_generateRunList($runFile, $_);
	}
}

1
