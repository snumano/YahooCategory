#!/usr/bin/env perl -w
#use strict;
#use warnings;

# find AS number
# created by snumano 2010/11/24
# revised by snumano 2011/01/28

# CPANより下記ライブラリをinstall
use Net::DNS;
use Term::ReadKey;
use LWP::UserAgent;
use HTTP::Request;
#use WWW::Mechanize;
use Web::Scraper;
use Jcode;
use Encode;
#use DBI;
#use DBI qw(:utils);
use POSIX qw(strftime);
use Data::Dumper;

### init ###
#my $hosting = "Nippon+RAD+Inc.";
#my $page;     # 全アプリ表示ページ　カウント用
#my $max_page = 240; 

#my $flag_page;# 全アプリ表示ページ用flag。ページにアプリ情報が記載されていれば真、情報が記載されていなければ偽とする。

#my ($id,$pw); # ID,PW

=pod
my @id_list;  # Appli IDを格納するリスト
my %app_name; # Appli Nameハッシュ配列。Key:Appli ID,Value:Appli Name
my %category; # Appli Categoryハッシュ配列。Key:Appli ID,Value:Category
my %category2;
my %sap;      # SAP名(提供会社)ハッシュ配列。Key:Appli ID,Value:SAP名
my %user;     # Appli利用者数ハッシュ配列。Key:Appli ID,Value:Appli利用者数
my %host;     # Host名ハッシュ配列。Key:Appli ID,Value:Host名
my %addr;     # IP Addressハッシュ配列。Key:Appli ID,IP Address(複数ある場合は1つ目のみ)
my %count_addr;  # IP Address数ハッシュ配列。Key:Appli ID,Value:IP Address数
my %company_name;# NW事業者ハッシュ配列。Key:Appli ID,Value:NW事業者
my %as;       # AS番号ハッシュ配列。Key:Appli ID,Value:AS番号
my %release_date;

my $key;
my $i = 1;
=cut

#my $mech = WWW::Mechanize->new(autocheck => 0);
#$mech->cookie_jar(HTTP::Cookies->new());
#$mech->default_header('Accept-Language'=> "en-us,en;q=0.7,ja;q=0.3" );
#$mech->agent_alias('Linux Mozilla');

my $today = strftime "%Y%m%d%H%M%S", localtime;

#my $debug = 0;


# how to use
unless ($ARGV[0]){
    print "Usage:\n";
    print "find_as.pl <input_file>\n";
}


# Main
open(OUT,"> ./ASNumber/$ARGV[0]");
print OUT "No\tID\tCATEGORY\tSITE_NAME\tURL\tSITE_TEXT\tHOST\tIP\tAS_NUMBER\tAS_COMPANY\tALEXA_RANK\n";
&analyze_list;
close(OUT);

exit;


### サブルーチン ###
sub analyze_list{
    open(IN, $ARGV[0]) or die "$!";
    while(<IN>){
	my($url,$host);
	my ($ip,$count_ip,$as_num,$as_company);
	my @line = split(/\t/, $_);
	if ($line[0] =~ /No/){
	    next;
	}


	$url = $line[4];

	if ($url =~ /(.+?)\/.*/) {
	    $host = $1;
	}
	else{
	    $host = $line[4];
	}

	my $global_rank = &alexa($url);
	($ip,$count_ip,$as_num,$as_company) = &host2as($host);

#	print "$url\t$global_rank\n";
#	print "$host\t$ip\t$count_ip\t$as_num\t$as_company\t$global_rank\n";
	chomp($_);
	print OUT $_."\t$host\t$ip\t$count_ip\t$as_num\t$as_company\t$global_rank\n";
    }
}


sub host2as{
    # DNSを参照して、ホスト名からIPを求める
    my $host = $_[0];
    my ($count_addr,$company_name,$as);
    my @addr;
    
    # ホスト名の文字列確認。www.aaa.jpや100.100.100.100はokだが、wwwのようなshortホスト名はNG
    if($host =~ /\./){          
	my $res2 = Net::DNS::Resolver->new;
	#ホスト名のIPアドレスを取得（DNS Aレコード）


	if($host =~ /\d+\.\d+\.\d+\.\d+/){
	    chomp($host);
	    $addr[0] = $host;
	    ($company_name,$as) = &whois($host); # 事業者名、AS番号
	    $count_addr = 1; # IPアドレス カウント数
	}
	elsif(my $query = $res2->search($host, 'A')){
	    # IPアドレス(Aレコード)を配列(@addr)に格納。IPアドレス複数ある場合を想定
	    @addr = map {$_->address."\n"} grep($_->type eq 'A', $query->answer);
	    # 1番目のIPアドレスに対してwhoisにて事業者名、AS番号を取得。複数IPアドレスの場合でもASは同じと仮定
	    if($addr[0]){
		chomp($addr[0]);
		($company_name,$as) = &whois($addr[0]); # 事業者名、AS番号
		$count_addr = @addr; # IPアドレス カウント数
	    }
	}
    }
    return($addr[0],$count_addr,$as,$company_name);
}

sub whois{
    # JPIRRのwhoisより、IP情報からASを求める
    # 実際には「whois -h jpirr.nic.ad.jp <ip_addr>」を実行し、outputを利用
    my $addr = $_[0];
#    my $whois_out = `/usr/bin/whois -h whois.radb.net $addr`;
    my $whois_out = `/usr/bin/whois -h jpirr.nic.ad.jp $addr`; # whoisサーバをRADBからJPIRRに変更。情報の信頼性向上
    my ($company_name,$as);

    if($whois_out =~ /descr\:\s+(.+)\n(.*\n)*origin\:\s+(\w+)\n/){
	$company_name = $1; # 事業者名
	$as = $3;           # AS番号
    }
    return($company_name,$as);
}


sub alexa{
    my $url = $_[0];
    my $global_rank = '-';

    my $uri = URI->new("http://www.alexa.com/siteinfo/${url}");
    my $scraper = scraper {
	process '//*[@id="traffic-rank-content"]/div/span[2]/div[1]/span/span/div/strong','global_rank' => 'TEXT';
    };

    my $result = $scraper->scrape($uri);
#    print $result->{global_rank}."\n";
    if ($result->{global_rank} && $result->{global_rank} =~ /\d/){
	$global_rank = $result->{global_rank};
	$global_rank =~ s/\s//g;
	$global_rank =~ s/,//g;
    }
    return($global_rank);
}

