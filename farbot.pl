#!/usr/bin/perl

use strict;
use warnings;

use IRC::Bot;

# Initialize new object
my $bot = IRC::Bot->new( Debug    => 0,
                         Nick     => 'FarBot',
                         Server   => 'irc.scifi-fans.net',
                         Pass     => '',
                         Port     => '6667',
                         Username => 'FarBot',
                         Ircname  => 'FarBot',
                         Admin    => 'admin',
                         Apass    => '',
                         Channels => [ '#scapers' ],
                         LogPath  => 'farbot.log',
);

# Daemonize process 
$bot->daemon();

# Run the bot
$bot->run();

__END__
