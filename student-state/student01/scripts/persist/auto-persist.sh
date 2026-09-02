#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
"${ROOT}/scripts/persist/snapshot.sh" >/dev/null

echo "automatic persistence snapshot completed"
