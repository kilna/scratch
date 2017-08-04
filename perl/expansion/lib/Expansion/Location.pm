#!/usr/bin/perl

package Expansion::Location;
my $CLASS = 'Expansion::Location';

use strict;
use warnings;

use Scalar::Util qw(weaken);

use Expansion::Util;

my @nav_cols = qw(name distance location time set_course);

my %defaults = ();

sub new
{

	my $source = shift;
	my $class  = first { defined($_) && $_ }( ref($source), $source, $CLASS );
	my %orig   = ref($source) ? %{$source} : ();
	my $self   = bless { %defaults, %orig, @_ }, $class;

	weaken $self->{'login'};

	my @planets = $self->get_planets;

	if ( $self->{'loc'} =~ m/(\d+)\s*,\s*(\d+)/ )
	{
		$self->{'x'} = $1;
		$self->{'y'} = $2;
		foreach my $p (@planets)
		{
			if ( ( $p->get_x == $self->get_x ) && ( $p->get_y == $self->get_y ) )
			{
				$self->{'name'} = $p->name;
			}
		}
	}
	else
	{
		foreach my $p (@planets)
		{
			next if ( $p->name ne $self->{'loc'} );
			$self->{'name'} = $p->name;
			$self->{'x'}    = $p->get_x;
			$self->{'y'}    = $p->get_y;
		}
	}

	unless ( defined( $self->get_x ) && defined( $self->get_y ) )
	{
		die "Unknown location $self->{'loc'}\n";
	}

	return $self;

}

sub get_x     { shift->{'x'}; }
sub get_y     { shift->{'y'}; }
sub name      { defined( $_[0]->{'name'} ) ? $_[0]->{'name'} : ''; }
sub is_planet { defined( shift->{'name'} ); }
sub login     { shift->{'login'}; }

sub get_planets
{
	my $self = shift;
	if ( ( not defined $self->login->planets ) && ( $self->login->planet_check_count < 2 ) )
	{
		my @planets = ();
		my @rows    = process_table(
			$self->login->req( 'path' => 'navigation' ),
			\@nav_cols,
			'<th>Set Course?</th> </tr></thead>*</tbody>'
		);
		foreach my $row (@rows)
		{
			my ( $x, $y ) = ( $row->{'location'} =~ m/\b(\d+)\s*\,\s*(\d+)\b/ );
			my $planet = {
				'name'  => $row->{'name'},
				'loc'   => $row->{'name'},
				'x'     => $x,
				'y'     => $y,
				'url'   => get_url( $row->{'set_course'} ),
				'login' => $self->{'login'},
			};
			weaken $planet->{'login'};
			bless $planet, ref($self);
		}
		$self->login->planets( \@planets );
	}

	return values %{ $self->login->planets };
}

sub get_centerpoint
{

	my $self = shift;

	my $centerpoint = $self->login->centerpoint;

	unless ( defined($centerpoint) )
	{
		my $total_x = 0;
		my $total_y = 0;
		my $count   = 0;
		foreach my $planet ( $self->get_planets )
		{
			$total_x += $planet->get_x;
			$total_y += $planet->get_y;
			$count++;
		}
		my $cp_x = int( ( $total_x / $count ) + 0.5 );
		my $cp_y = int( ( $total_y / $count ) + 0.5 );

		my $name = '';
		foreach my $planet ( $self->get_planets )
		{
			next unless ( ( $cp_x == $planet->get_x ) && ( $cp_y == $planet->get_y ) );
			$name = $planet->name;
		}

		$centerpoint = bless {
			'loc'  => "Sector $cp_x, $cp_y",
			'x'    => $cp_x,
			'y'    => $cp_y,
			'name' => $name,
		  },
		  ref($self);

		$self->login->set_centerpoint($centerpoint);
	}

	return $centerpoint;
}

sub distance
{

	my $from = shift;
	my $to   = shift;

	my $distance_x = $from->get_x - $to->get_x;
	if ( $distance_x < 0 ) { $distance_x = 0 - $distance_x; }
	my $distance_y = $from->get_y - $to->get_y;
	if ( $distance_y < 0 ) { $distance_y = 0 - $distance_y; }

	return sprintf '%.3f', sqrt( ( $distance_x * $distance_x ) + ( $distance_y * $distance_y ) );

}

sub distance_to_centerpoint
{

	my $self = shift;

	return $self->distance( $self->login->centerpoint )
}

sub closest_planet
{

	my $self = shift;

	my $closest_planet = undef;
	foreach my $planet ( $self->get_planets )
	{
		next if ( $self->name eq $planet->name );
		next if ( $self->distance($planet) > $self->distance($closest_planet) );
		$closest_planet = $planet;
	}

	return $closest_planet;
}

sub trip_distance
{

	my $self = shift;
	my $dest = shift;

	my $trip_distance = $self->distance($dest);
	unless ( $dest->is_planet )
	{
		$trip_distance += $dest->distance( $dest->closest_planet );
	}

	return $trip_distance;
}

1;
