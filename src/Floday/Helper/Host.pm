package Floday::Helper::Host;

use v5.20;

use Moo;

has attributesFromRunfile => (
  is => 'ro',
  isa => sub {
     my $hostName = $_[0]->{parameters}{name};
     my $hostType = $_[0]->{parameters}{type};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^\w+$/;
     die "Invalid type '$hostType' for host initialization" if $hostType !~ /^\w+$/;
  },
  reader => 'getAttributesFromRunfile'
);

1