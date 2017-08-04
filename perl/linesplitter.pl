my %info;
foreach (<>) {
    my @chunks = split /(\s\S+\@\S+\s)/, " $_";
    # print join "\n", map { "'$_'" } @chunks;
    my $email = '';
    my $pass = '';
    foreach my $chunk (@chunks) {
        if ($chunk =~ m/\s(\S+\@\S+)\s/) {
            $info{$email} = $pass;
            $email = $1;
        }
        else {
            $pass = $chunk;
        }
    }
}

foreach (sort keys %info) {
    print "$_ $info{$_}\n";
}
