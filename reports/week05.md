Raportti 

Tehtävä 5 Osa1
Osa 1:
Kun tekee "dns.qry.name == "yle.fi"" se hakee dns palvelut joissa esiintyy "yle" ja GeoIp asennuksen jälkeen näkee kuinka väliaikainen ipv6 osoite lähettää global unicastin ja paketti löytyy 2001:998:20::40. Tämän source address on Hanko, Fi, Elisa Oyj.
Capture Filterillä "Tcp port 443". Näkyy sourcen olevan Kerava. Destination Ip menee Amazon.com, Inc ja maana United States.
Display filter frame matches "yle". Löytää karkeasti kaikki missä yle esiintyy. Ylen destination GeoIP:t ovat Amazonilla, joten tämä on palvelun tuottaja. 

1) Dns kyselyn IP-osoite oli "195.148.239.84". TTL aika oli 128. Client hello ehdottaa "TLS 1.0". ja Server Hello antaa "TLS 1.2". 

Tein aluksi ohjeiden mukaisen kontin huomasin, että Zabbix on varannut tämän portin "8080", joten loin oman portin "8888".

Kontin tekeminen
------------------

Käytin komentoja "docker run -d \
  --env AUTH_USER=tllabra \
  --env AUTH_PASS=Qwerty1! \
  -v ~/site:/var/www \
  -p 8888:80 \
  tjarvenpaa/basic_auth".

Tässä docker run -d käynnistää kontin taustalle. "--env AUTH_USER=tllabra" antaa nimeksi tllabra. "--env AUTH_PASS=Qwerty1!" asettaa salasanaksi "Qwerty1!". "-v ~/site:/var/www " Mouttaa WSL hakemiston ~/site kontin sisään polkuun /var/www. Kontti lukee index.html:llän täältä. "-p 8888:80  
Ohjaa host‑koneen portin 8888 kontin porttiin 80. Sivu avataan "http://localhost:8888/". "tjarvenpaa/basic_auth" on docker image, jossa on basic auth toiminta. Kontin poisto onnistuu halutessa komennoilla docker rm <id>. 

Kun halusin kaapata liikenteen sivustoon käytin komentoa "sudo tcpdump -i lo -vv -w dump_auth.pcap tcp port 8888". Ennen käyttöä joutui asentamaan tcpdump wsl:llään komennoilla "sudo apt update" sudo apt install tcpdump -y". Kaappauksessa kuunnellaa interface loopback "-i lo", "-vv" näyttää pakettien sisällön tarkasti. "-w dump_auth.pcap" kirjoittaa tiedoston nimeltä "dump_auth.pcap". "tcp port 8888" on capture filter joka kaappaa vain http liikennettä. Kun sivusto on kaapattu löytyy username, sekä password HTP = Hyper Text Protokollan takaa Authorization all credentials kohdasta. Display filter, jolla löysin nämä on "http.authorization". 

Tiedoston voi kopioida wsl "cp dump_auth.pcap /mnt/c/Users/eelis/Desktop/". Tämän voi liittää sitten Wiresharkkiin. 


Tehtävä 5.1-5.3

Tallennus "docker cp clab-hamk-verkonhallinta-golden-web1:/web1.pcap ~/Verkonhallinta/web1.pcap"

Skannaus tuli osoitteesta 10.10.10.200 ja meni osoitteeseen 10.10.20.101. Attacker lähetti pyynnön [SYN] portti on auki ja web1 vastasi [RST] portti kiinni.
Portteja joita testattiin olivat https(443) ja http(80). Palvelimen vastaus oli [RST] tarkoittaen, että portti oli kiinni. Kuvankaappaus löytyy "NmapVastaukset.png".


Tehtävä 5.4

DNS-liikennettä ei synny porttiskannauksesta, koska Nmap käyttää suoraa IP-osoitetta eikä tee nimiresoluutiota. DNS- kyselyn voi luoda "dig google.com" käskyllä. Kysely ei toimi tälläkään tavalla, koska kontti ei pääse nettiin asennetaan "dnsutils" ja katsotaan päästäänkö sillä. Dnsutilssiakaan ei voitu ladata samaisesta syystä joten luodaan manuaalisesti dns yhteyksiä. Lopullisen tuloksen saatiin kun laitettiin capture päälle ja annettiin komento "dig @10.10.20.101 google.com". Tämä pakottaa queryn menevän ja se pääsee web1 palveluun asti mutta web1 ei ole DNS-palvelin niin antaa takaisin "Destination Unreachable". 
Dns kysely oli "Standard query" DNS-vastaus oli ICMP Port Unreachable. Kysely lähetettiin "10.10.20.101". Kuvankaappaus "dnsKysely.png"


Tehtävä 5.5 

Http pyyntö onnistuu "curl http://10.10.20.101" komenolla, vaikka yhteyttä ei voida muodostaa se silti näkyy Wiresharkissa. Pyynnöstä tuli sourcesta 10.10.10.200 [SYN] ja vastaus 10.10.20.101 [RST, ACK]. 


Tehtävät 5.6

Web1 kontissa ei ole systemd-init järjestelmää eikä journald palvelua joten journalctl ei anna lokitietoja. Kontissa ei ole myöskään rsyslog palvelua joten syslog tiedostoa ei muodostu. Komennolla "last" näkee että konttiin ei kirjauduta SSH:lla vaan containerlab käynnistää nämä automaattisesti. Tämän takia siellä ei ole yhtään kirjautumista. Lastlog näyttää saman asian tämän takia kaikki käyttäjät ovat **Never logged in**.
docker cp clab-hamk-verkonhallinta-golden-web1:/web1.3.pcap ~/Verkonhallinta/reports/Captures/web1.3.pcap 


