ufw:
  pkg.installed

ufw allow 22/tcp; ufw enable:
  cmd.run:
    - unless: "ufw status verbose | grep '22/tcp'"

ufw allow 80/tcp; ufw enable:
  cmd.run:
    - unless: "ufw status verbose | grep '80/tcp'"
