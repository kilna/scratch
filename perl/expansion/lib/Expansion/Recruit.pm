#!/usr/bin/perl -w

package Expansion::Crew;
my $CLASS = 'Expansion::Crew';

use strict;
use warnings;

use Scalar::Util qw(weaken);

my %defaults = (
);

sub new
{

	my $source = shift;
	my $class  = first { defined($_) && $_ }( ref($source), $source, $CLASS );
	my %orig   = ref($source) ? %{$source} : ();
	my $self   = bless { %defaults, %orig, @_ }, $class;

	weaken $self->{'login'};
	weaken $self->{'ship'};

	return $self;
}

sub name     { shift->{'name'}; }
sub hire_url { shift->{'hire_url'}; }
sub fire_url { shift->{'fire_url'}; }
sub index    { shift->{'index'}; }
sub ship     { shift->{'ship'}; }
sub login    { shift->{'login'}; }

1;
