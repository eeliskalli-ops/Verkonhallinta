# Ansible Inventory Dokumentaatio

## Yleiskatsaus

Ansible-inventaario HAMK:n verkonhallintalaboratorion containerlab-topologialle. Inventaario on jaoteltu loogisiin ryhmiin, jotka heijastavat verkkoarkkitehtuuria.

## Inventoryn rakenne

### Verkkolaiteryhmät

#### `[routers]`
FRR-based network routers:
- **r1**: Core router, user network gateway (10.10.10.0/24)
- **r2**: Core router, server network gateway (10.10.20.0/24)
- **r3**: Branch office router (10.10.30.0/24)

Connection: `network_cli` with FRR network OS settings

#### `[clients]`
End-user workstations:
- **client1**: Ubuntu workstation (10.10.10.101)
- **attacker**: Kali Linux security testing host (10.10.10.200)
- **branch-client**: Branch office Ubuntu workstation (10.10.30.101)

#### `[servers]`
Application servers:
- **web1**: Web server Ubuntu (10.10.20.101)
- **db1**: Database server Ubuntu (10.10.20.102)

#### `[monitoring]`
Monitoring and observability stack:
- **prometheus**: Metrics collection (port 9090)
- **grafana**: Visualization dashboard (port 3000)
- **zabbix**: Enterprise monitoring (port 8080)
- **cadvisor**: Container metrics (port 8080)

#### `[management]`
Management tools:
- **ansible**: Ansible control node

### Logical Network Segments

- `[user_network]`: client1, attacker
- `[server_network]`: web1, db1
- `[branch_office]`: branch-client

### Infrastructure Groups

- `[network_devices]`: All routers
- `[linux_hosts]`: All Linux-based nodes
- `[ubuntu_hosts]`: Ubuntu-specific nodes
- `[node_exporter]`: Nodes running Prometheus node_exporter

## Connection Settings

### Default Variables (`[all:vars]`)
```ini
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_become=no
```

### Router Variables
- `ansible_network_os=frr`
- `ansible_connection=network_cli`
- `ansible_user=admin`

### Linux Host Variables
- `ansible_connection=ssh` (standard SSH connection)
- `ansible_user=root`
- `ansible_ssh_pass=Hamk2024!` (fallback password)
- `ansible_python_interpreter=/usr/bin/python3`

**Authentication Methods:**
1. **SSH Key (Preferred)**: Ansible control node generates SSH keypair automatically
   - Public key: `/ansible/keys/ansible_id_rsa.pub`
   - Distributed to all nodes via `ansible-distribute-key.sh` script
   - Passwordless authentication for automation
   
2. **Password (Fallback)**: `Hamk2024!`
   - Used if SSH key authentication fails
   - Allows manual login: `ssh root@<hostname>`
   - Lab user account: `labadmin / Hamk2024!`

**SSH Server Configuration:**
- All Ubuntu/Kali nodes run OpenSSH server on port 22
- Root login enabled for automation purposes
- Password and public key authentication both enabled
- Configured via `configs/ssh-setup.sh` during topology deployment

## Usage Examples

### Initial Setup (After Topology Deployment)

After deploying the containerlab topology, distribute SSH keys:
```bash
# From WSL host
cd ~/Verkonhallinta
sudo bash scripts/ansible-distribute-key.sh

# This script:
# 1. Waits for Ansible container to generate SSH keypair
# 2. Distributes public key to all managed nodes
# 3. Enables passwordless SSH authentication
```

### Test Inventory Connectivity
```bash
# From ansible container
docker exec -it clab-hamk-verkonhallinta-golden-ansible bash
ansible all -i /ansible/inventory.ini -m ping

# Or from WSL host (if ansible installed)
cd ~/Verkonhallinta/configs/ansible
ansible all -i inventory.ini -m ping
```

### Ping All Hosts
```bash
ansible all -i /ansible/inventory.ini -m ping
```

### Ping Specific Group
```bash
ansible routers -i /ansible/inventory.ini -m ping
ansible servers -i /ansible/inventory.ini -m ping
```

### Run Ad-hoc Commands
```bash
# Check uptime on all Ubuntu hosts
ansible ubuntu_hosts -i /ansible/inventory.ini -a "uptime"

# Check disk space on servers
ansible servers -i /ansible/inventory.ini -a "df -h"
```

### Execute Playbooks
```bash
# Install node_exporter on all targets
ansible-playbook -i /ansible/inventory.ini /ansible/playbooks/install-node-exporter.yml

# Configure SNMP on routers
ansible-playbook -i /ansible/inventory.ini /ansible/playbooks/install-snmp.yml
```

## Host Variables

Each host includes custom variables for identification:

- **data_ip**: IP address on the data/user network
- **role**: Server role (webserver, database)
- **service**: Service name for monitoring nodes
- **port**: Exposed service port

Access these in playbooks:
```yaml
- name: Example task using host variables
  debug:
    msg: "{{ inventory_hostname }} data IP: {{ data_ip }}"
```

## Containerlab Integration

All hosts use their full containerlab container names:
- Format: `clab-hamk-verkonhallinta-golden-<nodename>`
- Management network: `clab-mgmt` (172.20.20.0/24)
- DNS resolution works within containerlab network

## Troubleshooting

### Host unreachable via SSH
1. Verify containerlab topology is running: `sudo containerlab inspect -t golden.clab.yml`
2. Check container names: `docker ps --filter "name=clab-hamk"`
3. Test SSH manually from ansible container:
   ```bash
   docker exec clab-hamk-verkonhallinta-golden-ansible \
     ssh -o StrictHostKeyChecking=no root@clab-hamk-verkonhallinta-golden-client1 hostname
   ```
4. Verify SSH is running in target:
   ```bash
   docker exec clab-hamk-verkonhallinta-golden-client1 pgrep sshd
   docker exec clab-hamk-verkonhallinta-golden-client1 ss -ltnp | grep :22
   ```
5. Re-distribute SSH keys if needed:
   ```bash
   sudo bash ~/Verkonhallinta/scripts/ansible-distribute-key.sh
   ```

### SSH authentication failed
1. Check if SSH key exists: `docker exec clab-hamk-verkonhallinta-golden-ansible ls -la /root/.ssh/`
2. Verify public key is in authorized_keys on target:
   ```bash
   docker exec clab-hamk-verkonhallinta-golden-client1 cat /root/.ssh/authorized_keys
   ```
3. Test password authentication as fallback:
   ```bash
   ansible client1 -i inventory.ini -m ping -e ansible_ssh_pass=Hamk2024!
   ```

### Manual SSH access for debugging
```bash
# From WSL host to any node
ssh root@clab-hamk-verkonhallinta-golden-client1
# Password: Hamk2024!

# Or using lab admin user
ssh labadmin@clab-hamk-verkonhallinta-golden-web1
# Password: Hamk2024!
```

### Python not found in target
- Ubuntu/Kali containers should have python3 installed
- Check: `docker exec <container> which python3`
- Install if missing: `docker exec <container> apt-get update && apt-get install -y python3`

### Permission denied
- Verify root password: `Hamk2024!`
- Check SSH config allows root login: `docker exec <container> grep PermitRootLogin /etc/ssh/sshd_config`
- Restart SSH if needed: `docker exec <container> pkill -HUP sshd`

## Maintenance

Update inventory when:
- Adding/removing nodes in topology
- Changing IP addressing scheme
- Modifying network segmentation
- Adding new service roles
