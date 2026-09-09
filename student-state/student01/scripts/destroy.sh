#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOPOLOGY_FILE="${ROOT_DIR}/topology/golden.clab.yml"
STUDENT_ID="${STUDENT_ID:-student01}"
NETBOX_COMPOSE_FILE="${ROOT_DIR}/configs/netbox/docker-compose.yml"
NETBOX_ENV_FILE="${ROOT_DIR}/configs/netbox/.env"

echo "[INFO] Tallennetaan opiskelijan tila ennen ympäristön tuhoamista..."
bash "${ROOT_DIR}/scripts/persist/student-state-sync.sh" "${STUDENT_ID}" >/dev/null

echo "[INFO] Suljetaan ympäristö..."

if [ -f "$NETBOX_COMPOSE_FILE" ] && [ -f "$NETBOX_ENV_FILE" ]; then
	echo "[INFO] Suljetaan NetBox-pino..."
	# Prefer the newer `docker compose` subcommand if available, otherwise fall back to `docker-compose`.
	if docker compose version >/dev/null 2>&1; then
		docker compose -f "$NETBOX_COMPOSE_FILE" --env-file "$NETBOX_ENV_FILE" down
	elif command -v docker-compose >/dev/null 2>&1; then
		docker-compose -f "$NETBOX_COMPOSE_FILE" --env-file "$NETBOX_ENV_FILE" down
	else
		echo "[WARN] docker compose or docker-compose not available; skipping NetBox shutdown" >&2
	fi
fi

sudo containerlab destroy -t "$TOPOLOGY_FILE" 

echo "[OK] Ympäristö poistettu ja tila tallennettu opiskelijalle ${STUDENT_ID}"
