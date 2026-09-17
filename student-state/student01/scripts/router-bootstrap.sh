#!/bin/bash
set -euo pipefail

ROUTER_NAME="${1:-router}"
LAN_CIDR="${2:-}"
LAN_IFACES="${3:-}"
DEFAULT_GW="${4:-}"

sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null

if [ -n "${DEFAULT_GW}" ]; then
  ip route replace default via "${DEFAULT_GW}" || true
fi

if [ -n "${LAN_CIDR}" ]; then
  iptables -t nat -C POSTROUTING -s "${LAN_CIDR}" -o eth0 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s "${LAN_CIDR}" -o eth0 -j MASQUERADE
fi

for iface in ${LAN_IFACES}; do
  iptables -C FORWARD -i "${iface}" -o eth0 -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i "${iface}" -o eth0 -j ACCEPT

  iptables -C FORWARD -i eth0 -o "${iface}" -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
    iptables -A FORWARD -i eth0 -o "${iface}" -m state --state ESTABLISHED,RELATED -j ACCEPT
done

echo "router bootstrap complete for ${ROUTER_NAME}"
