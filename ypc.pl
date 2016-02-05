#!/usr/bin/env perl -w

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

my @cate_id = ('Arts');
my @site_id = ();

my %cate_count;
my %site_count;

my %url = ();
my %site = ();
my %site_text = ();
my %category = ();

### Main ###
foreach(@cate_id){
    my (@cate_id_tmp) = &analyze_list($_, 1);
    foreach(@cate_id_tmp){
	if(!$cate_count{$_}){
	    push(@cate_id,$_);
	    $cate_count{$_}++;
	}
    }
    print "CATE No.:".$#cate_id."\n";
    print "SITE No.:".$#site_id."\n";

#    if ($#cate_id > 100){
#	last;
#    }
}

open(OUT,"> ./ypc.csv.${today}");
print OUT encode('utf-8',"No\tID\tCATEGORY\tSITE_NAME\tURL\tSITE_TEXT\n");
foreach (@site_id){
    print OUT $i."\t".$_."\t".encode('utf-8',$category{$_})."\t".encode('utf-8',$site{$_})."\t".encode('utf-8',$url{$_})."\t".encode('utf-8',$site_text{$_})."\n";
    $i++;
}
close(OUT);
exit;

### サブルーチン ###
sub analyze_list{
    my $cate_id = $_[0];
    my $flag = $_[1];
    my $scraper;
    my @cate_id;

    print STDERR "\#\#\# Reading Page \#\#\#\n";

    my $uri = URI->new("http://dir.yahoo.co.jp/$cate_id");

    if($cate_id eq ""){
	$scraper = scraper {
	    process '//*/dl/dt','list[]' => 'HTML';
	};
    }
    else{
	$scraper = scraper {
	    process '//*[@id="deepdir"]/div/ul/li', 'list[]' => 'HTML';
            process '//*[@id="deepdir"]/div/ul/li','list2[]' => '@class';
	    process '//*[@id="rgsite"]/table/tr/td','list3[]' => 'HTML';
	    process '//*[@id="breadcrumb"]','cate' => 'TEXT';
	    process '//*[@id="cat_head"]/h1','cate2' => 'TEXT';
	    process '//*[@id="wrdflt"]/div[1]/table/tr/td/a','url[]' => '@href';
	    process '//*[@id="wrdflt"]/div[2]/a', 'url2[]' => '@href';
	};
	
    }    
    my $result = $scraper->scrape($uri);

    if($cate_id eq ""){
	for(my $i=0;;$i++){
	    if($result->{list}[$i] && $result->{list}[$i] =~ /dir\.yahoo\.co\.jp\/(.+)\/\?q\=/){
		push(@cate_id,$1);
	    }
	    else{
		last;
	    }
	}
    }

    else{
	for(my $i=0; ;$i++){
	    if($result->{list}[$i] && $result->{list2}[$i] =~ /folder/ && $result->{list}[$i] =~ /dir\.yahoo\.co\.jp\/(.+)\/\?q\=/){
		push(@cate_id,$1);
		print "1.CATE:".encode('utf-8',$1)."\n";
	    }
	    elsif(!$result->{list}[$i]){
		last;
	    }

	}

	for(my $i=0; ;$i++){
	    if($result->{list3}[$i] && $result->{list3}[$i] =~ /\/RU=(\w+)-*\&apos\;\)\;\">(.+)<\/a>.*<\/p><p class=\"site_url\">(.+?)(<\/p><p class=\"propagation\">.+)?<\/p><p class=\"site_text\">\s*(.+)\s*<\/p><p class=\"new_window\">/){
		my $id        = $1;
		my $site      = $2;
		my $url       = $3;
		my $site_text = $5;

		if($id && !$site_count{$id}){
		    push(@site_id,$id);
		    $site_count{$id}++;

                    $url{$id} = $url;
		    $site{$id} = $site;
		    
		    $site_text{$id} = $site_text;
		    $category{$id} = $result->{cate}.$result->{cate2};
		    $category{$id} =~ s/\s//g;
		    
		    print "2.CATE:".encode('utf-8',$category{$id})."\n";			
		    print "2.SITE_ID:".$id."\n";
		    print "2.SITE_TEXT:".encode('utf-8',$site_text{$id})."\n";
		}

	    }
	    elsif(!$result->{list3}[$i]){
		last;
	    }
	}

	for(my $i=0; ;$i++){
	    print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
	    if($flag == 1 && $result->{url}[$i] && $result->{url}[$i] =~ /dir\.yahoo\.co\.jp\/(.+)/){
		print "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n";
		print $1."\n";
		my (@cate_id_tmp) = &analyze_list($1, 0);
		foreach(@cate_id_tmp){
		    if(!$cate_count{$_}){
			push(@cate_id,$_);
			$cate_count{$_}++;
		    }
		}
		print "4.CATE No.:".$#cate_id."\n";
		print "4.SITE No.:".$#site_id."\n";
	    }
	    elsif(!$result->{url}[$i]){
		last;
	    }
	}

	for(my $i=0; ;$i++){
	    print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
	    if($flag == 1 && $result->{url2}[$i] && $result->{url2}[$i] =~ /dir\.yahoo\.co\.jp\/(.+)/){
		print "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB\n";
		print $1."\n";
		my (@cate_id_tmp) = &analyze_list($1, 0);
		foreach(@cate_id_tmp){
		    if(!$cate_count{$_}){
			push(@cate_id,$_);
			$cate_count{$_}++;
		    }
		}
		print "5.CATE No.:".$#cate_id."\n";
		print "5.SITE No.:".$#site_id."\n";
	    }
	    elsif(!$result->{url2}[$i]){
		last;
	    }
	}
    }
    return(@cate_id);
}

