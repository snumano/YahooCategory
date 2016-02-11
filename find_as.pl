#!/usr/bin/env perl -w
#use strict;
#use warnings;

# find AS number
# created by snumano 2016/2/7

# CPANより下記ライブラリをinstall
use Net::DNS;
use Term::ReadKey;
use LWP::UserAgent;
use HTTP::Request;
use Web::Scraper;
use Jcode;
use Encode;
use POSIX qw(strftime);
use Data::Dumper;

my $today = strftime "%Y%m%d%H%M%S", localtime;

# how to use
unless ($ARGV[0]){
    print "Usage:\n";
    print "find_as.pl <input_file>\n";
}

# Main
open(OUT,"> ./ASNumber/$ARGV[0]");
print OUT "id\tyid\tcategory\tsite_name\turl\tsite_text\thost\tip\tcount_ip\tas_number\tas_company\n";
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

#	my $global_rank = &alexa($url);
	($ip,$count_ip,$as_num,$as_company) = &host2as($host);

	chomp($_);
#	print OUT $_."\t$host\t$ip\t$count_ip\t$as_num\t$as_company\t$global_rank\n";
	print OUT $_."\t$host\t$ip\t$count_ip\t$as_num\t$as_company\n";
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

