#!/bin/bash
# Remove iptables PROXY_ALL redirect only (leave dokodemo running).
set -euo pipefail
CHAIN="PROXY_ALL"
iptables -t nat -D OUTPUT -j "$CHAIN" 2>/dev/null || true
iptables -t nat -F "$CHAIN" 2>/dev/null || true
iptables -t nat -X "$CHAIN" 2>/dev/null || true
echo "OFF: iptables PROXY_ALL removed"
