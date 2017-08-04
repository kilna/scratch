#!/usr/bin/perl

package Expansion::Util;
require Exporter;
@EXPORT = qw(process_table decomma format_num extract_link get_time secs_to_time time_to_secs);

use POSIX;

sub process_table
{
	my $page        = shift;
	my $cols        = shift;
	my $table_match = shift;

	my ( $table_start, $table_end ) = split /\*/, $table_match, 2;
	if ( $page !~ m/\Q$table_start\E(.*?)\Q$table_end\E/ )
	{
		return;
	}
	my $table = $1;

	my @rows = ();
	while ( $table =~ m|<tr[^>]*>(.*?)</tr>|i )
	{
		my $hash  = {};
		my $row   = $1;
		my $count = 0;
		while ( $row =~ m|<td[^>]*>(.*?)</td>|i )
		{
			$hash->{ $cols->[$count] } = $1;
			$count++;
			$row =~ s|<td[^>]*>(.*?)</td>||i;
		}
		$table =~ s|<tr[^>]*>(.*?)</tr>||i;
		push @rows, $hash;
	}

	return @rows;
}

sub decomma
{
	my $num = shift;
	$num =~ s/\,//gs;
	return $num;
}

sub format_num
{
	my $num = shift;
	return $num unless ( $num =~ m/^\d+$/ );
	while ( $num =~ s/(\d)(\d\d\d)(?:,|\.|$)/$1,$2/g ) { }
	return $num;
}

sub extract_link
{
	my $string = shift;
	if ( $string =~ m/href=\"(.*?)\"/ )
	{
		my $link = $1;
		if ( $link !~ m/^\Q$server\E/ )
		{
			$link = $server . $link;
		}
		return $link;
	}
	return '';
}

sub timer
{
	my $secs      = shift;
	my $countdown = $secs;
	while ( $countdown >= 0 )
	{
		if ( $countdown != $secs )
		{
			print( "\b" x 8 );
		}
		print secs_to_time($countdown);
		sleep 1;
		$countdown--;
	}
	print "\n";
}

sub secs_to_time
{
	my $s = shift;
	unless ( $s =~ m/^\d$/ )
	{
		die "Unable to process seconds '$s'\n"
	}
	my $h = 0;
	my $m = 0;
	if ( $s >= 3600 )
	{
		$h = int( $s / 3600 );
		$s = ( $s % 3600 );
	}
	if ( $s >= 60 )
	{
		$m = int( $s / 60 );
		$s = ( $s % 60 );
	}
	return sprintf( '%02d:%02d:%02d', $h, $m, $s );
}

sub time_to_secs
{
	my $time = shift;
	if ( $time !~ m/^(\d\d)\:(\d\d)\:(\d\d)$/ )
	{
		return ( ( $1 * 3600 ) + ( $2 * 60 ) + $3 );
	}
	else
	{
		die "Unable to process time $time\n"
	}
}

sub get_time
{
	my $secs = defined($_[0]) ? time_to_secs(shift) : 0;
	return wantarray ? ( $secs, secs_to_time($secs) ) : $secs;
}

1;
