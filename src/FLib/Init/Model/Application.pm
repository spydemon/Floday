package FLib::Init::Model::Application;

#{{{POD
=pod

=head1 NAME

FLib::Init::Model::Application - Manage a single Floday application.

=head1 SYNOPSYS

 use FLib::Init::Model::Application;
 my $application = FLib::Init::Model::Application->new(<invocationAttributes>, <containerDefinition>);

=head1 DESCRIPTION

Manage an application.
Be careful at the fact that the I<path> attribute in it definition should be absolute inside the container it will be executed.
The user that run Floday needs also the execute right on it.

=head2 Methods

=head3 new($invocationAttributes, $containerDefinition)

Initialize an application object.

=over 15

=item $invocationAttributes

A hash with the attribute name as key, and his value as value.
Those attributes will overload the ones present in container definition.
Usually, this hash represent container attributes present in the runfile.

=item $containerDefinition

Hash of elements representing the container definition in his config.xml file.

=item return

An Flib::Init::Model::Application object.

=back

=head3 execute()

Will execute the current application inside the container.
The application need to have the execution right, and all it parameters will be sent trough the command line with the
I<--parameterKey value> format.

=over 15

=item retrun

Nothing.

=back

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Wiki and bug tracker of the entire Floday project can be found at: https://dev.spyzone.fr/floday.

=cut
#}}}

use v5.20;

sub new {
	my ($class, $initializationParameters, $definition) = @_;
	my %this;
	bless(\%this, $class);
	_setContainerType(\%this, $definition);
	_setName(\%this, $initializationParameters);
	_setType(\%this, $initializationParameters);
	_setPath(\%this, $definition);
	_setParameters(\%this, $initializationParameters, $definition);
	return \%this;
}

sub execute {
	my ($this) = @_;
	my $argsString = join ' ', map{'--'.$_. ' "'.$this->{parameters}{$_}.'"'} keys %{$this->{parameters}};
	qx($this->{path} $argsString);
}

sub _getContainersPath {
	my $path = $ENV{FLODAY_CONTAINERS};
	$path eq '' and die ("The environment variable FLODAY_CONTAINERS is not set");
	$path !~ /\/$/ and die ("FLODAY_CONTAINERS have to end with a slash");
	-d $path or die ("$path is not an existing directory");
	return $path;
}

sub _setContainerType {
	my ($this, $definition) = @_;
	die("Application without container type was definied") if !defined($definition->{containerType});
	my $containerDefinitionPath = _getContainersPath . $definition->{containerType}. '/config.xml';
	die("Definition of $definition->{containerType} type was not found") if !-e $containerDefinitionPath;
	$this->{containerType} = $definition->{containerType};
}

sub _setName {
	my ($this, $parameters) = @_;
	die("Application name was not found") if !defined($parameters->{name});
	$this->{name} = $parameters->{name};
}

sub _setParameters {
	my ($this, $parameters, $definition) = @_;
	my %parametersToKeep;
	for (keys %{$definition->{parameters}}) {
		$parametersToKeep{$_} = $parameters->{parameters}{$_};
		$parametersToKeep{$_} = $definition->{parameters}{$_}{default} if !defined($parametersToKeep{$_});
		/^[a-zA-Z0-9]*$/ or die "Invalid character in parameter name: $_";
		$parametersToKeep{$_} =~ /"/ and die "Invalid character in parameter $_ value";
		!defined($parametersToKeep{$_}) && $definition->{parameters}{$_}{mandatory} eq 'true'
		  and die("Mandatory \"$_\" parameter is not provided for $this->{name} application");
	}
	$this->{parameters} = {%parametersToKeep};
}

sub _setPath {
	my ($this, $definition) = @_;
	die ("Path of $this->{name} application not set") if !defined($definition->{path});
	my $path = _getContainersPath.$this->{containerType}.'/'.$definition->{path};
	die ("Application $definition->{path} was not found for $this->{name} container") if !-e $path;
	die ("$path can not be executed") if !-x $path;
	$this->{path} = $path;
}

sub _setType {
	my ($this, $parameters) = @_;
	die ("Type of container $this->{name} was not set") if !defined $parameters->{type};
	$this->{type} = $parameters->{type};
}

1
