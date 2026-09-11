#!/bin/bash
# Transparent mode ON: redirect ALL outbound TCP (except loopback, LAN,
# and the proxy server itself) into dokodemo-door on 127.0.0.1:10809,
# which SOCKS-forwards into v2rayN's mixed proxy on 127.0.0.1:10808.
#
# This is still your proxy (not TUN). Apps that open "direct" TCP
# (Cursor HTTP/2 / Node) get captured and still egress via VLESS.
set -euo pipefail

DIR="{{HOME}}/.local/share/proxy-all"
SERVER_DOMAIN="cdn.borealis-files.com"
CHAIN="PROXY_ALL"
PORT=10809

# GUI password prompt when needed (Cursor agent has no TTY for sudo).
if [[ -z "${SUDO_ASKPASS:-}" ]] && [[ -x /usr/bin/zenity ]]; then
  ASKPASS="$DIR/zenity-askpass.sh"
  cat >"$ASKPASS" <<'EOF'
#!/bin/bash
zenity --password --title="proxy-all (iptables)" --text="Password for transparent proxy redirect:" 2>/dev/null
EOF
  chmod 700 "$ASKPASS"
  export SUDO_ASKPASS="$ASKPASS"
  SUDO=(sudo -A)
else
  SUDO=(sudo)
fi

"$DIR/start-dokodemo.sh"

SRV_IPS=$(getent ahosts "$SERVER_DOMAIN" | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -u || true)
if [ -z "$SRV_IPS" ]; then
  echo "ERROR: cannot resolve $SERVER_DOMAIN, aborting (would create a routing loop)"
  exit 1
fi
echo "proxy server $SERVER_DOMAIN -> $(echo $SRV_IPS | tr '\n' ' ')"

"${SUDO[@]}" iptables -t nat -N "$CHAIN" 2>/dev/null || "${SUDO[@]}" iptables -t nat -F "$CHAIN"
for net in 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
  "${SUDO[@]}" iptables -t nat -A "$CHAIN" -d "$net" -j RETURN
done
for ip in $SRV_IPS; do
  "${SUDO[@]}" iptables -t nat -A "$CHAIN" -d "$ip" -j RETURN
done
"${SUDO[@]}" iptables -t nat -A "$CHAIN" -p tcp -j REDIRECT --to-port "$PORT"
"${SUDO[@]}" iptables -t nat -C OUTPUT -j "$CHAIN" 2>/dev/null || "${SUDO[@]}" iptables -t nat -I OUTPUT -j "$CHAIN"

echo "ON: all TCP (except loopback/LAN/proxy-server) -> 127.0.0.1:$PORT -> socks:10808"
"${SUDO[@]}" iptables -t nat -L "$CHAIN" -n --line-numbers
