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
    print "similarweb.pl <input_file>\n";
}

# Main
open(OUT,"> ./$ARGV[0].$today");
&alexa;
close(OUT);
exit;

### サブルーチン ###
sub alexa{
    open(IN, $ARGV[0]) or die "$!";
#    my $i = 1;
    while(<IN>){
        my @line = split(/\t/, $_);

        if ($line[0] =~ /id/){
            print OUT chomp($_)."\tGlobalRank\tCountry\tCountryRank\n";
            next;
        }
#	print $line[6]."\n";
#	print "http://www.alexa.com/siteinfo/$line[6]\n";
	my $uri = URI->new("http://www.alexa.com/siteinfo/$line[6]");
	my $scraper = scraper {
            process '//*[@id="rank-panel"]/header/span[1]/div/h4/span', 'hostname[]' => 'TEXT';
            process '//*[@id="traffic-rank-content"]/div/span[2]/div[1]/span/span/div/strong','globalrank[]' => 'TEXT';
            process '//*[@id="traffic-rank-content"]/div/span[2]/div[2]/span/span/h4/a', 'country[]' => 'TEXT';
            process '//*[@id="traffic-rank-content"]/div/span[2]/div[2]/span/span/div/strong', 'countryrank[]' => 'TEXT';
	};
	my $result = $scraper->scrape($uri);

	my $hostname = $result->{hostname}[0];
	$hostname =~ s/How popular is (.*)\?/$1/;
	my $global_rank = $result->{globalrank}[0];
	$global_rank =~ s/[\s,]//g;
	my $country = $result->{country}[0];
	my $country_rank = $result->{countryrank}[0];
	$country_rank =~ s/[\s,]//g;

#        print "$hostname\n";
#        print "$global_rank\n";
#        print "$country\n";
#        print "$country_rank\n";
	
	chomp($_);
#        print $_."\t$hostname\t$global_rank\t$country\t$country_rank\n";
        print OUT $_."\t$hostname\t$global_rank\t$country\t$country_rank\n";
#        $i++;
    }
}

