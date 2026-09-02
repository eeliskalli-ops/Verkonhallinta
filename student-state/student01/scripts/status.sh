#!/usr/bin/env bash

set -e

TOPOLOGY_FILE="topology/golden.clab.yml"
NETBOX_COMPOSE_FILE="configs/netbox/docker-compose.yml"
NETBOX_ENV_FILE="configs/netbox/.env"

echo ""
echo "===== Containerlab ====="
containerlab inspect -t "$TOPOLOGY_FILE"

echo ""
echo "===== Docker Containers ====="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

if [ -f "$NETBOX_COMPOSE_FILE" ] && [ -f "$NETBOX_ENV_FILE" ]; then
	echo ""
	echo "===== NetBox Compose ====="
	docker compose -f "$NETBOX_COMPOSE_FILE" --env-file "$NETBOX_ENV_FILE" ps
fi