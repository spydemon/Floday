#!/usr/bin/env perl

use v5.20;
use Virt::LXC;

my $web = Virt::LXC->new('web');
if (!$web->isExisting) {
	$web->setTemplate('alpine');
	$web->deploy;
	$web->put('Virt.LXC.d/web/interfaces', '/etc/network/interfaces');
	$web->start;
	$web->exec('rc-update add networking');
	$web->stop;
	$web->start;
	my @cmd = ('apk update', 'apk upgrade', 'apk add lighttpd', 'apk add vim', 'rc-update add lighttpd');
	for (@cmd) {
		my ($status, $stdout, $stderr) = $web->exec($_);
		say "-------\nOUT : $stdout\nERR : $stderr\n-------\n";
	}
	$web->put('Virt.LXC.d/web/lighttpd.conf', '/etc/lighttpd/lighttpd.conf');
	$web->put('Virt.LXC.d/web/hello.html', '/var/www/localhost/htdocs');
	$web->stop;
	`iptables -t nat -A PREROUTING -d 192.168.1.151 -p tcp --dport 80 -j DNAT --to-destination 10.0.3.5`
}

my $blog = Virt::LXC->new('web-blog');
if (!$blog->isExisting) {
	$blog->setTemplate('alpine');
	$blog->deploy;
	$blog->put('Virt.LXC.d/web-blog/interfaces', '/etc/network/interfaces');
	$blog->start;
	$blog->exec('rc-update add networking');
	$blog->stop;
	$blog->start;
	my @cmd = ('apk update', 'apk upgrade', 'apk add php-fpm', 'rc-update add php-fpm');
}
$web->start;
$blog->start;
