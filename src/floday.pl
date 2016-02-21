#!/usr/bin/perl

#{{{POD
=pod

=head1 NAME

Floday - LXC launcher

=head1 SYNOPSIS

 floday --run <runfile> --host <hostname>

=head1 DESCRIPTION

The purpose of Floday is to easily configure LXC containers that should be deployed in one ore several hosts.
More info at https://dev.spyzone.fr/floday/wiki.

=head1 AUTHOR

Kevin Hagner

=head1 SEE ALSO

Git repository : ssh://git@spyzone.fr:122/floday

Bug tracker : https://dev.spyzone.fr/floday
=cut
#}}}

use strict;
use warnings;
use v5.20;

use Getopt::Long;
use FLib::Init::Model::RunList;

my $runFile ='';
my $host = '';
GetOptions(
  "run=s" => \$runFile,
  "host=s" => \$host
);

my $runList = FLib::Init::Model::RunList->new($runFile, $host);
$runList->boot();
