#!/usr/bin/env perl

use v5.20;

use lib '/opt/floday/src/';
use File::Temp;
use Virt::LXC;
use Template::Alloy;
use YAML::Tiny;
use Getopt::Long;
use Data::Dumper;

$Data::Dumper::Indent = 1;
my $runlist = YAML::Tiny->read('/usr/lib/floday/runlist.yml');
my $c;
GetOptions(
	"container=s" => \$c
);

my ($h, $a) = $c =~ /(.*?)-(.*)/;
my $definition = $runlist->[1]->{$h};

my $test = {
	'containers' => [
		{
			'hostname' => 'spyzone.fr',
			'ipv4' => '10.0.3.6',
			'port' => '9000'
		},{
			'hostname' => 'ctr-team.com',
			'ipv4' => '10.0.3.7',
			'port' => '9000'
		}
	]
};

for (split /-/, $a) {
	$definition = $definition->{applications}->{$_};
}

my $configuration = File::Temp->new();
my $t = Template::Alloy->new(
	ABSOLUTE => 1,
);
$t->process('/opt/floday/containers/riuk/children/web/setup/lighttpd/lighttpd.conf.tt', $test, $configuration) or die $t->error;
my $container = Virt::LXC->new($definition->{parameters}{name});
$container->put($configuration, '/etc/lighttpd/lighttpd.conf');


