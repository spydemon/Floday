package Floday::Helper::Host;

use v5.20;

use Moo;

has attributesFromRunlist => (
  is => 'ro',
  isa => sub {
     my $hostName = $_[0]->{parameters}{name};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^[a-zA-Z]+$/;
  }
);

1