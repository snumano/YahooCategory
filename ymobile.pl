#!/usr/bin/perl -w

# created by snumano 2011/06/04
# revised by snumano 2011/08/10

# Usage:
# ymobile.pl

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
#use DBI;
#use DBI qw(:utils);
use POSIX qw(strftime);
use Data::Dumper;

### init ###

my $today = strftime "%Y%m%d%H%M%S", localtime;
my $debug = 0;
my $i = 1;

my @cate_id = ('561000364');   # root定義。topからはじめる場合は空にしておく。暫定的に生活と文化(561000364)を定義
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

#&get_siteurl;

open(OUT,"> ./ymobile.csv");
print OUT encode('utf-8',"No\tID\tCategory\tSite\tURL\tFQDN\tComment\tiモード公式\n");

foreach (@site_id){
    my $site = '';
    my $url = '';
    my $host = '';
    my $comment = '';
    my $koushiki_imode = '';

    if($site_info{$_} =~ /(http\%3A\%2F\%2F\S+?)\&amp.+\"\>(.+?)\<\/a\>\<\/strong\>.+abstr\"\>(.+?)\<\/span\>\<\/div\>/){
	$url = $1;
	$site = $2;
	$comment = $3;
	$url =~ s/\%3A/\:/;
	$url =~ s/\%2F/\//g;
	if($url =~ /http\:\/\/(.+?)\//){
	    $host = $1;
	}
    }
    if($site_info{$_} =~ /\[公式\]/){
	$koushiki_imode = '○';
    }
#    print Dumper($host);

    print OUT $i."\t".$_."\t".encode('utf-8',$category{$_})."\t".encode('utf-8',$site)."\t".$url."\t".$host."\t".encode('utf-8',$comment)."\t".encode('utf-8',$koushiki_imode)."\n";
    $i++;
}

close(OUT);

exit;



### サブルーチン ###
sub analyze_list{
    my $cate_id = $_[0];
    my $scraper;
    my @cate_id;
#    my @site_id;

    print STDERR "\#\#\# Reading Page \#\#\#\n";

    my $uri = URI->new("http://view-mobile.dir.yahoo.co.jp/i/$cate_id");

    if($cate_id eq ""){
	$scraper = scraper {
	    process '/html/body/div[4]/div/div/div/dl/dt','list[]' => 'HTML';;
	};
    }
    else{
	$scraper = scraper {
	    process '/html/body/div[4]/div/div/div/dl[2]/dd/ul/li','list[]' => 'HTML';
	    process '/html/body/div[3]/div','cate' => 'TEXT';
	    process '/html/body/div[3]/h1/span','cate2' => '@title';
	};
	
    }
    
    my $result = $scraper->scrape($uri);

    if($cate_id eq ""){
	for(my $i=0;;$i++){
	    if($result->{list}[$i] && $result->{list}[$i] =~ /a\shref\=\"\/i\/(\d+)\/\"/){
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
	    if($result->{list}[$i] && $result->{list}[$i] =~ /http\:\/\/view\-mobile\.dir\.yahoo\.co\.jp\/i\/(\d+)\"/){
		push(@cate_id,$1);
		print "1.CATE:".$1."\n";
	    }

	    if($result->{list}[$i] && $result->{list}[$i] =~ /simulator\?ca\=i\&amp\;url\=(http.+?)$/){
		my $site_info_tmp = $1;
		if($site_info_tmp =~ /sig\=(\w+)\"/){
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
	    if(!$result->{list}[$i]){
		last;
	    }
	}
    }
    return(@cate_id);
}

