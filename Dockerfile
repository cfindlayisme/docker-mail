#
# Author: Chuck Findlay <chuck@findlayis.me>
# License: LGPL v3.0
FROM alpine:3.16

# ENV variable to use
ENV MAILNAME=smtp.in.example.com

RUN apk add postfix openssl ca-certificates rsyslog sed dovecot

# Make postscren active - does a lot of our filtering. Requires a couple other services too
RUN sed -i '/^smtp      inet*/c\smtp      inet  n       -       n       -       1       postscreen' /etc/postfix/master.cf && \
    sed -i '/^\#dnsblog   unix*/c\dnsblog   unix  -       -       n       -       0       dnsblog' /etc/postfix/master.cf && \
    sed -i '/^#smtpd*/c\smtpd     pass  -       -       n       -       -       smtpd' /etc/postfix/master.cf

# General postfix stuff
RUN sed -i '/smtpd_banner*/c\smtpd_banner = $myhostname ESMTP' /etc/postfix/main.cf && \
    sed -i '/inet_protocols*/c\inet_protocols = ipv4, ipv6' /etc/postfix/main.cf && \
    sed -i '/mynetworks*/c\mynetworks = 127.0.0.0/8 [::0ffff:127.0.0.0]/104 [::1]/128' /etc/postfix/main.cf

# SASL auth related
RUN sed -i '/smtp_sasl_auth_enable*/c\smtp_sasl_auth_enable = yes' /etc/postfix/main.cf && \
    sed -i '/smtp_sasl_security_options*/c\smtp_sasl_security_options = noanonymous' /etc/postfix/main.cf
#    sed -i '/smtp_sasl_password_maps*/c\smtp_sasl_password_maps = lmdb:/etc/postfix/sasl_passwd' /etc/postfix/main.cf && \

# Special SSL settings
RUN echo "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" >> /etc/postfix/main.cf && \
    echo "smtp_tls_secuity_level = may" >> /etc/postfix/main.cf && \
    echo "smtpd_tls_secuity_level = may" >> /etc/postfix/main.cf && \
    echo 'tls_ssl_options = NO_COMPRESSION' >> /etc/postfix/main.cf && \
    echo 'smtp_tls_loglevel = 1' >> /etc/postfix/main.cf && \
    echo 'smtp_tls_exclude_ciphers = aNULL, MD5 , DES, ADH, RC4, PSD, SRP, 3DES, eNULL' >> /etc/postfix/main.cf && \
    echo 'tls_high_cipherlist = TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256:EECDH+AESGCM:ECDHE-RSA-AES256-SHA384' >> /etc/postfix/main.cf && \
    echo 'tls_medium_cipherlist = TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256:EECDH+AESGCM:ECDHE-RSA-AES256-SHA384' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_dh1024_param_file = /config/dh2048.pem' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_dh512_param_file = /config/dh512.pem' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_cert_file=/keys/fullchain.pem' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_key_file=/keys/privkey.pem' >> /etc/postfix/main.cf && \
    echo 'smtp_tls_cert_file=/keys/fullchain.pem' >> /etc/postfix/main.cf && \
    echo 'smtp_tls_key_file=/keys/privkey.pem' >> /etc/postfix/main.cf && \
    echo 'smtp_tls_policy_maps = lmdb:/etc/postfix/conf.d/tls_policy' >> /etc/postfix/main.cf && \
    echo 'smtp_tls_CApath = /etc/ssl/certs/' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_CApath = /etc/ssl/certs/' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_ask_ccert = yes' >> /etc/postfix/main.cf && \
    echo 'smtpd_tls_req_ccert = no' >> /etc/postfix/main.cf && \
    echo "smtpd_tls_received_header = yes" >> /etc/postfix/main.cf && \
    mkdir /etc/postfix/conf.d

# Hash files for access policies
COPY postfix-conf/conf.d/helo_access /etc/postfix/conf.d
COPY postfix-conf/conf.d/sender_access /etc/postfix/conf.d
COPY postfix-conf/conf.d/tls_policy /etc/postfix/conf.d
COPY postfix-conf/conf.d/postscreen_access.cidr /etc/postfix/conf.d
RUN \
    postmap /etc/postfix/conf.d/tls_policy && \
    postmap /etc/postfix/conf.d/helo_access && \
    postmap /etc/postfix/conf.d/sender_access

# Not really used, but blank to quiet it up
RUN \
    echo "" > /etc/postfix/aliases && \
    postmap /etc/postfix/aliases

# The checks to run on the incoming mail - lot of it will be processed by postscreen which is further below
# But, some basic checks are done here that are not very CPU intensive
RUN echo "smtpd_recipient_restrictions = " >> /etc/postfix/main.cf && \
    echo "    permit_sasl_authenticated," >> /etc/postfix/main.cf && \
    echo "    check_helo_access lmdb:/etc/postfix/conf.d/helo_access," >> /etc/postfix/main.cf && \
    echo "    # Has blacklisted senders/domains in it" >> /etc/postfix/main.cf && \
    echo "    check_sender_access lmdb:/etc/postfix/conf.d/sender_access," >> /etc/postfix/main.cf && \
    echo "    # Some stuff to be strict about" >> /etc/postfix/main.cf && \
    echo "    reject_invalid_hostname," >> /etc/postfix/main.cf && \
    echo "    reject_unknown_recipient_domain," >> /etc/postfix/main.cf && \
    echo "    reject_non_fqdn_helo_hostname," >> /etc/postfix/main.cf && \
    echo "    reject_invalid_helo_hostname," >> /etc/postfix/main.cf && \
    echo "    reject_unauth_pipelining," >> /etc/postfix/main.cf && \
    echo "    permit_mynetworks," >> /etc/postfix/main.cf && \
    echo "    reject_unauth_destination," >> /etc/postfix/main.cf && \
    echo "    # Rejects domains under 5 days old" >> /etc/postfix/main.cf && \
    echo "    reject_rhsbl_sender  fresh.spameatingmonkey.net," >> /etc/postfix/main.cf && \
    echo "    reject_rhsbl_client  fresh.spameatingmonkey.net," >> /etc/postfix/main.cf && \
    echo "    permit" >> /etc/postfix/main.cf

