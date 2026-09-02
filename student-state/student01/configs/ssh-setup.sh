#!/bin/bash
# ============================================================
# SSH Server Setup for Containerlab Nodes
# ============================================================
# Configures SSH server with root access for Ansible automation
# Creates lab-wide SSH key pair for passwordless authentication
# ============================================================

set -euo pipefail

LABUSER="${LABUSER:-labadmin}"
LABPASS="${LABPASS:-Hamk2024!}"
SSH_PORT="${SSH_PORT:-22}"

echo "=== Installing SSH Server ==="

# Install OpenSSH server
if ! command -v sshd &> /dev/null; then
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server >/dev/null 2>&1
    echo "  ✓ SSH server installed"
else
    echo "  ✓ SSH server already installed"
fi

# Create SSH directories
mkdir -p /root/.ssh
mkdir -p /run/sshd
chmod 700 /root/.ssh

# Configure SSH for Ansible/automation use
cat > /etc/ssh/sshd_config <<'EOF'
# HAMK Network Management Lab - SSH Configuration
Port 22
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
# Allow quick disconnects for automation
ClientAliveInterval 60
ClientAliveCountMax 3
EOF

# Set root password (for fallback/manual access)
echo "root:${LABPASS}" | chpasswd

# Create lab admin user (optional, for student use)
if ! id "${LABUSER}" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo "${LABUSER}"
    echo "${LABUSER}:${LABPASS}" | chpasswd
    mkdir -p /home/${LABUSER}/.ssh
    chmod 700 /home/${LABUSER}/.ssh
    chown -R ${LABUSER}:${LABUSER} /home/${LABUSER}/.ssh
fi

# Setup authorized_keys for Ansible
# This will be populated by ansible controller's public key
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Start SSH daemon
if pgrep sshd >/dev/null; then
    echo "  ✓ SSH daemon already running"
else
    /usr/sbin/sshd
    if pgrep sshd >/dev/null; then
        echo "  ✓ SSH daemon started on port ${SSH_PORT}"
    else
        echo "  ✗ Failed to start SSH daemon" >&2
        exit 1
    fi
fi

# Verify SSH is listening
if ss -ltn 2>/dev/null | grep -q ":${SSH_PORT}"; then
    echo "  ✓ SSH listening on port ${SSH_PORT}"
else
    echo "  ✗ SSH not listening on port ${SSH_PORT}" >&2
    exit 1
fi

echo "=== SSH Setup Complete ==="
echo "  Root password: ${LABPASS}"
echo "  Lab user: ${LABUSER} / ${LABPASS}"
echo "  SSH port: ${SSH_PORT}"
