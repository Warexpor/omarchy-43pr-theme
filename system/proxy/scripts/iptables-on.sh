#!/bin/bash
# Install iptables redirect only (dokodemo must already be listening on :10809).
# Used by the system systemd unit so the helper can stay a user service.
set -euo pipefail

DIR="{{HOME}}/.local/share/proxy-all"
SERVER_DOMAIN="cdn.borealis-files.com"
CHAIN="PROXY_ALL"
PORT=10809

if ! ss -lntp 2>/dev/null | grep -q '127.0.0.1:10809'; then
  echo "ERROR: dokodemo not listening on 127.0.0.1:10809 (start user dokodemo.service first)"
  exit 1
fi

SRV_IPS=$(getent ahosts "$SERVER_DOMAIN" | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -u || true)
if [ -z "$SRV_IPS" ]; then
  echo "ERROR: cannot resolve $SERVER_DOMAIN, aborting (would create a routing loop)"
  exit 1
fi

iptables -t nat -N "$CHAIN" 2>/dev/null || iptables -t nat -F "$CHAIN"
for net in 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
  iptables -t nat -A "$CHAIN" -d "$net" -j RETURN
done
for ip in $SRV_IPS; do
  iptables -t nat -A "$CHAIN" -d "$ip" -j RETURN
done
iptables -t nat -A "$CHAIN" -p tcp -j REDIRECT --to-port "$PORT"
iptables -t nat -C OUTPUT -j "$CHAIN" 2>/dev/null || iptables -t nat -I OUTPUT -j "$CHAIN"

echo "ON: iptables PROXY_ALL -> 127.0.0.1:$PORT"
iptables -t nat -L "$CHAIN" -n --line-numbers
