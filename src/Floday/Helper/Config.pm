package Floday::Helper::Config;

use v5.20;

use Config::Tiny;
use Moo;

with 'MooX::Singleton';

has floday_config_file => (
  builder => sub {
    my $cfg = Config::Tiny->read('/etc/floday/floday.cfg');
    die ("Unable to load Floday configuration file ($Config::Tiny::errstr)") unless defined $cfg;
    return $cfg;
  },
  is => 'ro',
  reader => '_get_floday_config_file'
);

sub get_floday_config {
	my ($this, $section, $key) = @_;
	die ("Undefined key") unless defined $key;
	my $value = $this->_get_floday_config_file()->{$section}{$key};
	die ("Undefined '$key' key in Floday configuration '$section' section") unless defined $value;
	return $value;
}

1