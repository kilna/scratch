#!/usr/bin/perl -w

package Expansion::Fleet;
my $CLASS = 'Expansion::Fleet';

use strict;
use warnings;

use Scalar::Util qw(weaken);

my %defaults = (
	'arrival_time_forced' => 0,
);

my @fleet_cols = qw(ship speed mass cargo quarters sensor_efficiency repair_rate repair_time repair);
my @shipyard_cols = qw(ship resale_value sell);
my @departures_cols = qw(name class speed mass combat_rating pursue);
my @recruiting_cols = qw(type rank name skills pay cost hire);
my @mission_cols = qw(type distance destination time credits description requirements accept);

sub new
{
	my $source = shift;
	my $class  = first { defined($_) && $_ }( ref($source), $source, $CLASS );
	my %orig   = ref($source) ? %{$source} : ();
	my $self   = bless { %defaults, %orig, @_ }, $class;

	weaken $self->{'login'};

	return $self;
}

sub name                { shift->{'name'}; }
sub url                 { shift->{'url'}; }
sub login               { shift->{'login'}; }
sub index               { shift->{'index'}; }
sub current_ship_name   { shift->{'current_ship'}; }
sub location            { shift->{'location'}; }
sub destination         { shift->{'destination'}; }
sub arrival_time_forced { shift->{'arrival_time_forced'}; }

sub emergency_repair_if_needed
{
	my $self = shift;

	my @rows = process_table(
		$self->login->req( 'path' => 'view/fleet' ),
		\@fleet_cols,
		'<th>repair?</th> </tr></thead>*</tbody>'
	);

	foreach my $row (@rows)
	{
		next if ( $row->{'speed'} > $self->login->config->{'min_emergency_repair_speed'} );
		my $url = extract_link( $row->{'repair'} );
		next unless $url;
		$self->login->req( 'url' => $url );
	}
}

sub go_to_closest_planet
{
	my $self = shift;
	$self->login->req( 'url' => $self->location->closest_planet->url );
}

sub config
{
	my $self = shift;
	return $self->login->config->{'fleets'}{ $self->{'name'} };
}

sub is_current
{
	my $self = shift;
	return ( $self->login->current_fleet->name eq $self->name );
}

sub set_current_destination
{
	my $self = shift;
	my $loc  = shift;

	if ( ( not defined $loc ) || ( not defined $self->{'destination'} ) || ( $self->{'destination'}->loc ne $loc ) )
	{
		$self->{'destination'} = Expansion::Location->new(
			'loc' => $loc,
		);
	}
}

sub set_current_location
{
	my $self = shift;
	my $loc  = shift;

	if ( ( not defined $loc ) || ( not defined $self->{'location'} ) || ( $self->{'location'}->loc ne $loc ) )
	{
		$self->{'location'} = Expansion::Location->new(
			'loc' => $loc,
		);
	}
}

sub set_current_ship
{
	my $self      = shift;
	my $ship_name = shift;

	unless (defined($self->{'current_ship'}) && ($self->{'current_ship'} eq $ship_name ) )
	{
		$self->{'current_ship'} = $ship_name;
	}

}

sub current_ship
{
	my $self = shift;
	return $self->ship( $self->current_ship_name )
}

sub change_current_ship
{
	my $self = shift;
	my $name = shift;
	$self->login->req( $self->ship($name)->url );
}

sub all_ships
{
	my $self   = shift;
	my %params = @_;

	if ( ( not defined $self->{'ships'} ) || ( defined $params{'reset'} ) )
	{

		$self->ensure_current;

		my $resp = $self->login->req( 'path' => 'view/ship' );
		if ( $resp =~ m|<hr>Select another ship:\s*(.*?)\s*<br>| )
		{
			my $ship_links = $1;
			foreach ( split /\s*\|\s*/, $ship_links )
			{
				next unless m|<a href="(/drupal/expansion/set/ship\?ship_index=(\d+)\&amp;dest=view/ship)">(.*?)</a>|;
				my $ship_name = $3;
				my $index = $2;
				my $select_url = $1;
				$self->{'ships'}{$ship_name} = Expansion::Ship->new(
					'login' => $self->login,
					'fleet' => $self,
					'name'  => $ship_name,
					'index' => $index,
					'select_url'   => $select_url,
				);
			}
		}
	}

	return values %{ $self->{'ships'} };
}

