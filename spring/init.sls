cd /home/spring/autonlampimaksi; mvn clean package:
  cmd.run:
    - unless: "ls -la /home/spring/autonlampimaksi | grep 'target'"

/etc/systemd/system/autolampimaksi.service:
  file.managed:
    - source: salt://spring/autolampimaksi.service

autolampimaksi.service:
  service.running:
    - watch:
      - file: /etc/systemd/system/autolampimaksi.service