# Mostly anti-spam measures - can be a little agressive, but less resource-intensive than spamassassin
# TODO: local DNS caching since this is pretty heavy on DNS lookups
RUN echo "postscreen_access_list = permit_mynetworks, cidr:/etc/postfix/conf.d/postscreen_access.cidr" >> /etc/postfix/main.cf && \
    echo "postscreen_dnsbl_sites =" >> /etc/postfix/main.cf && \
    echo "        zen.spamhaus.org*3" >> /etc/postfix/main.cf && \
    echo "        bl.mailspike.net*2" >> /etc/postfix/main.cf && \
    echo "        b.barracudacentral.org*2" >> /etc/postfix/main.cf && \
    echo "        bl.spameatingmonkey.net" >> /etc/postfix/main.cf && \
    echo "        bl.spamcop.net" >> /etc/postfix/main.cf && \
    echo "        psbl.surriel.com" >> /etc/postfix/main.cf && \
    echo "        swl.spamhaus.org*-4" >> /etc/postfix/main.cf && \
    echo "        list.dnswl.org=127.0.[2..15].0*-2" >> /etc/postfix/main.cf && \
    echo "        list.dnswl.org=127.0.[2..15].1*-3" >> /etc/postfix/main.cf && \
    echo "        list.dnswl.org=127.0.[2..15].[2..3]*-4" >> /etc/postfix/main.cf && \
    echo "        wl.mailspike.net=127.0.0.[17;18]*-1" >> /etc/postfix/main.cf && \
    echo "        wl.mailspike.net=127.0.0.[19;20]*-2" >> /etc/postfix/main.cf && \
    echo "# Postscreen Deep Protocol Tests" >> /etc/postfix/main.cf && \
    echo "postscreen_pipelining_enable = yes" >> /etc/postfix/main.cf && \
    echo "postscreen_pipelining_action = enforce" >> /etc/postfix/main.cf && \
    echo "postscreen_non_smtp_command_enable = yes" >> /etc/postfix/main.cf && \
    echo "postscreen_non_smtp_command_action = drop" >> /etc/postfix/main.cf && \
    echo "postscreen_bare_newline_enable = yes" >> /etc/postfix/main.cf && \
    echo "postscreen_bare_newline_action = ignore" >> /etc/postfix/main.cf && \
    echo "postscreen_greet_banner = Are you going to speak to me in a cockney accent?" >> /etc/postfix/main.cf && \
    echo "postscreen_blacklist_action = drop" >> /etc/postfix/main.cf && \
    echo "postscreen_dnsbl_action = enforce" >> /etc/postfix/main.cf && \
    echo "postscreen_greet_action = enforce" >> /etc/postfix/main.cf && \
    echo "postscreen_dnsbl_threshold = 3" >> /etc/postfix/main.cf && \
    echo "postscreen_dnsbl_whitelist_threshold = -1" >> /etc/postfix/main.cf && \
    echo "postscreen_helo_required = \$smtpd_helo_required" >> /etc/postfix/main.cf && \
    echo "postscreen_tls_security_level = \$smtpd_tls_security_level" >> /etc/postfix/main.cf && \
    echo "postscreen_use_tls = \$smtpd_use_tls" >> /etc/postfix/main.cf && \
    echo "postscreen_client_connection_count_limit = \$smtpd_client_connection_count_limit" >> /etc/postfix/main.cf

# vmail stuff - for the virtual mailboxes
# TODO: gid/uid map needs to be adjusted on container bootup via env variable or such
RUN \
    echo "home_mailbox = Maildir/" >> /etc/postfix/main.cf && \
    echo "virtual_alias_maps = lmdb:/etc/postfix/valiases" >> /etc/postfix/main.cf && \
    echo "virtual_mailbox_domains = lmdb:/etc/postfix/vhosts" >> /etc/postfix/main.cf && \
    mkdir /vmail && \
    echo "virtual_mailbox_base = /vmail" >> /etc/postfix/main.cf && \
    echo "virtual_mailbox_maps = lmdb:/etc/postfix/vmaps" >> /etc/postfix/main.cf && \
    echo "virtual_minimum_uid = 1000" >> /etc/postfix/main.cf && \
    echo "virtual_uid_maps = static:1000" >> /etc/postfix/main.cf && \
    echo "virtual_gid_maps = static:1000" >> /etc/postfix/main.cf

COPY dovecot-conf /etc/dovecotS

EXPOSE 25
EXPOSE 587
EXPOSE 993

COPY start.sh /usr/bin

CMD /usr/bin/start.sh