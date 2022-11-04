Work in progress, intended as my backup if gmail ever went to crap. (November 2022)

Configured setup to not require SQL database since it's only really for a small amount of users.

**Should** be able to deploy with multiple replicas in kubernetes - still need to test this

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
  - Holds the actual virtual mailboxes
  - TODO: Fix it so it's not static UID/GID of 1000