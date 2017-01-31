#!/usr/bin/perl -w

# created by snumano 2017/01/28

use strict;
use warnings;
use utf8;

# CPANより下記ライブラリをinstall
#use Net::DNS;
#use Term::ReadKey;
use Web::Scraper;
use URI;
use Jcode;
use Encode;
use POSIX qw(strftime);
use Data::Dumper;

### init ###

my $today = strftime "%Y%m%d%H%M%S", localtime;
#my $debug = 0;

# how to use
unless ($ARGV[0]){
    print "Usage:\n";
    print "trafficestimate.pl <input_file>\n";
}

# Main
open(OUT,"> ./$ARGV[0].$today");
&analyze;
close(OUT);
exit;

### サブルーチン ###
sub analyze{
    open(IN, $ARGV[0]) or die "$!";
    my $i = 0;
    my $start = 0;
    while(<IN>){
        my @line = split(/\t/, $_);

	if ($i < $start){
	    $i++;
	    next;
	}
        if ($line[0] =~ /id/){
            print OUT chomp($_);
            print OUT "\tAlexaRank\n";
	    $i++;
            next;
        }
#	print $line[6]."\n";
	my $uri = URI->new("http://www.trafficestimate.com/$line[6]");
	my $scraper = scraper {
            process '//*[@id="ctl00_cphMainContent_tcAlexaRank"]', 'rank[]' => 'TEXT';
	};
	my $result;
	my $rank;
        eval {$result = $scraper->scrape($uri)};
	
        unless($@){	
	    $rank = $result->{rank}[0];
            print "$rank\n";
	}
	chomp($_);
        print OUT $_."\t$rank\n";
        $i++;
    }
}

