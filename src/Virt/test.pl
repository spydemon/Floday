#!/usr/bin/env perl
use v5.20;
use strict;
use warnings;

use Virt::LXC qw(ALLOW_UNDEF);

my $c = Virt::LXC->new(
  utsname => 'integration-web'
);
my ($uid_start, $uid_map) = $c->get_config('lxc.id_map', qr/^u 0 (\d+) (\d+)$/, ALLOW_UNDEF);
say "$uid_start && $uid_map";

__END__

my $c = Virt::LXC->new(
  utsname => 'web',
  template => 'download -- -d debian -r wheezy -a amd64'
);
$c->stop if $c->is_running;
$c->destroy if $c->is_existing;
$c->deploy;
$c->set_config('lxc.network.ipv4', '10.0.3.2');
$c->start;
my @cmd = (
  'route add default gw 10.0.0.3 eth0',
  'echo "nameserver 8.8.8.8" > /etc/resolv.conf',
  'apt-get update -y',
  'apt-get install -y lighttpd'
);
map {
  my ($res, $stdout, $stderr) = $c->exec($_);
  die $stderr if $stderr ne '';
} @cmd;
$c->put('lighttpd.conf', '/etc/lighttpd/lighttpd.conf');
$c->put('www', '/var/www');
#get_config
#get_template

