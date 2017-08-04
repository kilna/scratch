#!/usr/bin/perl -w

package Expansion::Login;
my $CLASS = 'Expansion::Login';

use strict;
use warnings;

use Expansion::Location;
use Expansion::Util;
use Expansion::Fleet;

use LWP::UserAgent;
use Data::Dumper;
use List::Util qw(first);
use Scalar::Util qw(weaken);
use POSIX qw(:termios_h);

my %defaults = (
	'server'             => 'http://www.blah.net',
	'user'               => '',
	'password'           => '',
	'agent'              => "Kilna's Expansion Credit Bot/2.0",
	'debug'              => 0,
	'cookies_file'       => '',
	'planet_check_count' => 0,
);

sub new
{
	my $source = shift;
	my $class  = first { defined($_) && $_ }( ref($source), $source, $CLASS );
	my %orig   = ref($source) ? %{$source} : ();
	my $self   = bless { %defaults, %orig, @_ }, $class;

	weaken $self->{'config'};

	$self->req( 'path' => '' );

	return $self;
}

sub url
{
	my $self = shift;
	my $path = shift;

	my $server = $self->{'server'};
	
	if    ( $path eq 'login' )  { return "$server/drupal/node?destination=node"; }
	elsif ( $path eq 'logout' ) { return "$server/drupal/logout"; }
	else { return "$server/drupal/expansion/$path"; }
}

sub req
{
	my $self   = shift;
	my %params = @_;

	my $ua  = $self->ua;
	my $url = defined( $params{'url'} ) ? $params{'url'} : $self->url( $params{'path'} );

	my $resp    = $ua->get($url);
	my $results = $resp->content;

	unless ( $resp->is_success )
	{
		sleep 10;
		return $self->req(%params);
	}

	if ( $results =~ m/You are not authorized to access this page/ )
	{
		if ( defined( $params{'no_login'} ) && $params{'no_login'} )
		{
			die "Failed to log in properly\n";
		}
		my $login_resp = $ua->post(
			$self->url('login'),
			{
				'name'    => $self->{'user'},
				'pass'    => $self->{'password'},
				'op'      => 'Log in',
				'form_id' => 'user_login_block',
			}
		);

		if ( $login_resp->content =~ m/Sorry, unrecognized username or password/ )
		{
			die "Unrecognized username or password\n";
		}
		elsif ( $login_resp !~ m/Your Stats/ )
		{
			die "Failed to recognize page upon login\n";
		}

		return $self->req( %params, 'no_login' => 1 );
	}

	if ( $results =~ m/<b>Credits:<\/b>\s*([0-9,]+)\s*<br>/ )
	{
		$self->{'credits'} = decomma($1);
	}
	if ( $results =~ m/<b>Score:<\/b>\s*([0-9,]+)\s*<br>/ )
	{
		$self->{'score'} = decomma($1);
	}

	if ( $results =~ m/<b>Fleet:<\/b>\s*(.*?)\s+Fleet\s*<br>/ )
	{
		my $name = $1;
		if ( $name ne $self->{'current_fleet'} )
		{
			$self->{'current_fleet'} = $name;
		}
	}
	else
	{
		die "Unable to determine current fleet\n";
	}

	if ( $results =~ m/<b>Location:<\/b>\s*(.*?)\s*<br>/ )
	{
		$self->current_fleet->set_location($1);
	}

	if ( $results =~ m/<b>Destination:<\/b>\s*(.*?)\s*<br>/ )
	{
		$self->current_fleet->set_destination($1);
	}
	else
	{
		$self->current_fleet->set_destination('');
	}

	if ( $results =~ m/<b>Ship:<\/b>\s*(.*?)\s*<br>/ )
	{
		$self->current_fleet->set_current_ship($1);
	}

	if ( $results =~ m|<b>Trip Time:</b>\s*<span[^>]>\s*(.*?)\s*</span>| )
	{
		$self->current_fleet->set_arrival_time( time + get_time($1) + 1, 0 );
	}
	else
	{
		$self->current_fleet->set_arrival_time( undef, 0 );
	}

	return $results;
} ## end sub req

