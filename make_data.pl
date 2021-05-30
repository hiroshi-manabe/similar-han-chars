#!/usr/bin/env perl
# Usage: ./make_data.pl < IDS-UCS-Basic.txt > data.js
use strict;
use utf8;
use open IO => ':utf8', ':std';

sub main {
    my %dict = ();
    my %rev_dict = ();
    my %part_dict = ();
    my $count = 0;
    print <<HEAD;
function set_data(split_data, member_data) {
HEAD
    while (<STDIN>) {
        chomp;
        my @F = split/\t/;
        next if m{^;};
        my $parts_count = 0;
        while (1) {
            $F[2] =~ s{(([\x{2ff0}-\x{2ff1}\x{2ff4}-\x{2ffb}])([^&\x{2ff0}-\x{2ffb}]|&.+?;)([^&\x{2ff0}-\x{2ffb}]|&.+?;)|([\x{2ff2}-\x{2ff3}])([^&\x{2ff0}-\x{2ffb}]|&.+?;)([^&\x{2ff0}-\x{2ffb}]|&.+?;)([^&\x{2ff0}-\x{2ffb}]|&.+?;))}{
                my $is_top = (${^PREMATCH} eq "") and (${^POSTMATCH} eq "");
                if (not exists $rev_dict{$1}) {
                    $rev_dict{$1} = $is_top ? $F[1] : sprintf("&ORG-%04x;", $count);
                    $dict{$rev_dict{$1}} = $1;
                    $count++;
                }
                if ($is_top) {
                    if ($2) {
                        $part_dict{$3}->{$F[1]} = ();
                        $part_dict{$4}->{$F[1]} = ();
                        print qq{    split_data["$F[1]"] = ["$3", "$4"];\n};
                    }
                    else {
                        $part_dict{$6.$8}->{$F[1]} = ();
                        $part_dict{$7}->{$F[1]} = ();
                        print qq{    split_data["$F[1]"] = ["$6$8", "$7"];\n};
                    }
                }
                $rev_dict{$1};
            }egp;
            last if $F[2] !~ m{[\x{2ff0}-\x{2ffb}]};
        }
    }
    for my $part(sort keys %part_dict) {
        print qq{    member_data["$part"] = [}.join(", ", map { qq{"$_"}; }  sort keys %{$part_dict{$part}}).qq{];\n};
    }
    print "}\n";
}



if ($0 eq __FILE__) {
    main();
}
