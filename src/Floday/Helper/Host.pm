package Floday::Helper::Host;

use v5.20;

use Config::Tiny;
use Moo;

has attributesFromRunfile => (
  is => 'ro',
  isa => sub {
     no warnings 'uninitialized';
     my $hostName = $_[0]->{parameters}{name};
     my $hostType = $_[0]->{parameters}{type};
     die "Invalid name '$hostName' for host initialization" if $hostName !~ /^\w+$/;
     die "Invalid type '$hostType' for host initialization" if $hostType !~ /^\w+$/;
  },
  reader => 'getAttributesFromRunfile'
);

has flodayConfig => (
  builder => sub {
    my $cfg = Config::Tiny->read('/etc/floday/floday.cfg');
    die ("Unable to load Floday configuration file ($Config::Tiny::errstr)") unless defined $cfg;
	return $cfg;
  },
  is => 'ro',
  reader => 'getFlodayConfig'
);

1