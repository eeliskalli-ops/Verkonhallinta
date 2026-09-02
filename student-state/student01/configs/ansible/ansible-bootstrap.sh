#!/bin/bash
set -euo pipefail

echo "=== Ansible Control Node Bootstrap ==="

# Update package list
apt-get update -qq

# Install required packages
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ansible \
  python3 \
  python3-pip \
  sshpass \
  openssh-client \
  openssh-server \
  git \
  curl \
  vim \
  >/dev/null 2>&1

echo "  ✓ Packages installed"

# Generate SSH key pair for Ansible (passwordless)
if [ ! -f /root/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N "" -C "ansible@hamk-lab"
  echo "  ✓ SSH keypair generated"
else
  echo "  ✓ SSH keypair exists"
fi

# Copy public key to shared location for distribution
mkdir -p /ansible/keys
cp /root/.ssh/id_rsa.pub /ansible/keys/ansible_id_rsa.pub
chmod 644 /ansible/keys/ansible_id_rsa.pub
echo "  ✓ Public key exported to /ansible/keys/"

# Create ansible configuration
mkdir -p /etc/ansible
cat > /etc/ansible/ansible.cfg <<'EOF'
[defaults]
inventory = /ansible/inventory.ini
host_key_checking = False
deprecation_warnings = False
interpreter_python = auto_silent
timeout = 30
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
remote_user = root
private_key_file = /root/.ssh/id_rsa

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[privilege_escalation]
become = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
EOF

echo "  ✓ Ansible configuration created"

# Start SSH server for remote management
mkdir -p /run/sshd
if ! pgrep sshd >/dev/null; then
  /usr/sbin/sshd
  echo "  ✓ SSH server started"
fi

# Display info
echo ""
echo "=== Ansible Control Node Ready ==="
echo "  Ansible version: $(ansible --version | head -n1)"
echo "  SSH public key: /ansible/keys/ansible_id_rsa.pub"
echo "  Configuration: /etc/ansible/ansible.cfg"
echo "  Default inventory: /ansible/inventory.ini"
echo ""
echo "Next steps:"
echo "  1. Distribute SSH public key to managed nodes"
echo "  2. Test connectivity: ansible all -m ping"
echo "=================================="

