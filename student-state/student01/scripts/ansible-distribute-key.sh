#!/bin/bash
# ============================================================
# Distribute Ansible SSH Public Key to All Managed Nodes
# ============================================================
# Run this after topology deployment to enable passwordless SSH
# ============================================================

set -euo pipefail

ANSIBLE_CONTAINER="clab-hamk-verkonhallinta-golden-ansible"
PUBKEY_PATH="/ansible/keys/ansible_id_rsa.pub"

echo "=== Distributing Ansible SSH Key ==="

# Wait for ansible container to be ready and key to be generated
echo "Waiting for Ansible container and SSH key..."
for i in {1..30}; do
  if docker exec "${ANSIBLE_CONTAINER}" test -f "${PUBKEY_PATH}" 2>/dev/null; then
    echo "  ✓ SSH key found"
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "  ✗ Timeout waiting for SSH key"
    exit 1
  fi
done

# Get the public key
PUBKEY=$(docker exec "${ANSIBLE_CONTAINER}" cat "${PUBKEY_PATH}")
echo "  ✓ Public key retrieved"

# List of all managed nodes
NODES=(
  "clab-hamk-verkonhallinta-golden-client1"
  "clab-hamk-verkonhallinta-golden-attacker"
  "clab-hamk-verkonhallinta-golden-web1"
  "clab-hamk-verkonhallinta-golden-db1"
  "clab-hamk-verkonhallinta-golden-branch-client"
  "clab-hamk-verkonhallinta-golden-prometheus"
  "clab-hamk-verkonhallinta-golden-grafana"
  "clab-hamk-verkonhallinta-golden-zabbix"
)

# Distribute key to each node
SUCCESS=0
FAILED=0

for node in "${NODES[@]}"; do
  echo -n "  Installing key to ${node}... "
  
  # Wait for node SSH to be ready
  for i in {1..15}; do
    if docker exec "${node}" sh -c "test -S /run/sshd || pgrep sshd >/dev/null" 2>/dev/null; then
      break
    fi
    sleep 2
  done
  
  # Install the key
  if docker exec "${node}" sh -c "
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo '${PUBKEY}' >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys
  " 2>/dev/null; then
    echo "✓"
    ((SUCCESS++))
  else
    echo "✗ failed"
    ((FAILED++))
  fi
done

echo ""
echo "=== Distribution Complete ==="
echo "  Success: ${SUCCESS}"
echo "  Failed: ${FAILED}"
echo ""

if [ ${SUCCESS} -gt 0 ]; then
  echo "Test connectivity with:"
  echo "  docker exec ${ANSIBLE_CONTAINER} ansible all -m ping"
  echo ""
fi
