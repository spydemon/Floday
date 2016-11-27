package Floday::Helper::Config;

use v5.20;

use Config::Tiny;
use Moo;

has flodayConfigFile => (
  builder => sub {
    my $cfg = Config::Tiny->read('/etc/floday/floday.cfg');
    die ("Unable to load Floday configuration file ($Config::Tiny::errstr)") unless defined $cfg;
    return $cfg;
  },
  is => 'ro',
  reader => '_getFlodayConfigFile'
);

sub getFlodayConfig {
	my ($this, $section, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_getFlodayConfigFile()->{$section}{$key};
	die ("Undefined '$key' key in Floday configuration '$section' section") unless defined $value;
	return $value;
}

1