git:
  pkg.installed

cd /home/spring;git clone https://github.com/niikari/autonlampimaksi.git:
  cmd.run:
    - unless: "ls /home/spring/autonlampimaksi | grep 'pom.xml'"


