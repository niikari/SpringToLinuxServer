## Java Spring Boot -sovelluksen julkaisu Linux palvelimelle koodina

Projektin tarkoituksena on helpottaa Java Spring Boot (tässä tapauksessa maven) sovelluksen viemistä Linux
palvelimelle. Testattava ohjelma on luotu Haaga-Helian tietojenkäsittely tradenomitutkinnon yhteydessä kurssilla
"Palvelinohjelmointi". 

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/lopputulos.JPG?raw=true) |
|:--:|
| *Lopputulos* |

Lopputuloksena nähty sovellus saadaan pyörimään Linux palvelimella vain muutamalla komennolla ja tämän jälkeen
palvelun sijaintia voidaan vaihtaa (mikäli palveluntarjoajan ehdot / hinta ei miellytä) helposti vain muutamassa
minuutissa. Projektin lopputulosta voi käyttää hyväksi minkä tahansa Java Spring Boot Maven sovelluksen kanssa 
muuttamalla vain paria kohtaa "infran koodissa".

# Käytössä ollut laitteisto

Loin itselleni tilin Digital Oceaniin ja tämän jälkeen loin kaksi "droplettia" (virtuaalikonetta). 

| Distro | Muisti | Prosessori | Tallennustila | Sijainti |
| --- | --- | --- | --- | --- |
| Debian 11 x64 | 1 GB Memory | 1 Intel vCPU | 25 gb | Frankfurt |

Nimesin koneet antamalla toiselle tagin "master" ja toiselle "minion".

# Root käyttäjien "poistaminen" käytöstä

