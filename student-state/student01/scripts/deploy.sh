#!/usr/bin/env bash

set -e

# ----------------------------------------------------
# HAMK Verkonhallinta Golden Topology
# Deploy script
# ----------------------------------------------------

TOPOLOGY_FILE="topology/golden.clab.yml"
NETBOX_DIR="configs/netbox"
NETBOX_COMPOSE_FILE="${NETBOX_DIR}/docker-compose.yml"
NETBOX_ENV_FILE="${NETBOX_DIR}/.env"
NETBOX_ENV_TEMPLATE="${NETBOX_DIR}/example.environment"

echo ""
echo "========================================="
echo " HAMK Verkonhallinta Topology"
echo "========================================="
echo ""

# ----------------------------------------------------
# Check prerequisites
# ----------------------------------------------------

echo "[INFO] Tarkistetaan riippuvuudet..."

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker ei ole asennettu."
    exit 1
fi

if ! command -v containerlab >/dev/null 2>&1; then
    echo "[ERROR] Containerlab ei ole asennettu."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "[ERROR] Docker Compose pluginia ei loydy (docker compose)."
    exit 1
fi

echo "[OK] Docker löytyi"
echo "[OK] Containerlab löytyi"
echo "[OK] Docker Compose löytyi"

# ----------------------------------------------------
# Check topology file
# ----------------------------------------------------

if [ ! -f "$TOPOLOGY_FILE" ]; then
    echo "[ERROR] Topologiatiedostoa ei löydy:"
    echo "        $TOPOLOGY_FILE"
    exit 1
fi

if [ ! -f "$NETBOX_COMPOSE_FILE" ]; then
    echo "[ERROR] NetBox compose -tiedostoa ei loydy:"
    echo "        $NETBOX_COMPOSE_FILE"
    exit 1
fi

if [ ! -f "$NETBOX_ENV_FILE" ]; then
    if [ -f "$NETBOX_ENV_TEMPLATE" ]; then
        echo "[INFO] Luodaan NetBox .env mallipohjasta..."
        cp "$NETBOX_ENV_TEMPLATE" "$NETBOX_ENV_FILE"
        echo "[WARN] Paivita salasanat tiedostoon $NETBOX_ENV_FILE"
    else
        echo "[ERROR] NetBox .env puuttuu eika mallia loydy."
        exit 1
    fi
fi

# ----------------------------------------------------
# Create directories
# ----------------------------------------------------

echo ""
echo "[INFO] Luodaan tarvittavat hakemistot..."

mkdir -p logs
mkdir -p captures
mkdir -p reports
mkdir -p reports/generated

touch logs/.gitkeep
touch captures/.gitkeep
touch reports/.gitkeep
touch reports/generated/.gitkeep

echo "[OK] Hakemistot valmiina"

# ----------------------------------------------------
# Deploy lab
# ----------------------------------------------------

echo ""
echo "[INFO] Käynnistetään Containerlab..."

sudo containerlab deploy -t "$TOPOLOGY_FILE"

echo ""
echo "[INFO] Kaynnistetaan NetBox (Docker Compose)..."

docker compose -f "$NETBOX_COMPOSE_FILE" --env-file "$NETBOX_ENV_FILE" up -d --remove-orphans
bash scripts/netbox-seed.sh

echo ""
echo "[INFO] Tarkistetaan ympäristö..."

containerlab inspect -t "$TOPOLOGY_FILE"

# ----------------------------------------------------
# Service information
# ----------------------------------------------------

echo ""
echo "========================================="
echo " YMPÄRISTÖ KÄYNNISSÄ"
echo "========================================="
echo ""

echo "Grafana:"
echo "http://localhost:3000"
echo ""

echo "Prometheus:"
echo "http://localhost:9090"
echo ""

echo "Zabbix:"
echo "http://localhost:8080"
echo ""

echo "NetBox (jos käytössä):"
echo "http://localhost:8000"
echo ""

echo "========================================="
echo " Seuraavat askeleet"
echo "========================================="
echo ""

echo "Tarkista topologia:"
echo "containerlab inspect -t $TOPOLOGY_FILE"
echo ""

echo "Luo verkkokaavio:"
echo "containerlab graph -t $TOPOLOGY_FILE"
echo ""

echo "Kirjaudu client1-konttiin:"
echo "docker exec -it clab-hamk-verkonhallinta-golden-client1 bash"
echo ""

echo "Sulje ympäristö:"
echo "bash scripts/destroy.sh"
echo ""

echo "[OK] Käyttöönotto valmis"