#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SNAPSHOT_DIR="${ROOT}/.snapshots"
LATEST="$(ls -1dt "${SNAPSHOT_DIR}"/* 2>/dev/null | head -n 1 || true)"

if [ -z "${LATEST}" ]; then
  echo "No snapshots found"
  exit 1
fi

cp -a "${LATEST}/configs" "${ROOT}/"
cp -a "${LATEST}/Topology" "${ROOT}/"
cp -a "${LATEST}/scripts" "${ROOT}/"

echo "restored from ${LATEST}"
