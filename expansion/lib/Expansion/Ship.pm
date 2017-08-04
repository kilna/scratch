#!/usr/bin/perl -w

package Expansion::Ship;
my $CLASS = 'Expansion::Ship';

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

	weaken $self->{'fleet'};

	return $self;
}

sub name        { shift->{'name'}; }
sub url         { shift->{'url'}; }
sub index       { shift->{'index'}; }
sub fleet       { shift->{'fleet'}; }
sub location    { shift->fleet->{'location'}; }
sub destination { shift->fleet->{'destination'}; }
sub login       { shift->fleet->login; }

sub config
{
	my $self = shift;
	return $self->fleet->config->{'ships'}{ $self->name };
}

sub is_current
{

	my $self = shift;

	return ( $self->fleet->current_ship->name eq $self->name );
}

sub modules
{
}

sub repair_all
{
	my $self = shift;
}

sub needed_positions
{
	my $self = shift;
	my $type = shift;
}

1;
