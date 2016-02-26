#!/usr/bin/perl

use v5.20;
use Getopt::Long;
use Data::Dumper;

my ($port, $name, $to);
GetOptions(
  "to=s" => \$to,
  "name=s" => \$name,
  "port=s" => \$port
);

say $port;
say $name;
say $to;
