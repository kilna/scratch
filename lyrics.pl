#!/usr/bin/perl -w

use warnings;
use strict;
use WWW::Lyrics;

my $l = WWW::Lyrics->new("Pure energy");

print "Count ".$l->count()."\n";

while (my $page = $l->fetch())
{
	next unless $page->code() == 200;
	print $page->lyrics()."\n";
}
