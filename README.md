# YahooCategory

## 動作環境

* Perl5
 * Perl5.22.1で動作確認済

## 事前準備
### Ubuntu 14.04の場合

* make, gccをinstall

```
apt-get install make gcc
```

* cpanmをinstall
 * 手順は[こちら](https://github.com/miyagawa/cpanminus)を参照

* 必要なライブラリをinstall

```
cpanm Net::DNS Web::Scraper Jcode
```

* 実行

```
./ypc.pl
```