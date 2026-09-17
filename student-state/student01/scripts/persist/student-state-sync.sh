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

# Persist the container filesystem state (installed packages, files, etc.)
# for the server/client nodes by committing their current state as a
# per-student docker image. containerlab destroy removes the containers,
# but the committed image survives and is reused by render-topology.sh
# on the next deploy so that changes made inside the containers persist.
LAB_NAME="hamk-verkonhallinta-golden"
PERSIST_NODES=(client1 attacker branch-client web1 db1)

if command -v docker >/dev/null 2>&1; then
	for node in "${PERSIST_NODES[@]}"; do
		CONTAINER="clab-${LAB_NAME}-${node}"
		if docker inspect "${CONTAINER}" >/dev/null 2>&1; then
			IMAGE_TAG="clab-persist-${STUDENT_ID}-${node}:latest"
			echo "[INFO] Tallennetaan kontin ${CONTAINER} tila -> ${IMAGE_TAG}"
			docker commit "${CONTAINER}" "${IMAGE_TAG}" >/dev/null
		fi
	done
else
	echo "[WARN] docker ei loydy, konttien sisaista tilaa ei voitu tallentaa" >&2
fi

echo "student state saved to ${STATE_ROOT}"
