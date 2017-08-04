#!/bin/bash
## Apache 2.0
cd /install
tar xvfz httpd-2.0.49.tar.gz
cd httpd-2.0.49
#	--with-mpm=perchild \
#	--enable-suexec \
#	--enable-suexec-caller=nobody \
#	--with-suexec-docroot=/www \
#	--with-suexec-logfile=/apache/logs/suexec.log
./configure \
        --prefix=/apache \
	--with-mpm=prefork \
	--enable-access=shared \
	--enable-actions=shared \
	--enable-alias \
	--enable-asis=shared \
	--enable-auth-anon=shared \
	--enable-auth=shared \
	--enable-autoindex \
	--enable-cache=shared \
	--enable-cgi \
	--enable-cgid=shared \
	--enable-dir \
	--enable-dav=shared \
	--enable-dav_fs=shared \
	--enable-deflate=shared \
	--enable-disk-cache=shared \
	--enable-env \
	--enable-expires=shared \
	--enable-file-cache=shared \
	--enable-headers=shared \
	--enable-imap=shared \
	--enable-include=shared \
	--enable-info=shared \
	--enable-log-config \
	--enable-logio \
	--enable-mem-cache=shared \
	--enable-mime \
	--enable-mime-magic=shared \
	--enable-negotiation=shared \
	--enable-proxy-connect=shared \
	--enable-proxy-ftp=shared \
	--enable-proxy-http=shared \
	--enable-proxy=shared \
	--enable-rewrite=shared \
	--enable-setenvif \
	--enable-so \
	--enable-speling=shared \
	--enable-ssl=shared \
	--enable-status=shared \
	--enable-unique-id=shared \
	--enable-usertrack=shared \
	--enable-vhosts-alias \
	--disable-auth-dbm \
	--disable-auth-digest \
	--disable-auth-ldap \
	--disable-cern-meta \
	--disable-charset-lite \
	--disable-echo \
	--disable-example \
	--disable-isapi \
	--disable-ldap \
	--disable-suexec \
	--disable-userdir \

make
make install

exit;

## FastCGI
cd /install
tar xvfz mod_fastcgi-2.4.2.tar.gz
cd mod_fastcgi-2.4.2
cp Makefile.AP2 Makefile
make top_dir=/apache
make top_dir=/apache install

## mod_perl
cd /install
tar xvfz mod_perl-2.0-current.tar.gz
cd mod_perl-1.99_13
perl Makefile.PL MP_APXS=/apache/bin/apxs
make
make test
make install

## PHP
cd /install
tar xvfz php-4.3.4.tar.gz
cd php-4.3.4
./configure \
	--with-apxs2=/apache/bin/apxs \
	--with-mysql
make
make install

## GeoIP
cd GeoIP-1.3.1/
./configure
make -s install

## mod_geoip
apxs -i -a -L/usr/local/lib -I/usr/local/include -lGeoIP -c mod_geoip.c

