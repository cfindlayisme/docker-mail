#!/bin/sh
#
# Author: Chuck Findlay <chuck@findlayis.me>
# License: LGPL v3.0
echo "Generating dhparam keys (if needed)"

if [ ! -f /keys/dh2048.pem ]; then
    openssl dhparam -out /keys/dh2048.pem 2048
fi

if [ ! -f /keys/dh512.pem ]; then
    openssl dhparam -out /keys/dh512.pem 512
fi

# TODO: Won't change it properly if enviorment variable changes - should correct this so container doesn't need to be destroyed every time
sed -i "/myhostname = host.domain.tld*/c\myhostname = $MAILNAME" /etc/postfix/main.cf
echo $MAILNAME > /etc/mailname

echo "Creating hashmaps for postfix"
cp /config/vhosts /etc/postfix/vhosts
cp /config/vmaps /etc/postfix/vmaps
cp /config/valiases /etc/postfix/valiases
postmap /etc/postfix/vmaps
postmap /etc/postfix/vhosts
postmap /etc/postfix/valiases

echo "Copying over dovecot user & passwords"
cp /config/dovecot-users /etc/dovecot/dovecot-users
cp /config/dovecot-passwd /etc/dovecot/dovecot-passwd

echo "Starting rsyslog"
rsyslogd

echo "Starting dovecot"
dovecot

echo "Starting postfix"
postfix start

tail -f /var/log/mail.log