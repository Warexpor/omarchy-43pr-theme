#!/bin/bash
# Start (or reuse) the dokodemo-door helper that feeds redirected TCP into
# the existing v2rayN mixed proxy on 127.0.0.1:10808.
# This is NOT TUN — it is still your SOCKS/HTTP proxy path.
set -euo pipefail

DIR="{{HOME}}/.local/share/proxy-all"
XRAY="{{HOME}}/.local/share/v2rayN/bin/xray/xray"
CFG="$DIR/dokodemo-config.json"
PIDFILE="$DIR/dokodemo.pid"
LOG="$DIR/dokodemo-run.log"

if ! ss -lntp 2>/dev/null | grep -q '127.0.0.1:10808'; then
  echo "ERROR: v2rayN mixed proxy is not listening on 127.0.0.1:10808"
  exit 1
fi

if ss -lntp 2>/dev/null | grep -q '127.0.0.1:10809'; then
  echo "dokodemo already listening on 127.0.0.1:10809"
  exit 0
fi

if [[ ! -x "$XRAY" ]]; then
  echo "ERROR: xray binary missing: $XRAY"
  exit 1
fi

nohup "$XRAY" run -c "$CFG" >>"$LOG" 2>&1 &
echo $! >"$PIDFILE"
sleep 0.4

if ! ss -lntp 2>/dev/null | grep -q '127.0.0.1:10809'; then
  echo "ERROR: dokodemo failed to bind 10809; see $LOG"
  tail -n 40 "$LOG" || true
  exit 1
fi

echo "dokodemo started (pid $(cat "$PIDFILE")) on 127.0.0.1:10809 -> socks 10808"
