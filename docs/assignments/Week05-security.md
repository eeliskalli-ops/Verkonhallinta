# Viikko 5 – Tietoturva, lokit ja verkkoliikenteen analysointi

## Tavoite

Verkonhallinta ei tarkoita pelkästään valvontaa ja automaatiota.

Ylläpitäjän täytyy myös tunnistaa:

- poikkeava liikenne
- tietoturvauhat
- väärinkäytökset
- virheelliset konfiguraatiot

Tässä tehtävässä tutkitaan verkkoliikennettä ja palvelimien lokeja.

---

# Oppimistavoitteet

Tehtävän jälkeen osaat:

- käyttää tcpdumpia
- käyttää Wiresharkia
- analysoida verkkoliikennettä
- tunnistaa porttiskannauksen
- tulkita lokitiedostoja

---

# Lähtötilanne

Kirjaudu attacker-konttiin:
    
```bash
docker exec -it clab-hamk-verkonhallinta-golden-attacker bash
```

Kirjaudu web1-konttiin:

```bash
docker exec -it clab-hamk-verkonhallinta-golden-web1 bash
```

---

# Tehtävä 5.1 – Liikenteen kaappaus

Aloita kaappaus web1-palvelimella:

```bash
tcpdump -i eth1 -w web1.pcap
```

Pidä kaappaus käynnissä.

---

# Tehtävä 5.2 – Porttiskannaus

Suorita attacker-koneelta:

```bash
nmap 10.10.20.101
```

Keskeytä kaappaus.

Tallenna:

```text
web1.pcap
```

---

# Tehtävä 5.3 – Wireshark-analyysi

Avaa kaappaus Wiresharkilla.

Selvitä:

- mistä IP-osoitteesta skannaus tuli
- mitä portteja testattiin
- mitä vastauksia palvelin lähetti

Lisää kuvakaappauksia raporttiin.

---

# Tehtävä 5.4 – DNS-liikenne

Suodata:

```text
dns
```

Tunnista:

- DNS-kyselyt
- DNS-vastaukset
- käytetyt palvelimet

Dokumentoi havainnot.

---

# Tehtävä 5.5 – HTTP-liikenne

Suodata:

```text
http
```

Tunnista:

- HTTP-pyynnöt
- HTTP-vastaukset
- palvelimet

---

# Tehtävä 5.6 – Loki-analyysi

Tarkastele:

```bash
/var/log/syslog
```

tai

```bash
journalctl
```

Etsi:

- kirjautumisia
- virhetilanteita
- palveluiden käynnistyksiä

Dokumentoi löydökset.

---

# Tehtävä 5.7 – Turvallisuusarvio

Arvioi ympäristöä.

Tunnista vähintään kolme asiaa:

- mikä on turvallista
- mikä on tietoturvariski
- mitä pitäisi parantaa

---

# Pohdinta

Vastaa:

1. Miten porttiskannaus näkyi liikenteessä?
2. Miten se näkyi lokeissa?
3. Mitä hyötyä verkkoliikenteen analysoinnista on?
4. Miten monitorointia voisi hyödyntää hyökkäysten tunnistamisessa?

---

# Raportointi

Luo tiedosto:

```text
reports/week05.md
```

Raportin tulee sisältää:

## Johdanto

Tietoturva verkonhallinnan näkökulmasta.

## Kaappaus

Miten liikenne kerättiin.

## Porttiskannaus

Tulokset ja analyysi.

## Wireshark

Havaintoja liikenteestä.

## Loki-analyysi

Tutkitut lokit ja löydökset.

## Turvallisuusarvio

Parannusehdotukset.

## Yhteenveto

Opitut asiat.

---

# Arviointikriteerit (10 p)

| Kohde | Pisteet |
|---------|---------:|
| Liikenteen kaappaus | 2 p |
| Wireshark-analyysi | 3 p |
| Loki-analyysi | 2 p |
| Turvallisuusarvio | 2 p |
| Raportin laatu | 1 p |

## Erinomaisen suorituksen tunnusmerkit

- Analyysi perustuu havaittuun dataan.
- Liikenne ja lokit yhdistetään toisiinsa.
- Havaintoja perustellaan teknisesti.
- Turvallisuusarvio on realistinen ja käytännöllinen.