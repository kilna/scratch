#!/usr/bin/perl -w
use strict;
use warnings;

package Expansion::Config;

use Expansion::Login;

$Expansion::Config::DEBUG = 1;
  
my %defaults = (
	'debug' => 0,
);

# Gets a config file formatted thusly:
#
# foo = bar
# single_line_array [ value1 | value2 | value3 ]
# multi_line_array (
#   v1
#   v2
#   v3
# )
# subfoo {
#   bar = baz
#   fo = shizzle
#   subsubfoo {
#     oh = yeah
#   }
#   subarray (
#     {
#       key = value
#     }
#   )
# }
#
# Returns it as a perl structure n-levels deep
#
# {
#   'foo' => 'bar',
#   'single_line_array' = [
#     'value1',
#     'value2',
#     'value3',
#   ],
#   'multi_line_array' = [
#     'v1',
#     'v2',
#     'v3',
#   ],
#   'subfoo' => {
#     'bar' => 'baz',
#     'fo' => 'shizzle'
#     'subsubfoo' => {
#       'oh' => 'yeah'
#     }
#     'subarray' => [
#       {
#         'key' => 'value'
#       }
#     ]
#   }
# }
#
# Call as Expansion::Config->new( filename )
sub new
{
	my $package        = shift;                         # Always call as Expansion::Config->new( filename )
	my $file           = shift;                         # Filename
	my $contents       = shift;                         # Hashref of the lines in the file (only passed when calling itself recursively)
	my $start_line_num = defined( $_[0] ) ? shift: 1;   # Which line we're processing in the file (recursive only)
	my $mode           = defined( $_[0] ) ? shift: '{'; # Whether we're processing a hash { array ( or multi-line string <

	if ( not defined $contents )
	{
		# Load the file into the arrayref
		open CONFIG, '<', $file or die "Unable to open file $file: $!";
		$contents = [<CONFIG>];
		close CONFIG;
	}

	# This is this nesting level's results hash $line_num = Which line we're processing... line number can get bumped by
	# processing lower nesting levels
	my $struct; 
	my $indent_level;
	
	# Process up to the end of the file... if we're nested we'll process up to the }
	for ( my $line_num = $start_line_num ; $line_num < scalar(@$contents) ; $line_num++ )
	{
		# Get the contents of the line we're processing
		my $line = $contents->[$line_num - 1];
		$Expansion::Config::DEBUG && print STDERR "Line num $line_num ($start_line_num) : $line\n";

		if ( $mode eq '{' )
		{
			if (not defined $struct) { $struct = $start_line_num ? {} : {%defaults}; }

			# See what kind of line we're dealing with
			if ( $line =~ m/^ \s* (\#|$) /x )
			{
				next; # Comment / blank line, skip
			}
			elsif ( $line =~ m/ ^ \s* (\w+|\".*?\"|\'.*?\') \s* \= \s* (.*) \s* $ /x )
			{
				$struct->{ dequote($1) } = dequote($2);
			}
			elsif ( $line =~ m/ ^ \s* (\w+|\".*?\"|\'.*?\') \s* \[ \s* (.*?) \s* \] \s* $ /x )
			{
				$struct->{ dequote($1) } = [ split /\s*\|\s*/, $2 ];
			}
			elsif ( $line =~ m/ ^ \s* (\w+|\".*?\"|\'.*?\') \s* ( \{ | \( | \< ) \s* $ /x )
			{
				# Make the recursive call, and get both the structure and the line number
				# so we can continue processing this level where the nested level stopped
				( $struct->{ dequote($1) }, $line_num )
				  = Expansion::Config->new( $file, $contents, $line_num + 1, $2 );
			}
			elsif ( $line =~ m/ ^ \s* ( \) | \< ) \s* $ /x )
			{
				die "Unexpected $1 at line $line_num of file $file";
			}
			elsif ( $line =~ m/ ^ \s* } \s* $ /x )
			{
				# Sub-hash end
				if ( $start_line_num == 1 )
				{
					# If we're at the outermost level, a } should throw an error
					die "Unexpected } at line $line_num of file $file";
				}
				# We should only get to this return if we're at some nested level within the file
				return ( $struct, $line_num );
			}
			else
			{
				# Somethign we didn't recognize?  Abort!
				die "Malformed config at line $line_num of file $file";
			}
		}
		elsif ( $mode eq '(' )
		{
			if (not defined $struct) { $struct = []; }

			# See what kind of line we're dealing with
			if ( $line =~ m/^ \s* (\#|$) /x )
			{
				next; # Comment / blank line, skip
			}
			elsif ( $line =~ m/ \s* ( \{ | \( | \< )\s* $ /x )
			{
				# Make the recursive call, and get both the structure and the line number
				# so we can continue processing this level where the nested level stopped
				( my $val, $line_num )
				  = Expansion::Config->new( $file, $contents, $line_num + 1, $2 );
				push @$struct, $val;
			}
			elsif ( $line =~ m/ ^ \s* \) \s* $ /x )
			{
				# Array end
				if ( $start_line_num == 1 )
				{
					# If we're at the outermost level, a ) should throw an error
					die "Unexpected ) at line $line_num of file $file";
				}
				# We should only get to this return if we're at some nested level within the file
				return ( $struct, $line_num );
			}
			elsif ( $line =~ m/ ^ \s* ( \} | \< ) \s* $ /x )
			{
				die "Unexpected $1 at line $line_num of file $file";
			}
			elsif ( $line =~ m/ ^ \s* \[ \s* (.*?) \s* \] \s* $ /x )
			{
				push @$struct, [ split /\s*\|\s*/, $2 ];
			}
 			elsif ( $line =~ m/ ^ \s* (.*?) \s* $ /x )
			{
				push @$struct, dequote($1);
			}
		}
		elsif ( $mode eq '<' )
		{
			if (not defined $struct)
			{
				$struct = '';
				$indent_level = '';
			}
			
			if ( $line =~ m/ ^ \s* \> \s* $ /x )
			{
				return($struct, $line_num)
			}
			elsif ( ( $indent_level eq '' ) && ( $line =~ m/ ^ (\s*) (.*?) $ /x ) )
			{
				$indent_level = $1;
				$struct .= $2;
			}
			elsif ( $line =~ m/ ^ \Q $indent_level \E (.*?) $ /x )
			{
				$struct .= $1;
			}
			elsif ( $line =~ m/ ^ \s* (.*?) $ /x )
			{
				$struct .= $1;
			}			
		}
	} ## end for ( my $line_num = $start_line_num ; $line_num < scalar(@$contents) ; $line_num++...

	$Expansion::Config::DEBUG && print STDERR Data::Dumper->Dump( [$struct], ['$struct'] );

	if ($start_line_num == 1) { bless $struct; }

	# We should only get to this return if we're done processing at the top nesting level of the file
	return ($struct);

} ## end sub process

sub dequote
{
	my $string = shift;
	if ($string =~ m/^\"(.*)\"$/) { return $1; }
	if ($string =~ m/^\'(.*)\'$/) { return $1; }
	return $string;
}

sub play {
	
	my $self = shift;

	my %login_params = ( 'config' => $self );
	foreach (qw(user password server agent debug cookies_file)) {
		next unless defined($self->{$_});
		$login_params{$_} = $self->{$_};
	}
	
	my $login = Expansion::Login->new( %login_params );
	
	while (my $fleet = $login->next_fleet)
	{
		next unless defined($self->{'fleets'}{$fleet->name});
		last if $login->at_max_credits;
		$fleet->emergency_repair_if_needed;
		unless ($fleet->location->is_planet) {
			$fleet->go_to_closest_planet;
			next;
		}
		$fleet->sell_ships;
		$fleet->hire_crew;
		$fleet->repair_ships;
		unless ($fleet->all_ships_fully_repaired && $fleet->have_necessary_crew) {
			$fleet->set_arrival_time($self->{'wait_period'}, 1);
			next;
		}
		next if $fleet->persue_ship;
		next if $fleet->go_on_mission;
		$fleet->go_to_closest_planet;
	}	
	
}

1;
