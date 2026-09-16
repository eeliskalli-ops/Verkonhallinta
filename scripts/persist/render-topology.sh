#!/bin/bash
set -euo pipefail

# Renders a per-student copy of the golden topology, pointing the
# server/client nodes at their previously committed docker images
# (if any) so that changes made inside those containers survive a
# destroy/deploy cycle. Prints the path of the generated file on stdout.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STUDENT_ID="${1:-student01}"
LAB_NAME="hamk-verkonhallinta-golden"
BASE_TOPOLOGY="${ROOT}/topology/golden.clab.yml"
# Generated file must live next to golden.clab.yml so its relative binds
# (../configs, ../state, ../scripts) keep resolving to the repo root.
OUT_FILE="${ROOT}/topology/golden.${STUDENT_ID}.clab.yml"

# Must match the node list used in scripts/persist/student-state-sync.sh
PERSIST_NODES=(client1 attacker branch-client web1 db1)

cp "${BASE_TOPOLOGY}" "${OUT_FILE}"

if command -v docker >/dev/null 2>&1; then
	for node in "${PERSIST_NODES[@]}"; do
		IMAGE_TAG="clab-persist-${STUDENT_ID}-${node}:latest"
		if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
			echo "[INFO] Kaytetaan opiskelijan ${STUDENT_ID} tallennettua tilaa noodille ${node} (${IMAGE_TAG})" >&2
			awk -v node="${node}" -v img="${IMAGE_TAG}" '
			{
				if ($0 ~ "^    [A-Za-z0-9_.|-]+:[[:space:]]*$") {
					innode = ($0 ~ ("^    " node ":[[:space:]]*$")) ? 1 : 0
				}
				if (innode && /^      image:/) {
					sub(/image:.*/, "image: " img)
					innode = 0
				}
				print
			}' "${OUT_FILE}" > "${OUT_FILE}.tmp" && mv "${OUT_FILE}.tmp" "${OUT_FILE}"
		fi
	done
else
	echo "[WARN] docker ei loydy, kaytetaan alkuperaisia image-maarittelyja" >&2
fi

echo "${OUT_FILE}"
