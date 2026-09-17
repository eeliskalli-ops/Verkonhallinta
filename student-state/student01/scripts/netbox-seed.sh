#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/configs/netbox/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/configs/netbox/.env"
ENV_TEMPLATE="${ROOT_DIR}/configs/netbox/example.environment"
SEED_FILE="${ROOT_DIR}/configs/netbox/seed/netbox_seed.py"

MODE="upsert"
if [[ "${1:-}" == "--reset" ]]; then
  MODE="reset"
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Dockeria ei loydy PATH:sta"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[ERROR] docker compose pluginia ei loydy"
  exit 1
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "[ERROR] Compose-tiedostoa ei loydy: $COMPOSE_FILE"
  exit 1
fi

if [[ ! -f "$SEED_FILE" ]]; then
  echo "[ERROR] Seed-tiedostoa ei loydy: $SEED_FILE"
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$ENV_TEMPLATE" ]]; then
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    echo "[WARN] Luotiin $ENV_FILE mallista. Paivita salasanat ennen tuotantokayttoa."
  else
    echo "[ERROR] .env puuttuu eika mallia loydy"
    exit 1
  fi
fi

echo "[INFO] Odotetaan, etta NetBox vastaa..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --remove-orphans >/dev/null

curl_status="000"
for _ in $(seq 1 180); do
  curl_status=$(curl -sS -o /dev/null -w "%{http_code}" --retry 1 --retry-all-errors --retry-delay 1 http://localhost:8000/login/ || true)
  if [[ "$curl_status" == "200" ]]; then
    break
  fi
  sleep 1
done

if [[ "$curl_status" != "200" ]]; then
  echo "[FAIL] NetBox healthcheck: FAIL (HTTP ${curl_status} /login/)"
  echo "[INFO] Tarkista lokit: docker compose -f configs/netbox/docker-compose.yml --env-file configs/netbox/.env logs -f"
  exit 1
fi

echo "[OK] NetBox healthcheck: OK (HTTP 200 /login/)"

echo "[INFO] Ajetaan seed (${MODE})"
if [[ "$MODE" == "reset" ]]; then
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T \
    -e NB_SEED_RESET=1 \
    -e PYTHONWARNINGS='ignore:API_TOKEN_PEPPERS is not defined:UserWarning,ignore:LOGIN_REQUIRED is deprecated:FutureWarning' \
    netbox python /opt/netbox/netbox/manage.py shell < "$SEED_FILE"
else
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T \
    -e NB_SEED_RESET=0 \
    -e PYTHONWARNINGS='ignore:API_TOKEN_PEPPERS is not defined:UserWarning,ignore:LOGIN_REQUIRED is deprecated:FutureWarning' \
    netbox python /opt/netbox/netbox/manage.py shell < "$SEED_FILE"
fi

echo "[OK] NetBox seed valmis"