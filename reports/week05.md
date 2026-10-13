# Viikko 5 – Verkon skannaus ja liikenteen analysointi
**Eelis Källi – 2026**

---

## Tehtävä 5 Osa 1 – DNS, GeoIP ja HTTPS-liikenne

### DNS-suodatus
```
dns.qry.name == "yle.fi"
```
Näyttää kaikki DNS-kyselyt joissa esiintyy *yle.fi*. GeoIP:n jälkeen näkyy että väliaikainen IPv6-osoite lähettää global unicastin. Paketti löytyy osoitteesta `2001:998:20::40`. Source location: Hanko, FI (Elisa Oyj).

### HTTPS-liikenne
Capture filter:
```
tcp port 443
```
Source: Kerava  
Destination: Amazon.com, Inc (USA)

### Frame-suodatus
```
frame matches "yle"
```
Näyttää kaikki paketit joissa esiintyy sana “yle”. Destination GeoIP osoittaa Amazonille → Ylen palvelut hostataan siellä.

### TLS-versiot
- DNS-kyselyn IP: **195.148.239.84**
- TTL: **128**
- Client Hello: **TLS 1.0**
- Server Hello: **TLS 1.2**

---

## Basic Auth -kontti

Zabbix käytti porttia 8080 → tein oman portin 8888.

### Kontin luonti
```
docker run -d \
  --env AUTH_USER=tllabra \
  --env AUTH_PASS=Qwerty1! \
  -v ~/site:/var/www \
  -p 8888:80 \
  tjarvenpaa/basic_auth
```
- `docker run -d` → taustalle  
- `AUTH_USER` / `AUTH_PASS` → tunnukset  
- `-v ~/site:/var/www` → mounttaa index.html kontin sisään  
- `-p 8888:80` → hostin 8888 → kontin 80  
- Sivu avataan: `http://localhost:8888/`

### Liikenteen kaappaus
```
sudo tcpdump -i lo -vv -w dump_auth.pcap tcp port 8888
```

Display filter:
```
http.authorization
```

Tästä löytyi Basic Auth -tunnukset.

Tiedoston kopiointi:
```
cp dump_auth.pcap /mnt/c/Users/eelis/Desktop/
```

---

## Tehtävä 5.1–5.3 – Porttiskannaus

Kaappaus web1-kontista:
```
docker cp clab-hamk-verkonhallinta-golden-web1:/web1.pcap ~/Verkonhallinta/web1.pcap
```

### Havainnot
- Source: **10.10.10.200**
- Destination: **10.10.20.101**
- Attacker lähetti **SYN**
- Web1 vastasi **RST** → portti kiinni
- Testatut portit: **80 (HTTP)** ja **443 (HTTPS)**

Kuvankaappaus: *NmapVastaukset.png*

---

## Tehtävä 5.4 – DNS-liikenne

Nmap ei tee DNS-kyselyitä → käyttää suoraa IP-osoitetta.

Attackerin DNS ei toimi (ei internetiä, 127.0.0.11 stub).

DNS-liikenne pakotettiin:
```
dig @10.10.20.101 google.com
```

### Havainnot
- DNS-kysely: **Standard query A google.com**
- DNS-palvelin: **10.10.20.101**
- Web1 ei ole DNS-palvelin → **ICMP Port Unreachable**

Kuvankaappaus: *dnsKysely.png*

---

## Tehtävä 5.5 – HTTP-liikenne

HTTP-pyyntö attackerista:
```
curl http://10.10.20.101
```

Vaikka yhteys ei muodostu, TCP-yhteysyritys näkyy kaappauksessa.

### Havainnot
- Source: **10.10.10.200**
- Destination: **10.10.20.101**
- Pyynnön tyyppi: **SYN**
- Vastaus: **RST, ACK** → portti kiinni

Suodatin:
```
tcp.port == 80
```

---

## Tehtävä 5.6 – Loki-analyysi

Web1 on Docker-kontti → ei systemd:tä → ei journaldia → ei syslogia.

### Kirjautumislokit
```
last
lastlog
```
Havainnot:
- Konttiin ei kirjauduta SSH:lla  
- Containerlab käynnistää kontit automaattisesti  
- Kaikki käyttäjät: **Never logged in**

### Muut lokit
- `dpkg.log` → paketit  
- `apt/history.log` → paketinhallinta  
- `nginx/access.log` ja `nginx/error.log` → valmiiksi luodut, ei aktiivista palvelua  

### Johtopäätös
Porttiskannaus ei näy lokeissa, koska:
- web1 ei tarjoa palveluita  
- iptables ei loggaa TCP-yhteysyrityksiä  
- kontissa ei ole syslog/journald-palvelua  

---

## Lisäkaappaus
```
docker cp clab-hamk-verkonhallinta-golden-web1:/web1.3.pcap ~/Verkonhallinta/reports/Captures/web1.3.pcap
```
