Work in progress, using ProtonMail nowadays so this is more of a backup project in case I ever need to host my own mailserver.

Usual postfix/dovecot stack - nothing fancy. Low on resource usage so I can use tiny VMs to run it.

Looked at IRedmail/mailinabox/mailcow and saw they were all just to big for what I wanted to run them on.

Some more TODO:
- Configure postfix outgoing submission service
- Spam mitigation beyond postscreen
- OpenDKIM implementation needs to be added
- Write documentation for /config/dovecot-passwd and /config/dovecot-users
- Write logs to somewhere persistant
- Address this:
  - postfix/postscreen[142]: warning: connect to private/tlsproxy service: No such file or directory
- Gitlab CI tests to lint config (postconf -n inside container)

Completed:
- Incoming mail works
- Dovecot IMAP SSL works
- Incoming mail SSL works (ie, port 25 STARTTLS)
- dhparam doesn't auto regenerate every launch

Volumes:
- /config
  - vmaps
    - Format is email@domain \<TAB\> domain/email/
      - Trailing / is very important for Maildir style
      - ```user@example.com example.com/user/```
  - vhosts
    - Format is DOMAIN \<TAB\> OK
    - ```example.com  OK```
  - valiases
    - Format is EMAIL \<TAB\> EMAIL
    - ```aliased_email@example.com user@example.com```
- /keys
  - privkey.pem
    - Private key for SSL
  - fullchain.pem
    - Certificate file for SSL
- /vmail
  - Holds the actual virtual mailboxes (with trailing / in vmaps should be Maildir format)
  - TODO: Fix it so it's not static UID/GID of 1000