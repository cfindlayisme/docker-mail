Work in progress, intended as my backup if gmail ever went to crap. (November 2022)

Volumes:
- /config
  - vmaps
    - Format is email@domain \<TAB\> domain/email/
      - Trailing / is very important for Maildir style
  - vhosts
    - Format is DOMAIN \<TAB\> OK
- /keys
  - TODO: document this
- /vmail
  - Holds the actual virtual mailboxes
  - TODO: Fix it so it's not static UID/GID of 1000