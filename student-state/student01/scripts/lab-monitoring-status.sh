#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOPOLOGY_FILE="${ROOT_DIR}/Topology/golden.clab.yml"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Dockeria ei loydy PATH:sta"
  exit 1
fi

PROM_CONTAINER="clab-hamk-verkonhallinta-golden-prometheus"
if ! docker ps --format '{{.Names}}' | grep -q "^${PROM_CONTAINER}$"; then
  echo "[ERROR] Prometheus-konttia ei loydy. Onko labra kaynnissa?"
  echo "[INFO] Kaynnista: bash scripts/deploy.sh"
  exit 1
fi

echo "[INFO] Tarkistetaan Prometheus targetit (cadvisor)..."

TARGET_JSON=$(docker exec "$PROM_CONTAINER" wget -qO- http://localhost:9090/api/v1/targets)
CADVISOR_STATE=$(echo "$TARGET_JSON" | sed 's/},{/},\n{/g' | grep -F '"job":"cadvisor"' | grep -o '"health":"[^"]*"' | head -n1 | cut -d '"' -f4 || true)

if [[ "$CADVISOR_STATE" == "up" ]]; then
  echo "[OK] cadvisor-target on UP"
else
  echo "[WARN] cadvisor-target ei ole UP (tila: ${CADVISOR_STATE:-unknown})"
fi

echo "[INFO] Kysytaan esimerkkimetriikka container_memory_working_set_bytes..."
QUERY_URL='http://localhost:9090/api/v1/query?query=count(container_memory_working_set_bytes{name=~"/(clab|netbox)-.*"})'
METRIC_COUNT=$(docker exec "$PROM_CONTAINER" wget -qO- "$QUERY_URL" | sed -n 's/.*"value":\[[^,]*,"\([0-9.]*\)"\].*/\1/p' | head -n1)

echo "[INFO] Havaittuja konttimuistisarjoja: ${METRIC_COUNT:-0}"

echo ""
echo "[INFO] Grafana dashboard: Labra / Labra Container Observability"

echo "[INFO] Topologia: $TOPOLOGY_FILE"
