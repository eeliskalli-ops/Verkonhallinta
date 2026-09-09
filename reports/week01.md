                                    Verkkotehtävä viikko 1
Eelis Källi 2.9.2026

Raportissa käsitellään Wsl työtilan rakennetta ja miten verkko rakentuu. Tehtävässä rakennettiin myös verkkokaavio johon kirjoitettiin ip osoitteet, sekä reititys.


Ympäristön tarkoitus on luoda turvallinen, sekä monipuolinen verkko kokonaisuus jolla voi valvoa,välittää ja automoida verkon osa-alueita. Haara asiakas puoli mahdollistaa verkon etäkäytön toisesta toimipisteestä. Kokonaisuuden tarkoitus on auttaa opiskelijaa hahmoittamaan verkon käyttöön liittyviä kuormituksia, sekä verkon rakentamisen kokonaisuutta. 

IP-suunnitelman dokumentaatio:
User-LAN -> 10.10.10.0/24 Gateway 10.10.10.1 | Server LAN -> 10.10.20.0/24 Gateway 10.10.20.1 | Branch LAN -> 10.10.30.0/24 Gateway 10.10.30.1
Management LAN -> 10.10.99.0/24 Gateway 10.10.99.1 | R1<->R2 linkki 10.255.12.0/30 Gatewayt 10.255.12.1 / 10.255.12.2 | R2 <-> R3 linkki 10.255.23.0/30 
Gatewayt 10.255.23.1 / 10.255.23.2 

Tärkeimmät osoitteet ovat R1 10.10.10.1 | R1 10.255.12.1 | R2 10.10.20.1 | R2 10.255.12.1 | R2 10.255.12.2 | R3 10.10.30.1 | R3 10.255.23.2
Reititys analyysin tulostus:

----------------------------------------------------------------------------------------------------

ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
223: eth0@if224: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:14:14:07 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.20.20.7/24 brd 172.20.20.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe14:1407/64 scope link
       valid_lft forever preferred_lft forever
249: eth1@if250: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default
    link/ether aa:c1:ab:6f:06:34 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    altname clab-o-045ec1bad251fbd0
    inet 10.255.12.1/30 brd 10.255.12.3 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fe6f:634/64 scope link
       valid_lft forever preferred_lft forever
255: eth2@if256: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default
    link/ether aa:c1:ab:51:ad:9e brd ff:ff:ff:ff:ff:ff link-netnsid 2
    altname clab-o-f4a4216ff399fb64
    inet 10.10.10.1/24 brd 10.10.10.255 scope global eth2
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fe51:ad9e/64 scope link
       valid_lft forever preferred_lft forever
268: eth3@if267: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default
    link/ether aa:c1:ab:96:63:ad brd ff:ff:ff:ff:ff:ff link-netnsid 3
    altname clab-o-a5e7bd674c3b8074
    inet 10.10.10.254/24 brd 10.10.10.255 scope global eth3
       valid_lft forever preferred_lft forever
    inet6 fe80::a8c1:abff:fe96:63ad/64 scope link
       valid_lft forever preferred_lft forever

----------------------------------------------------------------------------------------------------

ip route
default via 172.20.20.1 dev eth0
10.10.10.0/24 dev eth2 proto kernel scope link src 10.10.10.1
10.10.10.0/24 dev eth3 proto kernel scope link src 10.10.10.254
10.10.20.0/24 nhid 24 via 10.255.12.2 dev eth1 proto ospf metric 20
10.10.30.0/24 nhid 24 via 10.255.12.2 dev eth1 proto ospf metric 20
10.10.99.0/24 nhid 24 via 10.255.12.2 dev eth1 proto ospf metric 20
10.255.12.0/30 dev eth1 proto kernel scope link src 10.255.12.1
10.255.23.0/30 nhid 24 via 10.255.12.2 dev eth1 proto ospf metric 20
172.20.20.0/24 dev eth0 proto kernel scope link src 172.20.20.7

----------------------------------------------------------------------------------------------------

ping -c 4 10.10.20.101
PING 10.10.20.101 (10.10.20.101): 56 data bytes
64 bytes from 10.10.20.101: seq=0 ttl=63 time=0.565 ms
64 bytes from 10.10.20.101: seq=1 ttl=63 time=0.175 ms
64 bytes from 10.10.20.101: seq=2 ttl=63 time=0.057 ms
64 bytes from 10.10.20.101: seq=3 ttl=63 time=0.133 ms

--- 10.10.20.101 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.057/0.232/0.565 ms

----------------------------------------------------------------------------------------------------

ping -c 4 10.10.30.101
PING 10.10.30.101 (10.10.30.101): 56 data bytes
64 bytes from 10.10.30.101: seq=0 ttl=62 time=2.410 ms
64 bytes from 10.10.30.101: seq=1 ttl=62 time=0.078 ms
64 bytes from 10.10.30.101: seq=2 ttl=62 time=0.163 ms
64 bytes from 10.10.30.101: seq=3 ttl=62 time=0.098 ms

--- 10.10.30.101 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.078/0.687/2.410 ms

--------------------------------------------------------------------------------------

traceroute 10.10.30.101
traceroute to 10.10.30.101 (10.10.30.101), 30 hops max, 46 byte packets
 1  10.255.12.2 (10.255.12.2)  0.006 ms  0.003 ms  0.003 ms
 2  10.255.23.2 (10.255.23.2)  0.004 ms  0.003 ms  0.003 ms
 3  10.10.30.101 (10.10.30.101)  0.001 ms  0.003 ms  0.001 ms

 ---------------------------------------------------------------------------------------

Reittitaulukon mukaan kone on kytketty kolmeen verkkoon: 10.10.10.0, 10.255.12.0, 172.20.20.0. Kaikki muut sisäverkot sijaitsevat naapurireitittimen 10.255.12.2 kautta. Tuntemattomat kohteet lähtevät aina osoitteeseen 172.20.20.1.


Yhteenveto

Isoimmat ajankulutukset oli löytää oikeat koodit ja tarkat paikat mihin koodi kirjoitetaan. Topologia kuvan tekeminen oli myös aikaa vievä, koska IP-osoitteiden hakeminen ja tulkitseminen oli hankalaa, sekä reitityksen analysointi. Dokumentaatio näyttää heti missä verkossa mikäkin laite sijaitsee ja auttaa paikallistamaan mahdolliset ongelma kohdat, sekä kuuluuko laite sisä- tai ulkoverkkoon.

Github linkki https://github.com/eeliskalli-ops/Verkonhallinta/blob/main/reports/week01.md
