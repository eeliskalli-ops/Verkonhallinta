#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STUDENT_ID="${1:-student01}"
STATE_ROOT="${ROOT}/student-state/${STUDENT_ID}"

if [ ! -d "${STATE_ROOT}" ]; then
  echo "No state found for ${STUDENT_ID}"
  exit 1
fi

cp -a "${STATE_ROOT}/configs" "${ROOT}/"
cp -a "${STATE_ROOT}/Topology" "${ROOT}/"
cp -a "${STATE_ROOT}/scripts" "${ROOT}/"

echo "student state restored from ${STATE_ROOT}"
