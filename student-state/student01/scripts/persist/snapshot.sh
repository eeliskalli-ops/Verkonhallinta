#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SNAPSHOT_DIR="${ROOT}/.snapshots"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="${SNAPSHOT_DIR}/${TIMESTAMP}"

mkdir -p "${TARGET}"

cp -a "${ROOT}/configs" "${TARGET}/configs"
cp -a "${ROOT}/Topology" "${TARGET}/Topology"
cp -a "${ROOT}/scripts" "${TARGET}/scripts"

cat > "${TARGET}/README.txt" <<EOF
Snapshot created at ${TIMESTAMP}
EOF

echo "snapshot saved to ${TARGET}"
