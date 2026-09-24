1.Johdanto

Mikä on infastructure as code (IaC)

Infastructure as code tarkoittaa sitä, että palvelien, verkkojen ja kofiguraatioiden hallinta tehdään koodina ei käsin. Sen sijaan että ylläpitäjä kirjautuu palvelimelle ja suorittaa komentoja manuaalisesti käytetään tiedostoja, joita voidaan ajaa automaattityökaluilla. 

Alhaalla oleva kaavio inventoryn sisältämät laitteet, sekä ryhmien muodostelut. Ryhmät auttavat kohistamaan playbookin asennuksen tiettyyn kohteeseen. Ryhmät tekevät laajennuksesta helpomman, koska se perii ryhmän asetukset. Ryhmät erottavat myös verkko-laitteet palvelimet ja työasema, mikä helpottaa suunnittelua ja testaamista. Tämän avulla saadaan vähennettyä käsin tehtyjä virheitä ja varmistamaan, että kaikki palvelimet ovat samanlaisia.

Miten automaatio muuttaa pelvelienten ylläpitoa

Ilman automaatiota käyttäjä kirjautuu koneille yksitellen ja suorittaa komennot käsin, josta voi tapahtua virheitä ja epäjohdonmukaisuutta. Automaatiossa nämä korvataa yhdellä komennolla, joka tekee muutokset kaikille palvelimille idettisesti.

Mikä on Ansiblen rooli infrastruktuurin hallinnassa?
Ansible on työkalu, joka toteuttaa IaC-periaatteen käytännössä. Se hallitsee palvelinten konfiguraatiot, suorittaa tehtävät automaattisesti ja varmistaa, että ympäristö pysyy yhtenäisenä. Playbookit toimivat dokumentaationa ja takaavat, että sama konfiguraatio voidaan toistaa milloin tahansa. Ansible tekee infrastruktuurin hallinnasta ennustettavaa, tehokasta ja skaalautuvaa.

2.Inventory

**Laitteet** 
-r1; r2; r3
-client1; attacker; branch-client
-web1; db1
-prometehus; grafana; zabbix; cadvisor
-ansible; srv-bp; mgmt-bp; syslog

**Ryhmät**
routers: r1, r2, r3
clients: client1, attacker, branch-client
servers: web1, db1
monitoring: prometheus, grafana, zabbix, cadvisor
management: ansible
user_network: client1, attacker
server_network: web1, db1
branch_office: branch-client
network_devices (children) routers
linux_hosts (children) clients, servers, monitoring, management
ubuntu_hosts: client1, web1, db1, branch-client
node_exporter (children) routers, clients, servers

SNMP playbookin käyttö


apt päivittää pakettikannan ja asentaa paketit: SNMP & SNMPD | copy kirjoittaa kofigurikaatiotiedoston content kentästä. service ottaa snmpd palvelun käyttöön ja käynnistää sen. shell tarkistaa prosessin olemassaolon komennolla pgrep snmpd. debug näyttää vahvistus viestin playbookin lopussa. 

Playbook yhdistää jokaiseen inventaarion isäntään SSH:lla ja suorittaa testin, joka vastaa takaisin jos yhteys ja etäkoneen Ansible-ympäristö toimivat. Tämä ei ole tavallinen verkkopingi vaan pieni ohjelman pala joka vastaa "pong" jos kaikki on kunnossa. ok:[host] tarkoittaa että ansible pääsi kohteeseen ja sai vastauksen. Unreachable Ansible ei päässyt kohteeseen ollenkaan. Failed Ansible yritti mutta epäonnistui tehtävässä. Tämä voi johtua jonkun kirjaston puuttumisesta. Ensimmäisen playbookin tarkoitus on suorittaa SNMP ja SNMPD asennus ja käynnistää palvelu.

Havainnot 

Konfigurikaatio korvattiin playbookissa olevalla snpd.conf tiedoilla. Käynnistysmenetelmä täytyi olla kontainer pohjainen käynnistys, koska ne eivät tue systemctl pohjaa. Varmesin toimivuuden pgrep komennolla joka näyttää prosessin, sekä snmpwalk näyttää SNMP-endpoint vastauksen yhdessä todistavat toimivuuden. tein alla olevan tehtävän ennenkun huomasin githubin tehtävä rekenteen muutoksesta enkä saanut tekemääsi playbookkia toimimaan.

