Work in progress, intended to switch over to it eventually.

Trying to keep resources low on it so it will not require much. and minimal configuration so that disaster recovery is easy peasy.

Configured setup to not require SQL database since it's only really for a small amount of users.

Some more TODO:
- Verify SSL on postfix incoming is good
- Configure postfix outgoing submission service
- Spam mitigation beyond postscreen
- OpenDKIM implementation needs to be added
- Write documentation for /config/dovecot-passwd and /config/dovecot-users

Completed:
- Incoming mail works
- Dovecot IMAP SSL works

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