## Java Spring Boot -sovelluksen julkaisu Linux palvelimelle koodina

| ![image](https://github.com/niikari/SpringToLinuxServer/blob/main/photos/lopputulos.JPG?raw=true) |
|:--:|
| *Lopputulos* |

# Käytössä ollut laitteisto

Loin itselleni tilin Digital Oceaniin ja tämän jälkeen loin kaksi "droplettia" (virtuaalikonetta). 

| Distro | Muisti | Prosessori | Tallennustila | Sijainti |
| --- | --- | --- | --- | --- |
| Debian 11 x64 | 1 GB Memory | 25 gb | 1 Intel vCPU | Frankfurt |

Nimesin koneet antamalla toiselle tagin "master" ja toiselle "minion".

# Root käyttäjien "poistaminen" käytöstä

Aloitin molempien koneiden osalta konfiguroinnin samalla tavalla, Tero Karvisen kotisivuilta löytämiltäni ohjeilta ![First steps on a new virtual private server](https://terokarvinen.com/2017/first-steps-on-a-new-virtual-private-server-an-example-on-digitalocean/?fromSearch=server).

Ensin asensin palomuurin

	$ sudo apt-get install ufw

Ja tämän jälkeen tein "reiän" ssh-yhteyden mahdollistamiseksi

	$ sudo ufw allow 22/tcp

Lopuksi aktivoin palomuurin

	$ sudo ufw enable

Tämän jälkeen loin molemmille saman nimisen käyttäjän ja annoin käyttäjälle tarvittavat oikeudet

	$ sudo adduser niiles
	$ sudo adduser niiles sudo
	$ sudo adduser niiles adm

Lopuksi estin root-käyttäjän mahdollisuuden kirjautua palvelimelle

	$ sudo usermod --lock root
	$ sudoedit /etc/ssh/sshd_config
	  PermitRootLogin no

Kirjauduin uudelleen koneille juuri luomallani käyttäjällä: "niiles"




