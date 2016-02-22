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
	return \%this;
}

1