sub credits            { shift->{'credits'}; }
sub score              { shift->{'score'}; }
sub config             { shift->{'config'}; }
sub planet_check_count { shift->{'planet_check_count'}; }

sub planets
{
	my $self        = shift;
	my @set_planets = @_;
	if ( scalar @set_planets )
	{
		foreach my $planet (@set_planets)
		{
			$self->{'planets'}{ $planet->name } = $planet;
		}
		$self->{'planet_check_count'}++;
	}
	return %{ $self->{'planets'} };
}

sub effective_credits
{
	my $self = shift;
	if ( $self->credits <= $self->config->{'min_credits'} )
	{
		return 0;
	}
	return ( $self->credits - $self->config->{'min_credits'} );
}

sub at_max_credits
{
	my $self = shift;
	if ( $self->credits >= $self->config->{'max_credits'} )
	{
		return 1;
	}
	return 0;
}

sub next_fleet
{
	my $self = shift;

	my $fleet_name      = undef;
	my $time_to_arrival = undef;

	# This will get the arrival times for all fleets
	foreach my $fleet ( $self->all_fleets )
	{
		$self->change_current_fleet( $fleet->name );
		unless ( defined($time_to_arrival) && defined($fleet_name) )
		{
			$time_to_arrival = $fleet->time_to_arrival;
			$fleet_name      = $fleet->name;
			next;
		}
		if ( $time_to_arrival < $fleet->time_to_arrival )
		{
			$time_to_arrival = $fleet->time_to_arrival;
			$fleet_name      = $fleet->name;
		}
	}

	my $fleet = $self->fleet($fleet_name);

	if ($time_to_arrival)
	{
		my $term;
		if ( $self->{'debug'} )
		{
			print "Waiting for fleet " . $fleet->name . " to arrive at " . $fleet->destination . "\n";
			print "Arrival in: ";
			timer($time_to_arrival);
		}
		else
		{
			sleep $time_to_arrival;
		}
	}

	return $fleet;
}

sub fleet
{
	my $self = shift;
	my $name = shift;

	$self->all_fleets();

	return $self->{'fleets'}{$name};
}

sub all_fleets
{
	my $self   = shift;
	my %params = @_;

	if ( ( not defined $self->{'fleets'} ) || defined( $params{'reset'} ) )
	{
		my $resp = $self->req( 'path' => 'view/ fleet' );
		$self->{'fleets'} = {};
		if ( $resp =~ m|<hr>Select another fleet:\s*(.*?)\s*<br>| )
		{
			my $fleet_links = $1;
			foreach ( split /\s*\|\s*/, $fleet_links )
			{
				next unless m|<a href="(/drupal/expansion/set/fleet\?fleet_index=(\d+)\&amp\;dest=view/fleet)">(.*?)</a>|;
				$self->{'fleets'}{$3} = Expansion::Fleet->new(
					'login' => $self,
					'name'  => $3,
					'index' => $2,
					'url'   => $1,
				);
			}
		}

	}

	return values %{ $self->{'fleets'} };
}

sub current_fleet
{
	my $self = shift;

	return $self->fleet( $self->{'current_fleet'} );
}

sub change_current_fleet
{
	my $self = shift;
	my $name = shift;

	$self->req( $self->fleet($name)->url );

}

sub logout
{
	my $self = shift;

	$self->ua->get( $self->url('logout') );
}

sub get_centerpoint { shift->{'centerpoint'}; }

sub set_centerpoint
{
	my $self     = shift;
	my $location = shift;
	$self->{'centerpoint'} = $location;
}

sub ua
{
	my $self = shift;

	unless ( defined $self->{'ua'} )
	{

		$self->{'ua'} = LWP::UserAgent->new;
		$self->{'ua'}->agent( $self->{'agent'} );
		my $cookies_file = $self->{'cookies_file'};
		if ( ( not defined $cookies_file ) || ( $cookies_file eq '' ) )
		{
			$cookies_file = $ENV{'HOME'} . '.cookies_' . $self->{'user'};
		}
		$self->{'ua'}->cookie_jar(
			{
				'file'     => $cookies_file,
				'autosave' => 1,
			}
		);
		push @{ $self->{'ua'}->requests_redirectable }, 'POST';
	}

	return $self->{'ua'};
}

1;
