       # Viikko 1 – Verkon dokumentointi

       ## Tavoite

       Verkonhallinnan ensimmäinen vaihe on ymmärtää hallittava ympäristö.

       Tässä tehtävässä tutustut kurssin virtuaaliseen verkkoympäristöön, dokumentoit sen rakenteen ja tuotat verkkodokumentaation, jota hyödynnetään myöhemmissä harjoituksissa.

       Työelämässä vastaavaa dokumentaatiota käytetään:

       - verkon ylläpidossa
       - vianetsinnässä
       - muutostenhallinnassa
       - tietoturvatarkastuksissa
       - kapasiteettisuunnittelussa

       ---

       # Oppimistavoitteet

       Tehtävän jälkeen osaat:

       - tunnistaa verkkoympäristön komponentit
       - selvittää laitteiden väliset yhteydet
       - dokumentoida IP-osoitteet ja verkot
       - tuottaa verkkokaavion
       - laatia teknisen verkkodokumentin

       ---

       # Lähtötilanne

       Käynnistä ympäristö:

       ```bash
       bash scripts/deploy.sh
       ```

       Tarkista ympäristön tila:

       ```bash
       bash scripts/status.sh
       ```

       Tutki topologiaa:

       ```bash
       containerlab inspect -t topology/golden.clab.yml
       ```

       ---

       # Tehtävä 1.1 – Topologian kartoitus

       Selvitä ympäristössä olevat laitteet.

       Dokumentoi vähintään:

       | Laite | Tarkoitus |
       |---------|---------|
       | r1 |Reititin käyttäjälle |
       | r2 |Reititin serverille ja hallinalle |
       | r3 |Haarakonttorin reititin  |
       | client1 |Käyttäjän kone |
       | attacker |Hyökkääjä ehkä ddos ?|
       | web1 |netti serveri jota käyttäjät voivat katsoa |
       | db1 |database serveri |
       | branch-client |Haarakonttori |
       | ansible |Ansiblellä voi automoida ohjelmia jotka normaalisti veisi aikaa.      |
       | prometheus |Kerää tietoja ja tallentaa ne aikaleimalla hetkenä milloin ne on kerätty.
       Kerätty data on esimerkiksi aktiivisien yhteyksien tai kyselyjen määrä. |
       | grafana |Yhdistää kaikki databaset ja valvoo niitä. Grafanalla voi laittaa ohjelmat hälyttämään jos jokin käyttöraja ylittyy rajana voi laittaa ohjelman sisäisesti tai sähköpostiin. |
       | zabbix |Zabbixilla voi luoda triggereitä esim cpu käytön valvontaa varten. |

       Kirjoita lyhyt kuvaus jokaisesta laitteesta.

       ---

       # Tehtävä 1.2 – Verkkokaavio

       Piirrä verkkokaavio ympäristöstä.

       Kaaviossa tulee näkyä:

       - kaikki laitteet
       - reitittimet
       - IP-verkot
       - yhteydet

       Voit käyttää esimerkiksi:

       - draw.io
       - Visio
       - PowerPoint
       - käsin piirretty ja skannattu kuva

       Malliesimerkki:

       ```text
                            Branch Office
                            10.10.30.0/24

                     branch-client
                            |
                            r3
                            |
                     10.255.23.0/30
                            |
                            r2
              --------------+--------------
              |                           |
              |                           |
       10.10.20.0/24              10.10.99.0/24
              Server LAN             Management LAN

       web1     db1        ansible
                                   grafana
                                   prometheus
                                   zabbix

                            |
                     10.255.12.0/30
                            |
                            r1
                            |
                     10.10.10.0/24
                     User LAN

                     client1
                     attacker
       ```

       ---

       # Tehtävä 1.3 – IP-osoitteiden dokumentointi

       Täydennä seuraava taulukko:

       | Verkko | Tarkoitus | Yhdyskäytävä |
       |---------|---------|---------|
       | 10.10.10.0/24 |USER LAN | R1 10.10.10.1|
       | 10.10.20.0/24 |SERVER LAN | 10.10.20.1|
       | 10.10.30.0/24 |BRANCH LAN |10.10.30.1 |
       | 10.10.99.0/24 |MANAGEMENT LAN |10.10.99.1 |
       | 10.255.12.0/30 |R1<-->R2 LINKKI |R1:10.255.12.1<>R2:10.255.12.2 |
       | 10.255.23.0/30 |R2<->R3 |R2:10.255.23.1<>R3:10.255.23.2 |

       Selvitä lisäksi:

       - Mitä laitteita kuhunkin verkkoon kuuluu?
       User laniin kuuluvat hyökkääjä sekä käyttäjä server laniin kuuluu netti serveri sekä tietokanta serveri.
       haaraan kuuluvat haara client managementtiin kuuluvat valvonta palvelimet.
       - Mikä reititin toimii yhdyskäytävänä?
      Riippuu mistä verkosta katsoo koska jokaisella verkolla on oma gateway.
       - Mitä tarkoitusta verkko palvelee?
       Verkkolla valvotaan datan käyttöä ohjelmiston ylikuormitusta ja ohjataan käyttäjiä. Verkon reitittimien väliset linkit mahdollistavat verkkojen yhdessä toimivuuden, sekä ohjaavat liikenteen oikeean suuntaan. 

       ---

       # Tehtävä 1.4 – Reitityksen tutkiminen

       Kirjaudu client1-laitteelle:

       ```bash
       docker exec -it clab-hamk-verkonhallinta-golden-client1 bash
       ```

       Suorita seuraavat komennot:

       ```bash
       ip addr
       ```

       ```bash
       ip route
       ```

       Testaa yhteydet:

       ```bash
       ping -c 4 10.10.20.101
       ```

       ```bash
       ping -c 4 10.10.30.101
       ```

       Tutki reittiä branch-clientille:

       ```bash
       traceroute 10.10.30.101
       ```

       Dokumentoi:

       - löytyykö yhteys kaikkiin verkkoihin
       Pingaus näyttäisi hyppäävän Router 1 yli ja menevän suoraan R2 linkkiin ja siitä R3 linkkii ja siitä clientille
       - mitä reittiä liikenne kulkee
       10.10.10.1->10.255.12.2->10.255.23.2->10.10.30.101
       - mitä reitittimiä reitille kuuluu
       R2 ja R3
       Lisää komentojen tulosteet raporttiin.

       ---

       # Tehtävä 1.5 – Dokumentaation tuottaminen

       Luo tiedosto:

       ```text
       reports/week01.md
       ```

       Raportin tulee sisältää seuraavat osiot.

       ## 1. Johdanto

       Kuvaile lyhyesti ympäristön tarkoitus.

       ## 2. Verkkokaavio

       Lisää laatimasi verkkokaavio.

       ## 3. Laiteluettelo

       Taulukko ja kuvaukset ympäristön laitteista.

       ## 4. IP-suunnitelma

       Dokumentoi:

       - verkot
       - aliverkot
       - yhdyskäytävät
       - tärkeimmät IP-osoitteet

       ## 5. Reitityksen analyysi

       Sisällytä:

       - ping-testit
       - traceroute
       - reittitauluanalyysi

       ## 6. Yhteenveto

       Pohdi:

       - Mitkä asiat verkon dokumentaation muodostamisessa kuluttivat eniten aikaa ja miksi?
       - Miten dokumentaatio mielestäsi auttaa palvelusta vastaavaa it-asiantuntijaa työssään?
       ---

       # Palautus

       Palauta Git-repositorioon seuraavat tiedostot:

       ```text
       reports/week01.md
       ```

       sekä mahdolliset kuvat:

       ```text
       reports/images/topology.png
       ```

       Esimerkki hakemistorakenteesta:

       ```text
       reports/
       ├── week01.md
       └── images/
       └── topology.png
       ```

       ---

       # Arviointikriteerit (10 p)

       | Kohde | Pisteet |
       |---------|---------:|
       | Verkkokaavio | 3 p |
       | IP-dokumentaatio | 2 p |
       | Laiteluettelo | 2 p |
       | Reitityksen analyysi | 2 p |
       | Raportin laatu | 1 p |

       ## Erinomaisen suorituksen tunnusmerkit

       - Kaavio on selkeä ja teknisesti oikea.
       - Verkot ja osoitteet on dokumentoitu oikein.
       - Reititys on analysoitu oikein.
       - Raportti on teknisesti täsmällinen ja hyvin jäsennelty.
       - Havainnot perustuvat tehtyihin mittauksiin ja komentojen tulosteisiin.

       ---

       # Vinkkejä

       Tutustu erityisesti seuraaviin komentoihin:

       ```bash
       ip addr
       ```

       ```bash
       ip route
       ```

       ```bash
       ping
       ```

       ```bash
       traceroute
       ```

       ```bash
       containerlab inspect -t topology/golden.clab.yml
       ```
       Tutustu myös [/docs/topology.md](https://github.com/tjarvenpaa/Verkonhallinta/blob/main/docs/topology.md)
       Näitä samoja työkaluja käytetään myöhemmillä viikoilla vianetsinnässä, valvonnassa ja verkonhallinnassa.
       ``
