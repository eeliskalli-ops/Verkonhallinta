# Viikko 3 – Prometheus, Node Exporter ja Grafana

## Tavoite

Tällä viikolla rakennetaan ensimmäinen moderni monitorointiratkaisu kurssiympäristöön.

Viikolla 2 tutustuttiin SNMP:hen. Tässä harjoituksessa käytetään Prometheus-järjestelmää ja Node Exporter -agenttia palvelimien valvontaan.

Harjoituksen jälkeen osaat:

- asentaa Node Exporter -agentin
- tarkistaa Prometheus-keräysten toiminnan
- käyttää PromQL-kyselyitä
- luoda Grafana-dashboardin
- analysoida järjestelmän suorituskykyä

---

# Oppimistavoitteet

Tehtävän jälkeen osaat:

- selittää Prometheus-monitoroinnin toimintaperiaatteen
- tunnistaa agenttipohjaisen monitoroinnin hyödyt
- käyttää Grafanaa tietojen visualisointiin
- rakentaa monitorointinäkymiä
- arvioida järjestelmän kuormitusta

---

# Teoria

Prometheus-järjestelmä koostuu seuraavista komponenteista:

## Node Exporter

Kerää käyttöjärjestelmän suorituskykytietoja.

Esimerkiksi:

- CPU-kuorma
- muistin käyttö
- levytilan käyttö
- verkkoliikenne

---

## Prometheus

Kerää mittarit säännöllisesti agentilta.

Tallentaa tiedot aikasarjatietokantaan.

---

## Grafana

Visualisoi mittarit.

Ylläpitäjä käyttää Grafanaa:

- dashboardeihin
- analysointiin
- raportointiin

---

# Lähtötilanne

Varmista että ympäristö on käynnissä:

```bash
bash scripts/status.sh
```

Avaa Prometheus:

```text
http://localhost:9090
```

Avaa Grafana:

```text
http://localhost:3000
```

---

# Tehtävä 3.1 – Node Exporterin asennus

Kirjaudu web1-koneelle:

```bash
docker exec -it clab-hamk-verkonhallinta-golden-web1 bash
```

Asenna tarvittavat työkalut:

```bash
apt update
apt install wget tar -y
```

Lataa Node Exporter.

Selvitä uusin saatavilla oleva versio GitHubista ja lataa se:

```bash
wget https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-<version>.linux-amd64.tar.gz
```

Pura paketti:

```bash
tar xvf node_exporter-*.linux-amd64.tar.gz
```

Siirry hakemistoon:

```bash
cd node_exporter-*
```

Käynnistä Node Exporter:

```bash
./node_exporter
```

Pidä tämä terminaali auki.

---

# Tehtävä 3.2 – Tarkista exporterin toiminta

Avaa uusi terminaali.

Tarkista että Node Exporter vastaa:

```bash
curl http://localhost:9100/metrics
```

Tuloksena pitäisi näkyä suuri määrä mittareita.

Esimerkiksi:

```text
node_cpu_seconds_total
node_memory_MemTotal_bytes
node_filesystem_size_bytes
```

Ota kuvakaappaus raporttia varten.

---

# Tehtävä 3.3 – Tarkista että Prometheus näkee palvelimen

Avaa Prometheus selaimessa:

```text
http://localhost:9090
```

Valitse:

```text
Status → Targets
```

Tarkista että:

- web1 näkyy kohteena
- tila on UP

Jos kohde ei näy:

- tarkista Node Exporterin toiminta
- tarkista Prometheus-konfiguraatio
- tarkista verkon yhteydet

Lisää kuvakaappaus raporttiin.

---

# Tehtävä 3.4 – Grafanan tietolähde

Kirjaudu Grafanaan.

Lisää tietolähteeksi:

```text
Prometheus
```

Palvelimen osoite:

```text
http://prometheus:9090
```

Testaa yhteys.

Tallenna kuvakaappaus onnistuneesta yhteydestä.

---

# Tehtävä 3.5 – Luo dashboard

Luo uusi dashboard nimellä:

```text
Golden Topology Monitoring
```

Lisää seuraavat paneelit.

---

## CPU

PromQL:

```promql
100 - (avg by(instance)
(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Paneelin nimi:

```text
CPU Usage %
```

---

## Muisti

PromQL:

```promql
(node_memory_MemTotal_bytes -
 node_memory_MemAvailable_bytes)
