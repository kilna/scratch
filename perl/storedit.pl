#!/usr/bin/perl -w

#use Data::Denter;
use YAML;
use Storable;
use File::Copy;

#$Data::Denter::Width = 8;

($filename) = @ARGV;

unless (defined($filename) && $filename) {
        die "usage: storedit filename\n";
}

$shortfilename = $filename;
$shortfilename =~ s/^.*\/(.*?)$/$1/;

if (-f $filename) {
        copy($filename,"/tmp/$shortfilename.bak");
        open(OUT,">/tmp/$shortfilename.tmp") or die "Unable to write to file '/tmp/$shortfilename.tmp'\n";
        my $var;
        #$var = Indent(retrieve($filename)) or die "Unable to open file '$filename' for reading";
        $var = Dump(retrieve($filename)) or die "Unable to open file '$filename' for reading";
        foreach my $line (split(/\n/,$var)) {
        #       while ($line =~ /^(\t*) {8}/) {
        #               $line =~ s/^(\t*) {8}(.*)$/$1\t$2/;
        #       }
                print OUT $line . "\n";
        }
        close OUT;
}
else {
        open(OUT,">/tmp/$shortfilename.tmp") or die "Unable to write to file '/tmp/$shortfilename.tmp'\n";
        print OUT "";
        close OUT;
}

system("nano -w /tmp/$shortfilename.tmp");

$/ = undef;
open(IN, "/tmp/$shortfilename.tmp") or die "Unable to open file '/tmp/$shortfilename.tmp' for reading post-edit\n";
$var = <IN>;
close IN;
#store(Undent($var),$filename) or die "Unable to write to file '$filename' post-edit\n";
store(Load($var),$filename) or die "Unable to write to file '$filename' post-edit\n";

unlink("/tmp/$shortfilename.tmp");

