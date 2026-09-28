#!/bin/bash
# Watch v2rayN guiNDB.db for globalinet ProfileItem set changes (subscription
# update), then run globalinet-filter-sub.py.
#
# Delay/ping updates only touch ProfileExItem — fingerprint stays the same, so
# we do not re-probe on every GUI speed test.
set -euo pipefail

HOME_DIR="${HOME:-{{HOME}}}"
PROXY_ALL="${HOME_DIR}/.local/share/proxy-all"
STATE="${PROXY_ALL}/globalinet-filter"
DB="${HOME_DIR}/.local/share/v2rayN/guiConfigs/guiNDB.db"
FILTER="${PROXY_ALL}/globalinet-filter-sub.py"
LOG="${STATE}/watch.log"
LOCK="${STATE}/watch.lock"
DEBOUNCE_SECS="${GLOBALINET_FILTER_DEBOUNCE:-4}"
SUB_REMARKS="${GLOBALINET_SUB_REMARKS:-globalinet}"

mkdir -p "$STATE"
exec >>"$LOG" 2>&1

log() { echo "[$(date '+%F %T')] $*"; }

fingerprint() {
  python3 "$FILTER" --db "$DB" --sub-remarks "$SUB_REMARKS" --fingerprint-only 2>/dev/null || true
}

run_filter() {
  local fp_now prev
  fp_now="$(fingerprint)"
  prev=""
  [[ -f "$STATE/last-fingerprint.txt" ]] && prev="$(tr -d '\n' <"$STATE/last-fingerprint.txt")"
  if [[ -z "$fp_now" ]]; then
    log "skip: empty fingerprint (db/sub missing?)"
    return 0
  fi
  if [[ "$fp_now" == "$prev" ]]; then
    log "skip: fingerprint unchanged vs last filtered run"
    return 0
  fi
  log "subscription profile set changed — starting filter (concurrency=${GLOBALINET_FILTER_CONCURRENCY:-6})"
  # flock around the probe+delete so overlapping watches do not stack
  flock -n 9 || { log "skip: filter already running"; return 0; }
  python3 "$FILTER" \
    --db "$DB" \
    --sub-remarks "$SUB_REMARKS" \
    --concurrency "${GLOBALINET_FILTER_CONCURRENCY:-6}" \
    --timeout "${GLOBALINET_FILTER_TIMEOUT:-12}" \
    || log "WARN: filter exited non-zero"
} 9>"$LOCK"

if [[ "${1:-}" == "--once" ]]; then
  # Force a filter run even if fingerprint matches (manual / oneshot unit)
  log "manual --once: running filter"
  flock -n 9 || { log "skip: filter already running"; exit 0; }
  python3 "$FILTER" \
    --db "$DB" \
    --sub-remarks "$SUB_REMARKS" \
    --concurrency "${GLOBALINET_FILTER_CONCURRENCY:-6}" \
    --timeout "${GLOBALINET_FILTER_TIMEOUT:-12}"
  exit $?
fi 9>"$LOCK"

if [[ ! -f "$DB" ]]; then
  log "ERROR: db not found: $DB"
  exit 1
fi
if [[ ! -f "$FILTER" ]]; then
  log "ERROR: filter script not installed: $FILTER"
  exit 1
fi
if ! command -v inotifywait >/dev/null 2>&1; then
  log "ERROR: inotifywait missing (pacman -S inotify-tools)"
  exit 1
fi

log "watching $DB for globalinet ProfileItem changes (debounce ${DEBOUNCE_SECS}s)"
# Seed: do not auto-filter on watch start unless explicitly requested
if [[ "${GLOBALINET_FILTER_ON_START:-0}" == "1" ]]; then
  run_filter
else
  fp="$(fingerprint)"
  if [[ -n "$fp" && ! -f "$STATE/last-fingerprint.txt" ]]; then
    echo "$fp" >"$STATE/last-fingerprint.txt"
    log "seeded last-fingerprint without probing (set GLOBALINET_FILTER_ON_START=1 to probe now)"
  fi
fi

CFG_DIR="$(dirname "$DB")"
wait_db_event() {
  # returns 0 when guiNDB.db changed; 1 on timeout (if -t passed via "$@")
  local f
  f="$(inotifywait -q -e close_write,moved_to,create --format '%f' "$@" "$CFG_DIR" 2>/dev/null || true)"
  [[ "$f" == "guiNDB.db" ]]
}

while true; do
  if [[ ! -f "$DB" ]]; then
    log "db missing; sleeping 5s"
    sleep 5
    continue
  fi
  # Block until guiNDB.db is written/replaced (ignore sibling files)
  while ! wait_db_event; do
    :
  done
  # Debounce bursty writes during a single sub update, then drain briefly
  sleep "$DEBOUNCE_SECS"
  while wait_db_event -t 1; do
    sleep 1
  done
  run_filter || true
done