Onnistunut asennus
PLAY RECAP **********************************************************************************************************************************************************************
branch-client              : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
db1                        : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
web1                       : ok=7    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 

Etänä katsotut SNMP sovellukset käynnissä

root@ansible:/ansible/playbooks# ansible -i ../inventory.ini web1,db1,branch-client -m command -a "pgrep -x snmpd" -b
db1 | CHANGED | rc=0 >>
5949
branch-client | CHANGED | rc=0 >>
5931
web1 | CHANGED | rc=0 >>
5956

Kysyy jokaiselta koneelta sysDecr 0 
root@ansible:/ansible/playbooks# ansible -i ../inventory.ini web1,db1,branch-client -m shell -a "snmpwalk -v2c -c public 127.0.0.1 .1.3.6.1.2.1.1.1.0" -b
db1 | CHANGED | rc=0 >>
iso.3.6.1.2.1.1.1.0 = STRING: "Linux db1 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64"
web1 | CHANGED | rc=0 >>
iso.3.6.1.2.1.1.1.0 = STRING: "Linux web1 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64"
branch-client | CHANGED | rc=0 >>
iso.3.6.1.2.1.1.1.0 = STRING: "Linux branch-client 6.18.33.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun 18 21:54:43 UTC 2026 x86_64"
root@ansible:/ansible/playbooks# 

Oman playbookin teko

PLAY [Install and configure web server] ****************************************

TASK [Update package cache] ****************************************************
ok: [web1]

TASK [Install web server] ******************************************************
ok: [web1]

TASK [Create index.html] *******************************************************
ok: [web1]

TASK [Test nginx configuration] ************************************************
changed: [web1]

TASK [Check if nginx is already running] ***************************************
ok: [web1]

TASK [Start nginx] *************************************************************
skipping: [web1]

TASK [Verify web server responds] **********************************************
ok: [web1]

TASK [Show verification result] ************************************************
ok: [web1] => {
    "msg": "Web server on web1 returned status 200"
}

PLAY RECAP *********************************************************************
web1                       : ok=7    changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   


-------------------------------------------------------------------------------------------------------------------------------------

 Järjestelmätiedot (Tehtävä 4.5)

| Host | Käyttöjärjestelmä| IP-osoite | CPU (vCPU) | Muisti (MB) |
|------|---------------------------|-----------|------------|-------------|
| web1 | Ubuntu Debian V24.04|10.10.20.101 |20   |  11812   |
| db1  |   Ubuntu Debian V24.04|10.10.20.102| 20 | 11812    |
| branch-client |Ubuntu Debian V24.04|10.10.30.101 | 20  | 11812   |
| client1 |Ubuntu Debian V24.04 | 10.10.10.101|  20    | 11812    |
| attacker |Kali Debian 2026.3| 10.10.10.200    |20  |  11812     |

Analyysi (Tehtävä 4.6)

Käsin tehdyssä asennuksessa joudut asentamaan jokaiselle koneelle erikseen ohjelmat. Tällä tavalla virheiden riski kasvaa huomattavasti. Käsin tehty järjestelmä on siis hidas, jos sinulla on 10 konetta teet samat 10 eri koneelle. Ansiblella tehty asennus tekee kaiken yhdellä komennolla ja yhdestä paikasta. Playbookkia ajaessa määrität mitä paketteja asennetaan, mitä palveluja käynnistetään ja mitä tiedostoja luodaan. Playbookin hyödyt ovat yhdenmukaisuus kun ajat sen monelle koneelle kaikki saavat täsmälleen saman kofigurikaation. Asennuksen voi myös tehdä useaan otteeseen. 

Mitä hyötyä on autommatiosta?

1.Nopeus
Yhdellä komennolla saa vaikka 10 konetta konfiguroitua. Käsin tämä olisi 10 kertaa hitaampaa. 

2.Toistettavuus
Playbookit tuottavat saman lopputuloksen joka kerta.

3.Virheiden minimointi 
Playbookit eivät toimi jos kirjoitus virheitä on tulllut

4.Dokumentaatio
Playbookkia voi kuka tahansa katsoa mitä se tekee.

Missä tilanteissa automaatio on välttämätöntä?

1.Suuret ympäristöt
Jos palvelimia on enemmän kun 3, niin käsin tekeminen ei ole järkevää.

2.Turvallisuus
Automaatio varmistaa, että kofigurikaatiot ovat idettisiä.


