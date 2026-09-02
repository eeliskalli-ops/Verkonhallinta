# NetBox (Docker Compose)

Tama hakemisto sisaltaa erillisen NetBox-pinon, joka liitetaan containerlabin hallintaverkkoon `clab-mgmt`.

## Miksi erillinen pino?

- NetBox pysyy irti varsinaisesta topologiasta.
- NetBox voidaan kaynnistaa ja sammuttaa ilman muutoksia `golden.clab.yml`-tiedostoon.
- NetBox voi silti tavoittaa kaikki mgmt-verkossa olevat laitteet (`172.20.20.0/24`).

## Kaytto

1. Luo ymparistotiedosto:

```bash
cp configs/netbox/.env.example configs/netbox/.env
```

2. Vaihda ainakin seuraavat arvot tiedostoon `configs/netbox/.env`:

- `POSTGRES_PASSWORD`
- `NETBOX_SECRET_KEY` (vahintaan 50 merkkia)
- `API_TOKEN_PEPPER_1` (vahintaan 50 merkkia)
- `NETBOX_SUPERUSER_PASSWORD`

3. Kaynnista labra normaalisti:

```bash
bash scripts/deploy.sh
```

Skripti kaynnistaa ensin containerlabin ja sen jalkeen NetBox-pinon.

## Osoite

- NetBox UI: `http://localhost:8000`

## Topologian visualisointi (NetBox plugin)

Tassa pinossa asennetaan NetBoxiin plugin `netbox-topology-views`.

Kun pino on kaynnissa, avaa NetBox ja siirry:

- `Plugins` -> `Topology Views`

Talla voit rakentaa ja tallentaa visuaalisen topologian NetBoxissa.

## Alkutilan seed (containerlab-topologia)

Voit luoda kurssiympariston alkutilan tiedot NetBoxiin:

```bash
bash scripts/netbox-seed.sh
```

Tama ajaa idempotentin upsert-seedin (ei tuplaa objekteja).
Seed luo laitteet, rajapinnat, IP-osoitteet, prefixit seka kaapeloinnit.
Ennen seedia skripti ajaa NetBox-healthcheckin ja tulostaa selkeasti `OK` tai `FAIL`.

Jos haluat nollata aiemmin seedatut objektit ja luoda ne uudelleen:

```bash
bash scripts/netbox-seed.sh --reset
```

`--reset` poistaa vain `clab-seed`-tagilla luodut kohteet.

Seed luo myos valmiit Topology Views -ryhmat:

- `Labra Full`
- `Labra Core`
- `Labra Management`

## Vianetsinta

Jos Topology Views ilmoittaa puuttuvista kuvista (`.../static/netbox_topology_views/img`):

- Pino ajaa nyt automaattisesti `collectstatic`-vaiheen NetBoxin kaynnistyksessa.
- Kaynnista NetBox-palvelu uudelleen:

```bash
docker compose -f configs/netbox/docker-compose.yml --env-file configs/netbox/.env up -d --force-recreate netbox
```

Tarkista, etta hakemisto loytyy kontista:

```bash
docker compose -f configs/netbox/docker-compose.yml --env-file configs/netbox/.env exec -T netbox ls -la /opt/netbox/netbox/static/netbox_topology_views/img
```

NetBox-pino:

```bash
docker compose -f configs/netbox/docker-compose.yml --env-file configs/netbox/.env ps
```

NetBox-lokit:

```bash
docker compose -f configs/netbox/docker-compose.yml --env-file configs/netbox/.env logs -f
```

Huomio: `scripts/netbox-seed.sh` suodattaa tunnetut NetBoxin deprecation-varoitukset,
jotta ulostuloon jaa vain oikeat virheet.

## .env tiedoston ohjeellinen sisältö

```bash
NETBOX_VERSION=latest
NETBOX_HOST_PORT=8000
ALLOWED_HOSTS=*
TZ=Europe/Helsinki

POSTGRES_DB=netbox
POSTGRES_USER=netbox
POSTGRES_PASSWORD=change-me-postgres

NETBOX_SECRET_KEY=change-me-to-a-long-random-string-at-least-50-characters-123
API_TOKEN_PEPPER_1=change-me-to-a-long-random-string-at-least-50-characters-456
NETBOX_SUPERUSER_NAME=admin
NETBOX_SUPERUSER_EMAIL=admin@example.local
NETBOX_SUPERUSER_PASSWORD=change-me-admin
```
