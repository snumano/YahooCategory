#!/usr/bin/perl -w

# created by snumano 2011/06/04

# Usage:
# ypc.pl

use strict;
use warnings;
use utf8;

# CPANより下記ライブラリをinstall
use Net::DNS;
use Term::ReadKey;
use Web::Scraper;
use URI;
use Jcode;
use Encode;
use POSIX qw(strftime);
use Data::Dumper;

### init ###

my $today = strftime "%Y%m%d%H%M%S", localtime;
my $debug = 0;
my $i = 1;

my @cate_id = ('Society_and_Culture');
my @site_id = ();

my %cate_count;
my %site_count;

my %site_info = ();
my %category = ();

### Main ###
foreach(@cate_id){
    my (@cate_id_tmp) = &analyze_list($_);
    foreach(@cate_id_tmp){
	if(!$cate_count{$_}){
	    push(@cate_id,$_);
	    $cate_count{$_}++;
	}
    }
    print "CATE No.:".$#cate_id."\n";
    print "SITE No.:".$#site_id."\n";

}

open(OUT,"> ./ypc.csv");
print OUT encode('utf-8',"No\tID\tCategory\tSite\tURL\tFQDN\tComment\n");

foreach (@site_id){
    my $site = '';
    my $url = '';
    my $host = '';
    my $comment = '';
    my $koushiki_imode = '';

    if($site_info{$_} =~ /(http\:\/\/\S+?)\".+\;\"\>(.+?)\<\/a\>.+abstr\"\>(.+?)\<\/span\>/){
	$url = $1;
	$site = $2;
	$comment = $3;
	$url =~ s/\%3A/\:/;
	$url =~ s/\%2F/\//g;
	if($url =~ /http\:\/\/(.+?)\//){
	    $host = $1;
	}
    }
#    print Dumper($host);

    print OUT $i."\t".$_."\t".encode('utf-8',$category{$_})."\t".encode('utf-8',$site)."\t".$url."\t".$host."\t".encode('utf-8',$comment)."\n";
    $i++;
}

close(OUT);

exit;



### サブルーチン ###
sub analyze_list{
    my $cate_id = $_[0];
    my $scraper;
    my @cate_id;

    print STDERR "\#\#\# Reading Page \#\#\#\n";

    my $uri = URI->new("http://dir.yahoo.co.jp/$cate_id");

    if($cate_id eq ""){
	$scraper = scraper {
	    process '/html/body/div[5]/div/div/div/div/ul/li/span','list[]' => 'HTML';
	};
    }
    else{
	$scraper = scraper {
	    process '/html/body/div[5]/div/div/div/div[2]/ul/li/span','list[]' => 'HTML';
	    process '/html/body/div[5]/div/div/div[3]/ul/li','list2[]' => 'HTML';
	    process '/html/body/div[4]/h2','cate' => 'TEXT';
	    process '/html/body/div[4]/h1','cate2' => 'TEXT';
	};
	
    }
    
    my $result = $scraper->scrape($uri);

    if($cate_id eq ""){
	for(my $i=0;;$i++){
	    if($result->{list}[$i] && $result->{list}[$i] =~ /dir\.yahoo\.co\.jp\/(.+?)\?q\=/){
#		print Dumper($1);
		push(@cate_id,$1);
	    }
	    else{
		last;
	    }
	}
    }
    else{
	for(my $i=0; ;$i++){
#	    print "i:".$i."\n";
#	    print encode('utf-8',$result->{list}[$i])."\n";
	    if($result->{list}[$i] && $result->{list}[$i] =~ /dir\.yahoo\.co\.jp\/(.+?)\?q\=/){
		push(@cate_id,$1);
		print "1.CATE:".$1."\n";
	    }
	    elsif(!$result->{list}[$i]){
		last;
	    }

	}
	for(my $i=0; ;$i++){
	    if($result->{list2}[$i] && $result->{list2}[$i] =~ /a\shref\=\"(http.+)$/){
		my $site_info_tmp = $1;
		if($site_info_tmp =~ /sig\=(\w+?)\&amp/){
		    my $id = $1;
#		    print "SITE:".$id."\n";
		    if($id && !$site_count{$id}){
			push(@site_id,$id);
			$site_count{$id}++;
			
			$site_info{$id} = $site_info_tmp;
			$category{$id} = $result->{cate}.$result->{cate2};
			$category{$id} =~ s/\s//g;
			
			print "2.CATE:".encode('utf-8',$category{$id})."\n";			
			print "2.SITE_ID:".$id."\n";
			print "2.INFO:".encode('utf-8',$site_info{$id})."\n";
		    }
		}

	    }
	    elsif(!$result->{list2}[$i]){
		last;
	    }
	}
    }
    return(@cate_id);
}
