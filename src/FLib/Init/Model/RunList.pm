package FLib::Init::Model::RunList;

use v5.20;

use FLib::Init::Helper::RunFileParser;

sub new {
	my ($class, $runFile, $hostName) = @_;
	my $runFile = FLib::Init::Helper::RunFileParser->new($runFile, $hostName);
	my $test = 1;
}

1
