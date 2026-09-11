#!/bin/bash
# Transparent mode OFF: remove the iptables redirect.
# Explicit proxy on 127.0.0.1:10808 keeps working.
# Dokodemo helper is stopped by default (safe); pass --keep-dokodemo to leave it.
set -euo pipefail

DIR="{{HOME}}/.local/share/proxy-all"
CHAIN="PROXY_ALL"

if [[ -z "${SUDO_ASKPASS:-}" ]] && [[ -x /usr/bin/zenity ]]; then
  ASKPASS="$DIR/zenity-askpass.sh"
  cat >"$ASKPASS" <<'EOF'
#!/bin/bash
zenity --password --title="proxy-all (iptables)" --text="Password to remove transparent proxy redirect:" 2>/dev/null
EOF
  chmod 700 "$ASKPASS"
  export SUDO_ASKPASS="$ASKPASS"
  SUDO=(sudo -A)
else
  SUDO=(sudo)
fi

"${SUDO[@]}" iptables -t nat -D OUTPUT -j "$CHAIN" 2>/dev/null || true
"${SUDO[@]}" iptables -t nat -F "$CHAIN" 2>/dev/null || true
"${SUDO[@]}" iptables -t nat -X "$CHAIN" 2>/dev/null || true

if [[ "${1:-}" != "--keep-dokodemo" ]]; then
  "$DIR/stop-dokodemo.sh"
fi

echo "OFF: transparent redirect removed (explicit :10808 proxy still works)"
