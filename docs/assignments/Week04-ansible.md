# Viikko 4 – Ansible ja Infrastructure as Code

## Tavoite

Tähän asti palveluiden käyttöönotto on tehty käsin.

Tässä tehtävässä automatisoidaan ympäristön hallintaa Ansiblella.

Harjoituksen jälkeen osaat:

- käyttää Ansiblea usean koneen hallintaan
- luoda inventory-tiedoston
- suorittaa playbookeja
- automatisoida ohjelmistojen asennuksia
- hallita infrastruktuuria koodina

---

# Oppimistavoitteet

Tehtävän jälkeen osaat:

- selittää Infrastructure as Code -periaatteen
- käyttää Ansible inventorya
- suorittaa playbookeja
- asentaa ohjelmia etänä
- automatisoida palvelinten ylläpitotehtäviä

---

# Lähtötilanne

Kirjaudu Ansible-palvelimelle:

```bash
docker exec -it clab-hamk-verkonhallinta-golden-ansible bash
```

Tarkista inventory:

```bash
cat /ansible/inventory.ini
```

Tarkista yhteydet:

```bash
ansible all -i /ansible/inventory.ini -m ping
```

---

# Tehtävä 4.1 – Tutustu inventoryyn

Selvitä:

- mitä laitteita inventory sisältää
- miten ryhmät on muodostettu
- mitä hyötyä ryhmistä on

Dokumentoi havainnot.

---

# Tehtävä 4.2 – Suorita ensimmäinen playbook

Siirry playbook-hakemistoon:

```bash
cd /ansible/playbooks
```

Suorita:

```bash
ansible-playbook -i ../inventory.ini ping.yml
```

Dokumentoi:

- mitä playbook tekee
- mitä tuloksista voidaan päätellä

---

# Tehtävä 4.3 – Tutustu valmiisiin esimerkkeihin

Ympäristössä on valmiina kaksi esimerkkiplaybookia, joista näet miten Ansible-playbook rakennetaan:

```text
/ansible/playbooks/install-snmp.yml
/ansible/playbooks/install-node-exporter.yml
```

Tutki molemmat tiedostot ja vastaa:

- mitä moduuleja playbookeissa käytetään (esim. `apt`, `copy`, `service`, `get_url`, `unarchive`)
- miten muuttujia (`vars`) hyödynnetään
- miten `handlers`-lohkoa käytetään SNMP-playbookissa
- miksi Node Exporter -playbook ei tarvitse handleria

Suorita molemmat esimerkkiplaybookit ympäristössä ja varmista, että asennukset onnistuvat:

```bash
cd /ansible/playbooks
ansible-playbook -i ../inventory.ini install-snmp.yml
ansible-playbook -i ../inventory.ini install-node-exporter.yml
```

Näitä playbookeja käytät mallina omien playbookien rakentamisessa seuraavissa tehtävissä.

---

# Tehtävä 4.4 – Oma playbook: palvelimen asennus

Valitse **vähintään yksi** seuraavista tehtävistä (halutessasi voit tehdä molemmat lisäpisteiden toivossa):

## Vaihtoehto A – Web-palvelin (web1)

Kirjoita itse playbook `install-webserver.yml`, joka asentaa `web1`-koneelle web-palvelimen (esim. `nginx` tai `apache2`).

Playbookin tulee:

- päivittää pakettilista
- asentaa valitsemasi web-palvelinohjelmisto
- luoda yksinkertainen `index.html`-sivu, joka kertoo palvelimen nimen
- käynnistää ja ottaa palvelun käyttöön (`enabled: yes`)
- varmistaa asennuksen onnistumisen (esim. `uri`-moduulilla tai `curl`-komennolla)

## Vaihtoehto B – Tietokantapalvelin (db1)

Kirjoita itse playbook `install-database.yml`, joka asentaa `db1`-koneelle tietokantapalvelimen (esim. `mariadb-server` tai `postgresql`).

Playbookin tulee:

- päivittää pakettilista
- asentaa valitsemasi tietokantaohjelmisto
- käynnistää ja ottaa palvelun käyttöön
- luoda testitietokanta tai -käyttäjä
- varmistaa, että tietokantapalvelu on käynnissä

## Vaatimukset molemmille vaihtoehdoille

- käytä samaa rakennetta kuin tehtävän 4.3 esimerkeissä (`vars`, `tasks`, tarvittaessa `handlers`)
- suorita playbook ja korjaa mahdolliset virheet
- ota talteen suorituksen tuloste (`ansible-playbook` output) raporttia varten

---

# Tehtävä 4.5 – Kerää järjestelmätietoja

Suorita:

```bash
ansible all -i ../inventory.ini -m setup
```

Kerää tiedot:

- käyttöjärjestelmä
- IP-osoite
- prosessorien määrä
- muistin määrä

Dokumentoi tulokset taulukkoon.

---

# Tehtävä 4.6 – Analyysi

Vertaa:

- käsin tehtyjä asennuksia
- Ansiblella tehtyjä asennuksia

Pohdi:

- mitä hyötyjä automaatiosta on
- missä tilanteissa automaatio on välttämätöntä

---

# Raportointi

Luo tiedosto:

```text
reports/week04.md
```

Raportin tulee sisältää:

## Johdanto

Mikä on Infrastructure as Code?

## Inventory

Ympäristön rakenne.

## Esimerkkiplaybookit

Havainnot SNMP- ja Node Exporter -playbookeista.

## Oma playbook

Koodi ja suorituksen tulokset (web-palvelin ja/tai tietokantapalvelin).

## Vertailu

Käsin vs. automaatio.

## Yhteenveto

Opitut asiat.

---

# Arviointikriteerit (10 p)

| Kohde | Pisteet |
|---------|---------:|
| Inventoryn ymmärtäminen | 2 p |
| Esimerkkiplaybookien analyysi | 2 p |
| Oma playbook (web1 ja/tai db1) | 4 p |
| Raportointi | 2 p |