sub sell_ships
{
	my $self = shift;

	my @rows = process_table(
		$self->login->req( 'path' => 'shipyard/fleet' ),
		\@shipyard_cols,
		'<th>Sell?</th> </tr></thead>*</tbody>'
	);
	
	foreach my $row (@rows)
	{
		next unless defined($self->config->{'ships'}{$row->{'ship'}});
		my $url = extract_link($row->{'sell'});
		next unless $url;
		$self->login->req( 'url' => $url );
	}
}

sub hire_crew {
	my $self = shift;
	
	my $page = $self->login->req( 'path' => 'view/crew' );
	
	my %needed_types = ();
	while ($page =~ m/You only have (\d+)\/(\d+) of the required (\w+) crew\./) {
		$needed_types{$3} = $2 - $1;
		$page =~  s/You only have \d+\/\d+ of the required \w+ crew\.//;
	}
	
	my $num_hired = 0;
	foreach my $type (keys %needed_types)
	{
		my @recruits = process_table(
			$self->login->req( 'path' => 'recruiting?filter='.$type ),
			\@recruiting_cols,
			'<th>Hire?</th> </tr></thead>*</tbody>'			
		);
		foreach my $recruit (sort {$a->{'cost'} <=> $b->{'cost'}} @recruits)
		{
			last if ($self->login->credits < $recruit->{'cost'});
			my $url =  extract_link($recruit->{'hire'});
			next unless $url;
			$self->login->req( 'url' => $url );
			$num_hired++;
		}
	}
	return $num_hired;
}

sub repair_ships {
	my $self = shift;
	# TODO
}

sub all_ships_fully_repaired {
	my $self = shift;
	# TODO
	return 1;
}

sub have_necessary_crew {
	my $self = shift;
	my $page = $self->login->req( 'path' => 'view/crew' );
	return ($page =~ m/You only have/) ? 0 : 1;
}

sub pursue_ship {
	my $self = shift;
	my @rows = process_table(
		$self->login->req( 'path' => 'departures' ),
		\@departures_cols,
		'<th>Pursue?</th> </tr></thead>*</tbody>'
	);
	foreach my $row (sort { $b->{'combat_rating'} <=> $a->{'combat_rating'} } @rows)
	{
		next if ($b->{'combat_rating'} < $self->login->config->{'min_combat_rating'});
		my $url = extract_link($row->{'sell'});
		next unless $url;
		$self->login->req( 'url' => $url );
		return 1;
	}
	return 0;
}

sub go_on_mission {
	my $self = shift;
	my @rows = process_table(
		$self->login->req( 'path' => 'showMissions' ),
		\@departures_cols,
		'<th>Accept?</th> </tr></thead>*</tbody>'
	);
	my @process_rows =();
	foreach my $row (@rows)
	{
		next if $row->{'credits'} == 0;
		$row->{'ratio'} = $row->{'credits'} / time_to_secs($row->{'time'});
		push @process_rows, $row;
	}
	foreach my $row (sort { $b->{'ratio'} <=> $a->{'ratio'} } @process_rows)
	{
		my $url = extract_link($row->{'sell'});
		next unless $url;
		$self->login->req( 'url' => $url );
		return 1;
	}
	return 0;
}

sub ensure_current
{
	my $self = shift;
	unless ( $self->is_current )
	{
		$self->login->change_current_fleet( $self->name );
	}
}

sub ship
{
	my $self = shift;
	my $name = shift;

	$self->all_ships;

	return $self->{'ships'}{$name};
}

sub set_arrival_time
{
	my $self   = shift;
	my $time   = shift;
	my $forced = defined( $_[0] ) ? shift: 0;
	if ( $self->{'arrival_time_forced'} && not $forced )
	{
		return;
	}
	$self->{'arrival_time'}        = $time;
	$self->{'arrival_time_forced'} = $forced;
}

sub arrival_time
{
	my $self = shift;
	if ( not defined $self->{'arrival_time'} )
	{
		$self->{'arrival_time_forced'} = 0;
		$self->{'arrival_time'}        = undef;
	}
	return $self->{'arrival_time'};
}

sub time_until_arrival
{
	my $self = shift;
	unless ( defined $self->arrival_time )
	{
		return 0;
	}
	return ( time - $self->arrival_time );
}

1;
