                                                            Tehtävä 2

Eelis Källi 9.9.2026

Tehtävän tarkoitus oli oppia ymmärtämään SNMP:n käyttöä, käyttötarkoitusta, sekä asennukseen liittyviä konfigurikaatioita. 
Simple network management protocolla on TCP/IP-verkkojen hallinassa käytettävä tietoliikenneprotokolla. Protokollan avulla voidaan kysyä verkossa olevien laitteiden tiloja tai laitteet voivat itsenäisesti antaa hälytyksiä. SNMP:llä voi esimerkiksi valvoa reitittimien, kytkimien ja palvelimien tilaa, kuten suorittimen käyttöasetta, muistin määrää ja verkkoliikennettä. 


Systemctl status snmpd ei toimi, koska kontissa ei ole systemd:tä. SNMP agentti käynnistetään manuaalisesti komennolla /usr/sbin/snmpd. Tämä luo uuden directoryn konttiin, joka ilmoittaa Turning on AgentX master support. Agentx masteri mahdollistaa muiden agenttien käyttää snmp:tä. Snmp tilan voi tarkistaa ps aux | grep snmpd, jossa ps aux listaa kaikki käynnissä olevat prosessit ja niistä tarkat tiedot, kuten prosessitunnuksen(PID). grep snmpd suodattaa taas edellisen listan ja tulostaa vain ne rivit, joissa esiintyy snmpd.

Konfiguroinnissa joudutaan heti asentamaan nano apt install käskyllä. Lukemani mukaan vi-editorin käyttö voisi onnistua tässä, mutta päädyin tutumpaan vaihtoehtoon eli nano:n käyttöön. Tiedostossa lisäsin nimen agent operatin kohtaan ennen agentx.


Ansiblen sisällä snmp asennuksen jälkeen ilmeni yhteys ongelmia. Yhteyttä ei voitu testata komennolla snmpwalk -v2c -c public web1 system, koska Ansibleen ei ole asennettu nimipaketteja. System OID numerolla saadaan kuitenkin yhteys. OID numero löytyi web1 palvelimen snmp.conf tiedostosta. Tämänkin jälkeen yhteys ei toiminut, jouduin poistamaan conf tiedostosta agentAddress 127.0.0.1 rivin, jonka kautta snmp yritti yhdistää vain paikallisesti. Lisäsin myös rivin agentAddress udp:161, joka mahdollisti agentin kuuntelemaan kaikkia saatavilla olevia yhteyksiä. Kyselystä selvisi, että järjestelmän nimi on web1. Palvelin käyttää Linuxia (kernel 6.18.33.2-microsoft-standard-WSL2. Timetick:(4325) 0:00:43.25 kertoo tickien määrän (4325) ja helpommin luettavan ajan. Järjestelmä oli snmp asennuksen jälkeen ollut päällä 43.25 sekuntia. 


Järjestelmätietojen kyselyt osoittatuivat hankaliksi, koska järjestelmässä ei ollut snmp-mibs-downloaderia. Asennus tunnistaa OID-osoitteet ja kääntää ne luettavampaan muotoon. Järjestelmä kyselyiden tulosteet: getsysName.0 SNMPv2-MIB::sysName.0 = STRING: web1 | getsysDescr.0 SNMPv2-MIB::sysDescr.0 = STRING: Linux web1 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64 | getsysUpTime.0 DISMAN-EVENT-MIB::sysUpTimeInstance = Timeticks: (303323) 0:50:33.23.

Verkkorajapintojen tulkinnassa meni jonkin verran aikaa. Listauksesta ei näe suoraa tietoa mitkä yhteydet olivat rajapintoja, joten web1 palvelimen kautta sai selvitettyä käskyllä ip -4 addr, että lo on loopback 127.0.0.1/8 tämä ei osallistu verkon liikenteeseen. Eth0 172.20.20.5/24 on todennäköisesti jokin WSL:llän virtuaaliverkko. Eth1 10.10.20.101 on LAN-verkko jota käytetään SNMP-yhteyksiin, tämä on verkkorajapinta joka yhdistää laitteen verkkoon.

MIB-objektien tarkoitukset. SysName.0 kertoo laitteen nimen, jota käytetään hallinassa tunnistamiseen. SysDescr.0 kuvaa laitteen käyttöjärjestelmän ja version, tätä käytetään laitteen tunnistamiseen, sekä vianmääritykseen. Laiteylläpitäjä näkee kyselyllä laitteen ohjelmistoversion, mikä auttaa päivitystarpeissa. SysUpTime.0 kertoo SNMP-agentin käynnissäoloajan. IfDescr kertoo rajapinnan nimen ja tyypin. IfOperStatus kertoo onko rajapinta aktiivinen ja toimiiko se.

Usean laitteen valvonta aloitettiin asentamalla db1 ja branch-clientille snmpd ja nano sekä mibs-downloader tämän jälkeen testattiin yhteyttä snmpwalk -v2c -c public branch-client system. Muiden palvelimien käynnistyksessä oli jotain häikkää en saanut sitä toimimaan kun vasta palvelimen uudelleen käynnistyksen jälkeen. Web1 tiedot: nimi web1 Linux(kernel 6.18.33.2-microsoft-standard-WSL2 uptime on kyselyn aikana (945961) 2:37:39.61 | db1 nimi db1 käyttöjärjestelmä Linux db1 6.18.33.2-microsoft-standard-WSL2 uptime (39597) 0:06:35.97 | branch-client nimi branch-client käyttöjärjestelmä Linux branch-client 6.18.33.2-microsoft-standard-WSL2 uptime (111217) 0:18:32.17.

SNMP hyödyt ovat automaattinen tiedon hakeminen palvelimista, reitittimistä, kytkimistä ja muista laitteista. Protokollalla voi myös havaita vikatilanteita. SNMP:n vahvuus on yksinkertaisuus. Protokollalla voidaan kerätä laitteesta esimerkiksi nimi, käyttöjärjestelmä, käynnissäoloaika ja laitteen sijainti. Lisäksi silla voidaan hakea CPU-kuormaa, muistin käyttöä, levyjen tilaa, verkkoliikennettä ja prosesseja. SNMP:llä on huono suojaus joka altistaa tämän erinlaisiin hyökkäysmenetelmiin. V2 ei ole erillisiä käyttäjä tunnuksia, mikä tarkoittaa että kaikki ovat ylläpitäjä roolissa. Käyttäisin version 3 silloin kun yrityksissä noudatetaan GDPR tietosuoja-asetusta. Asetuksen tarkoitus on suojata käyttäjän yksityisyyttä ja henkilötietoja. 


Github linkki:https://github.com/eeliskalli-ops/Verkonhallinta/blob/main/reports/week02.mdv



