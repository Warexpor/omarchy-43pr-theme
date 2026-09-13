#!/usr/bin/env bash
# Install 43PR HDR / blur helpers that cannot ship inside a git theme.
#
# Default (no Omarchy coupling):
#   - Installs chromium-sdr-sync to ~/.local/bin
#   - Runs it once (flags.conf + auto Electron wrappers)
#
# Opt-in Omarchy hooks:
#   ./extras/install-hdr-blur.sh --with-hooks
#
# What you still paste yourself (Omarchy strips *.lua / foot.ini from git themes):
#   - extras/hyprland-blur-chromium.lua  →  ~/.config/hypr/hyprland.lua
#   - extras/looknfeel-blur.lua          →  ~/.config/hypr/looknfeel.lua
#   - extras/foot-blur.ini               →  ~/.config/foot/foot.ini
#
# Full writeup: docs/hdr-on-omarchy.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
SYNC_SRC="$ROOT/extras/chromium-sdr-sync"
SYNC_DST="$BIN/chromium-sdr-sync"
WITH_HOOKS=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--with-hooks]

  --with-hooks   Also register Omarchy post-update + post-boot hooks
                 (skipped unless the omarchy CLI is on PATH)
  -h, --help     Show this help
EOF
}

while (( $# > 0 )); do
  case "$1" in
  --with-hooks) WITH_HOOKS=1; shift ;;
  -h|--help) usage; exit 0 ;;
  *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ ! -f "$SYNC_SRC" ]]; then
  echo "missing $SYNC_SRC" >&2
  exit 1
fi

mkdir -p "$BIN"
install -m 755 "$SYNC_SRC" "$SYNC_DST"
echo "installed $SYNC_DST"

if (( WITH_HOOKS )); then
  if command -v omarchy >/dev/null 2>&1; then
    omarchy hook install post-update "$SYNC_DST"
    omarchy hook install post-boot "$SYNC_DST"
    echo "registered Omarchy post-update + post-boot hooks"
  else
    echo "omarchy CLI not found — hooks skipped (binary still installed)" >&2
  fi
else
  echo "Omarchy hooks not registered (pass --with-hooks to enable)"
fi

"$SYNC_DST"

cat <<EOF

Next (manual — cannot be applied by theme install):

  1. Append  $ROOT/extras/hyprland-blur-chromium.lua
     into    ~/.config/hypr/hyprland.lua

  2. Merge   $ROOT/extras/looknfeel-blur.lua
     into    ~/.config/hypr/looknfeel.lua

  3. Merge   $ROOT/extras/foot-blur.ini
     into    ~/.config/foot/foot.ini
     then open a new Foot window.

  4. hyprctl reload && hyprctl configerrors

Details: $ROOT/docs/hdr-on-omarchy.md
EOF