Aloitin molempien koneiden osalta konfiguroinnin samalla tavalla, Tero Karvisen kotisivuilta löytämilläni ohjeilla [First steps on a new virtual private server](https://terokarvinen.com/2017/first-steps-on-a-new-virtual-private-server-an-example-on-digitalocean/?fromSearch=server).

Ensin asensin palomuurin

	$ sudo apt-get install ufw

Ja tämän jälkeen tein "reiän" ssh-yhteyden mahdollistamiseksi

	$ sudo ufw allow 22/tcp

Lopuksi aktivoin palomuurin

	$ sudo ufw enable

Tämän jälkeen loin molemmille saman nimisen käyttäjän,  annoin käyttäjälle tarvittavat oikeudet ja kirjauduin sisään
ssh-yhteydellä

	$ sudo adduser niiles
	$ sudo adduser niiles sudo
	$ sudo adduser niiles adm
	$ ssh niiles@*koneen_nimi*

Lopuksi estin root-käyttäjän mahdollisuuden kirjautua palvelimelle ja käynnistin ssh.servicen uudelleen

	$ sudo usermod --lock root
	$ sudoedit /etc/ssh/sshd_config
	  PermitRootLogin no
	$ sudo systemctl restart ssh.service

Kirjauduin uudelleen koneille juuri luomallani käyttäjällä: "niiles"

# Herra / orja arkkitehtuuri käyttämällä Salttia

Aloitin tekemällä ensimmäisestä (tag: "master") Herra -koneen. Aloitin päivittämällä paketinhallinnan

	$ sudo apt-get update
	$ sudo apt-get upgrade

Tämän jälkeen asensin koneelle salt-masterin ([Salt Projektin dokumetaatio](https://docs.saltproject.io/en/latest/))

	$ sudo apt-get install salt-master

Tämän jälkeen tarkistin version

	$ salt-master --version
	  salt-master 3002.6	  
	  
Vielä piti avata "reiät" palomuuriin Saltille (portit 4505, 4506)

	$ sudo ufw allow 4505/tcp
	$ sudo ufw allow 4506/tcp

Siirryin seuraavalle koneelle (tag: "minion") ja lähdin tekemään tästä orjaa. Aloitin päivittämällä paketinhallinnan
ja tämän jälkeen asensin koneelle salt-minionin

	$ sudo apt-get install salt-minion

Ja tarkastin jälleen version

	$ salt-minion --version
	  salt-minion 3002.6

Master version tulee olla joko uudempi tai sama kuin orjien, jotta kaikki toimisi jatkossa.

Tämän jälkeen katsoin master-koneen ip-osoitteen komennolla

	$ hostname -I

Tallensin tämän osoitteen leikepöydälle ja siirryin takaisin orja-koneelle. Muokkasin salt-minionin konfigurointitiedostoa
ja kerroin mistä ip-osoitteesta se löytää masterin ja käynnistin palvelun uudelleen (jotta ottaa konfigurointitiedston
uuden sisällön käyttöön)

	$ sudo nano /etc/salt/minion
	  master: *masterin ip-osoite*
	$ sudo systemctl restart salt-minion.service

Lopuksi tarkistin, että palvelu toimii

	$ sudo systemctl status salt-minion.service

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/minion.service.JPG?raw=true) |
| :--: |
| *Salt-minion.service käynnissä oikein* |

Tämän jälkeen master -koneen piti vielä hyväksyä orja komennettavaksi

	$ sudo salt-key -A
	  yes

	$ sudo salt-key

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/minion.key%20accepted.JPG?raw=true) |
| :--: |
| *Orja kone löytyy hyväksyttyjen avainten listalta* |

Testasin vielä, että herra todella voi komentaa orjaa kahdella tavalla. Luomalla tilan "Helloworld" ja lähettämällä
käskyn tulostaa ruudulle heimaailma.

# Infran laittaminen kuntoon

Ohjelmat, jotka tässä projektissa asennetaan ja asetukset, joita muutetaan on kuvattu salt "tilojen" kansioissa:

*Nginx*

Konfiguraatiotiedoston sisältö (java-app.conf), sijaitsee /srv/salt/nginx

```
server {
        listen 80;
        listen [::]:80;

        server_name 134.209.252.108;

        location / {
             proxy_pass http://localhost:8080/;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_set_header X-Forwarded-Proto $scheme;
             proxy_set_header X-Forwarded-Port $server_port;
        }
}
```

Asennetaan Nginx, asetetaan konfiguraatio-tiedoston sisältö ja käynnistetään nginx

```
nginx:
  pkg.installed

/etc/nginx/conf.d/java-app.conf:
  file.managed:
    - source: salt://nginx/java-app.conf

nginx.service:
  service.running:
    - watch:
      - file: /etc/nginx/conf.d/java-app.conf
```

*spring-käyttäjän luominen (kotihakemiston luominen)*

```
spring:
  user.present:
    - fullname: Spring Project User
    - home: /home/spring
```

*Javan sekä mavenin asentaminen*

```
openjdk-11-jre:
  pkg.installed

maven:
  pkg.installed
```

*Palomuurin asentaminen (portti 22 ja 80 auki)*

```
ufw:
  pkg.installed

ufw allow 22/tcp; ufw enable:
  cmd.run:
    - unless: "ufw status verbose | grep '22/tcp'"

ufw allow 80/tcp; ufw enable:
  cmd.run:
    - unless: "ufw status verbose | grep '80/tcp'"
```

*Gitin lataaminen ja sovelluksen kloonaaminen GitHubista spring-käyttäjän kotihakemistoon*

```
git:
  pkg.installed

cd /home/spring;git clone https://github.com/niikari/autonlampimaksi.git:
  cmd.run:
    - unless: "ls /home/spring/autonlampimaksi | grep 'pom.xml'"


```

*Spring sovellus*

Luodaan sovelluksesta ensin palvelu (daemon) -> tiedosto /srv/salt/spring/autolampimaksi.service

```
[Unit]
Description=Spring Boot Autolampimaksi
After=syslog.target
After=network.target[Service]
User=spring
Type=simple

[Service]
ExecStart=/usr/bin/java -jar /home/spring/autonlampimaksi/target/autonlampimaksi-0.0.1-SNAPSHOT.jar                         >
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=autolampimaksi

[Install]
WantedBy=multi-user.target
```

Käynnistetään palvelu (portti 80)

```
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


```

*top.sls tiedostossa määritellään missä järjestyksessä nämä tehdään*

```
base:
  '*':
    - ufw
    - nginx
    - adduser
    - git
    - javamaven
    - spring
```

Salt aloittaa asentamalla tarvittaessa palomuurin ja tarkastaa, että portti 80 on auki. Tämän jälkeen asennetaan
nginx ja muutetaan konfiguraatiota (Reverse Proxy -> yhteys porttiin 80 ohjataan localhost:8080). Sitten luodaan
uusi käyttäjä (spring) sekä tälle kotikansio. Tämän jälkeen asennetaan git ja kloonataan ohjelmakoodi GitHubista.
Lopuksi asennetaan java sekä maven -> tehdään ohjelmakoodista suoritettava .jar tiedosto -> tehdään tästä ajettava
palvelu palvelimelle ja käynnistetään palvelu.

Kaikki komennon toteutaan vain, jos tarvitaan (idempotentti). Eli muutoksia ei tehdä, jos muutoksia ei ole.

*Ennen* tilan suorittamista on tarkistettava orja -koneen ip osoite ja laitettava se talteen leikepöydälle

	$ hostname -I

*Tämän jälkeen siirrytään master -koneelle*

Kopioidaan tämän repositorion sisältö /srv/salt.

Laitetaan orjan ip-osoite nginx/java-app.conf -tiedostoon

	$ sudo nano /srv/salt/nginx/java-app.conf
	  server_name *ip-osoite*;

Lopuksi suoritetaan tila

	$ sudo salt '*' state.apply

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/ensimmainen%20suoritus.JPG?raw=true) |
| :--: |
| *Ensimmäinen suoritus (lopputulos)* |

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/toinen%20suoritus.JPG?raw=true) |
| :--: |
| *Seuraavat suoritukset (lopputulos)* |

Avaa selaimella orjan ip-osoite

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/lopputulos.JPG?raw=true) |
| :--: |
| *Orjalla näkyvä palvelu saavutettavissa* |

Pienillä muutoksilla on mahdollista julkaista mikä tahansa Java Spring Boot sovellus tämän koodin avulla.