/
node_memory_MemTotal_bytes
* 100
```

Paneelin nimi:

```text
Memory Usage %
```

---

## Levytila

PromQL:

```promql
100 -
(
node_filesystem_avail_bytes
/
node_filesystem_size_bytes
* 100
)
```

Paneelin nimi:

```text
Disk Usage %
```

---

## Verkkoliikenne (saapuva)

PromQL:

```promql
rate(node_network_receive_bytes_total[5m])
```

Paneelin nimi:

```text
Network Receive
```

---

## Verkkoliikenne (lähtevä)

PromQL:

```promql
rate(node_network_transmit_bytes_total[5m])
```

Paneelin nimi:

```text
Network Transmit
```

---

# Tehtävä 3.6 – Kuormituksen generointi

Aiheuta kuormitusta web1-palvelimelle.

## Levykuormitus

```bash
dd if=/dev/zero of=testfile.img bs=1M count=500
```

## CPU-kuormitus

```bash
yes > /dev/null
```
Tämä tuottaa yhdelle cpu säikeellä lähes 100% kuorman. Tähän parempi, hallittavampi tapa voisi olla käyttää työkalua stress-ng:

```bash
sudo apt install stress-ng
stress-ng --cpu 4 --timeout 60s
```
Tämä kuormittaa neljää CPU-ydintä 60 sekunnin ajan ja lopettaa itse automaattisesti. Se on usein parempi vaihtoehto laboratorio- ja monitorointitesteissä kuin yes > /dev/null.

Tarkkaile dashboardin muutoksia.

Vastaa raportissa:

- Miten CPU-käyrä muuttui?
- Miten levytilan käyttö muuttui?
- Näkyikö verkkoliikenteessä muutoksia?

Lisää kuvakaappaukset.

---

# Tehtävä 3.7 – SNMP vs Prometheus

Vertaa viikon 2 SNMP-ratkaisua viikon 3 Prometheus-ratkaisuun.

Täydennä taulukko:

| Ominaisuus | SNMP | Prometheus |
|------------|------|------------|
| Tiedonkeruu |Valvontajärjestelmä kysyy laitteelta MIB‑arvoja. Laitteen tarjoamat tiedot ovat ennalta määriteltyjä | Palvelin julkaisee mittarit HTTP‑rajapinnassa, ja Prometheus hakee ne säännöllisesti.|
| Käyttöönotto |Vaatii SNMP‑agentin asetukset, yhteisöavaimen ja usein palomuurimuutoksia. |Node Exporter toimii suoraan ilman monimutkaisia asetuksia. Riittää että palvelu käynnistetään |
| Mittarien määrä |Riippuu laitteen MIB‑tiedostoista. Usein vain perusresurssit kuten CPU, muisti ja verkko |Mittareita on huomattavasti enemmän ja ne ovat yhdenmukaisia eri palvelimilla. |
| Visualisointi | Tarvitsee erillisiä työkaluja kuten Cacti, LibreNMS tai Zabbix. Ulkoasu on usein vanhanaikainen. | Grafana tarjoaa suoran integraation ja modernit, muokattavat dashboardit. |
| Hälytysmahdollisuudet | SNMP‑trapit ovat yksinkertaisia ja vaativat erillisen vastaanottimen.|Alertmanager mahdollistaa monipuoliset hälytyssäännöt ja useita ilmoituskanavia. |
| Soveltuvuus pilviympäristöihin |Ei sovi hyvin kontteihin, koska SNMP‑agentteja ei yleensä ole saatavilla. | Suunniteltu toimimaan konttiympäristöissä ja Kubernetesissa.|

---

# Tehtävä 3.8 – Pohdinta

Vastaa seuraaviin kysymyksiin:

1. Mitä hyötyä Prometheuksesta on verrattuna SNMP:hen?
Prometheus on helpompi ottaa käyttöön ja antaa huomattavasti enemmän mittareitä kuin SNMP. Prometheus toimii hyvin yhteystyössä Grafanan kanssa, joten mittareitten visualisointi on selkeää ja nykyaikaisempaa.
2. Millaisia mittareita ylläpitäjän kannattaa seurata jatkuvasti?
- CPU-kuorma ja sen trendi
- Muistin käyttö
- Levytilan käyttö
- Verkkoliikenteen määrä
- Prosessien määrä
- Palveluitten vastajat
3. Mitä tietoa dashboardisi tarjoaa ylläpitäjälle?
Dashboard näyttää palvelimen perusresurssien käytönmäärän reaaliajassa. 
4. Mitä uusia mittareita lisäisit dashboardiin?
Network Recieve - Network Transmit - Disk Usage - Memory Usage - CPU Usage
5. Miten monitorointitiedosta voisi olla hyötyä vianetsinnässä?
CPU:ta seuraamalla voisi nähdä esimerkiksi looppaavan prosessin.
Muistia katsomalla voi nähdä jos jokin sovellus vuotaa muistia. Jos levy täyttyy tiedostot kasvavat hallitsemattomiksi. 
Jos verkossa näkyy piikki se voi johtua hyökkäyksestä. 

---

# Raportointi

Luo tiedosto:

```text
reports/week03.md
```

Raportin tulee sisältää:

## 1. Johdanto

Prometheus-monitoroinnin toimintaperiaate.

## 2. Node Exporterin käyttöönotto

Asennusvaiheet ja testit.

## 3. Prometheus

Targets-sivun tarkastelu ja havainnot.

## 4. Dashboard

Kuvakaappaus koko dashboardista.

## 5. Kuormitustesti

Mittareiden käyttäytyminen kuormituksen aikana.

## 6. SNMP vs Prometheus

Vertailutaulukko ja johtopäätökset.

## 7. Yhteenveto

Mitä opit harjoituksesta?

---

# Palautus

Palauta seuraavat tiedostot:

```text
reports/week03.md
```

sekä raportissa käytetyt kuvat:

```text
reports/images/
```

Esimerkiksi:

```text
reports/
├── week03.md
└── images/
    ├── grafana-dashboard.png
    ├── prometheus-targets.png
    ├── node-exporter-metrics.png
    └── load-test.png
```

---

# Arviointikriteerit (10 p)

| Kohde | Pisteet |
|--------|---------:|
| Node Exporterin käyttöönotto | 2 p |
| Prometheus-targetit | 2 p |
| Dashboard | 3 p |
| Kuormitustesti | 2 p |
| Raportin laatu | 1 p |

## Erinomaisen suorituksen tunnusmerkit

- Dashboard on selkeä ja helposti luettava.
- Kaikki mittarit toimivat oikein.
- Kuormitustestin vaikutukset näkyvät mittauksissa.
- Tuloksia analysoidaan eikä vain esitetä.
- Raportissa vertaillaan kriittisesti SNMP:n ja Prometheuksen eroja.
