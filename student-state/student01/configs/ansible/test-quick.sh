#!/bin/bash
# Quick test script for Ansible inventory validation
# Run from WSL host or ansible container

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY="${SCRIPT_DIR}/inventory.ini"

echo "=== Ansible Inventory Quick Test ==="
echo "Inventory: ${INVENTORY}"
echo ""

# Check prerequisites
echo "1. Checking prerequisites..."
if ! command -v ansible &> /dev/null; then
    echo "ERROR: ansible not found. Install with: sudo apt-get install ansible"
    exit 1
fi

if ! python3 -c "import docker" 2>/dev/null; then
    echo "WARNING: Python docker library not found. Install with: pip3 install docker"
    echo "         (Required for docker connection method)"
fi

if [ ! -S /var/run/docker.sock ]; then
    echo "WARNING: Docker socket not found at /var/run/docker.sock"
    echo "         (Required for docker connection method)"
fi

echo "   ✓ Ansible installed: $(ansible --version | head -n1)"
echo ""

# List inventory
echo "2. Listing inventory groups..."
ansible-inventory -i "${INVENTORY}" --list -y | grep -E "^  [a-z]" | sort | head -n 20
echo ""

# Test ping - routers only (they use network_cli)
echo "3. Testing router connectivity (network_cli)..."
ansible routers -i "${INVENTORY}" -m ping -o || echo "   Some routers unreachable"
echo ""

# Test ping - one Linux host with docker connection
echo "4. Testing Linux host connectivity (docker)..."
ansible client1 -i "${INVENTORY}" -m ping -o || echo "   client1 unreachable - check docker connection"
echo ""

# Full test with playbook
if [ -f "${SCRIPT_DIR}/playbooks/test-inventory.yml" ]; then
    echo "5. Running full inventory test playbook..."
    ansible-playbook -i "${INVENTORY}" "${SCRIPT_DIR}/playbooks/test-inventory.yml"
else
    echo "5. Test playbook not found, skipping"
fi

echo ""
echo "=== Test Complete ==="
