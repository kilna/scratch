#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin.'/lib';

use Expansion::Config;

my $cfg = Expansion::Config->new( $ARGV[0] );
$cfg->play();
