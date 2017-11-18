#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

my $FILE = 'main';

`pdflatex $FILE.tex`;
`pdflatex $FILE.tex`;
`makeglossaries $FILE`;
`pdflatex $FILE.tex`;
