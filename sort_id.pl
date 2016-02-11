#!/usr/bin/env perl -w
#use strict;
#use warnings;

# find AS number
# created by snumano 2016/2/7

# CPANより下記ライブラリをinstall
#use Jcode;
#use Encode;
use POSIX qw(strftime);
use Data::Dumper;

my $today = strftime "%Y%m%d%H%M%S", localtime;

# how to use
unless ($ARGV[0]){
    print "Usage:\n";
    print "sort_id.pl <input_file>\n";
}

# Main
open(OUT,"> ./$ARGV[0].$today");
&sort_list;
close(OUT);
exit;

### サブルーチン ###
sub sort_list{
    open(IN, $ARGV[0]) or die "$!";
    my $i = 1;
    while(<IN>){
	my @line = split(/\t/, $_);
	if ($line[0] =~ /id/){
	    print OUT $_;
	    next;
	}
	print OUT "$i\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$line[9]\t$line[10]";
	$i++;
    }
}
