#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STUDENT_ID="${1:-student01}"
STATE_ROOT="${ROOT}/student-state/${STUDENT_ID}"
mkdir -p "${STATE_ROOT}"

# Persist lab configuration and scripts for this student
rm -rf "${STATE_ROOT}/configs"
rm -rf "${STATE_ROOT}/Topology"
rm -rf "${STATE_ROOT}/scripts"

cp -a "${ROOT}/configs" "${STATE_ROOT}/configs"

# Topology directory may be named 'Topology' or 'topology' depending on OS
if [ -d "${ROOT}/Topology" ]; then
	SRC_TOPOLOGY="${ROOT}/Topology"
elif [ -d "${ROOT}/topology" ]; then
	SRC_TOPOLOGY="${ROOT}/topology"
else
	echo "no topology directory found in ${ROOT}" >&2
	exit 1
fi
cp -a "${SRC_TOPOLOGY}" "${STATE_ROOT}/Topology"

cp -a "${ROOT}/scripts" "${STATE_ROOT}/scripts"

cat > "${STATE_ROOT}/student-id.txt" <<EOF
${STUDENT_ID}
EOF

echo "student state saved to ${STATE_ROOT}"
