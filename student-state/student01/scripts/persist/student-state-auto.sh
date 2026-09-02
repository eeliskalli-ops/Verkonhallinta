#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STUDENT_ID="${1:-student01}"

"${ROOT}/scripts/persist/student-state-sync.sh" "${STUDENT_ID}" >/dev/null
"${ROOT}/scripts/persist/student-state-restore.sh" "${STUDENT_ID}" >/dev/null

echo "student state synchronized for ${STUDENT_ID}"
