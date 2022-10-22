#!/bin/sh
#
# Author: Chuck Findlay <chuck@findlayis.me>
# License: LGPL v3.0

if [ ! -f /etc/postfix/dh2048.pem ]; then
    openssl dhparam -out /etc/postfix/dh2048.pem 2048
fi

if [ ! -f /etc/postfix/dh512.pem ]; then
    openssl dhparam -out /etc/postfix/dh512.pem 512
fi

# TODO: Won't change it properly if enviorment variable changes - should correct this so container doesn't need to be destroyed every time
sed -i "/myhostname = host.domain.tld*/c\myhostname = $MAILNAME" /etc/postfix/main.cf
echo $MAILNAME > /etc/mailname

rsyslogd
postfix start

tail -f /var/log/mail.log