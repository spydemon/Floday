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

has flodayConfigFile => (
  builder => sub {
    my $cfg = Config::Tiny->read('/etc/floday/floday.cfg');
    die ("Unable to load Floday configuration file ($Config::Tiny::errstr)") unless defined $cfg;
	return $cfg;
  },
  is => 'ro',
  reader => '_getFlodayConfigFile'
);

sub _getFlodayConfig {
	my ($this, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_getFlodayConfigFile()->{containers}{$key};
	die ("Undefined '$key' key in Floday configuration container section") unless defined $value;
	return $value;
}

1