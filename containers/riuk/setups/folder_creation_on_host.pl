#!/usr/bin/env perl
use strict;
use warnings;
use v5.20;

use Floday::Setup;

$APP->generate_file(
  'riuk/setups/folder_creation_on_host.tt',
  undef,
  '/tmp/a/creation/test/on/host.txt'
);