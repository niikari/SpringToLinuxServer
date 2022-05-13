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
| Debian 11 x64 | 1 GB Memory | 25 gb | 1 Intel vCPU | Frankfurt |

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

- nginx
- spring-käyttäjän luominen (kotihakemiston luominen)
- java
- maven
- ufw
- spring

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

	$ sudo /srv/salt/nginx
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














