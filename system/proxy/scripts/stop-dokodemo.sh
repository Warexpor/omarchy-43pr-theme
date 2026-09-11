#!/bin/bash
# Stop the dokodemo helper (iptables redirect should be off first).
set -euo pipefail

DIR="{{HOME}}/.local/share/proxy-all"
PIDFILE="$DIR/dokodemo.pid"

if [[ -f "$PIDFILE" ]]; then
  pid=$(cat "$PIDFILE" || true)
  if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    sleep 0.2
    kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$PIDFILE"
fi

# Fallback: kill by config path if pidfile stale
pkill -f 'xray run -c {{HOME}}/.local/share/proxy-all/dokodemo-config.json' 2>/dev/null || true
echo "dokodemo stopped"
