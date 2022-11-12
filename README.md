Work in progress, intended to switch over to it eventually.

Trying to keep resources low on it so it will not require much. and minimal configuration so that disaster recovery is easy peasy.

Configured setup to not require SQL database since it's only really for a small amount of users.

Some more TODO:
- Verify SSL on postfix incoming is good
- Configure postfix outgoing submission service
- Spam mitigation beyond postscreen

Completed:
- Incoming mail works
- Dovecot IMAP SSL works
- Write documentation for /config/dovecot-passwd and /config/dovecot-users

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
  - TODO: document this
- /vmail
  - Holds the actual virtual mailboxes (with trailing / in vmaps should be Maildir format)
  - TODO: Fix it so it's not static UID/GID of 1000