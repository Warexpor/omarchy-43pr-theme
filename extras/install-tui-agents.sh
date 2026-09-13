#!/usr/bin/env bash
# Install 43PR TUI-agent transparency helpers.
#
# Default (no Omarchy coupling):
#   1. Syncs templates + apply script to ~/.local/share/43pr-tui-agents/
#   2. Runs apply once (OpenCode / Grok / Claude / Herdr / Cursor zen)
#
# Opt-in Omarchy theme-set hook:
#   ./extras/install-tui-agents.sh --with-hooks
#
# Cursor Agent CLI still paints opaque Ink chrome — no public API for
# transparent surfaces yet (see extras/tui-agents/cursor/README.md).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/extras/tui-agents"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/43pr-tui-agents"
APPLY_SHARE="$SHARE/bin/apply-tui-agents.sh"
WITH_HOOKS=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--with-hooks]

  --with-hooks   Also register an Omarchy theme-set hook so re-applying
                 the 43pr theme re-syncs agent configs (no-ops for others)
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

if [[ ! -f "$SRC/opencode/themes/43pr.json" ]]; then
  echo "missing $SRC/opencode/themes/43pr.json" >&2
  exit 1
fi

mkdir -p "$SHARE/bin" "$SHARE/opencode/themes" "$SHARE/opencode/plugins" \
  "$SHARE/claude" "$SHARE/cursor" "$SHARE/grok"

# Sync templates then place the apply script (do not --delete: preserves share/bin).
if command -v rsync >/dev/null 2>&1; then
  rsync -a \
    --exclude 'bin/' \
    "$SRC/" "$SHARE/"
else
  cp -a "$SRC/opencode" "$SRC/claude" "$SRC/cursor" "$SHARE/"
  [[ -d "$SRC/grok" ]] && cp -a "$SRC/grok" "$SHARE/"
fi
install -m 755 "$SRC/bin/apply-tui-agents.sh" "$APPLY_SHARE"
echo "synced templates → $SHARE"

"$APPLY_SHARE" 43pr

if (( WITH_HOOKS )); then
  if command -v omarchy >/dev/null 2>&1; then
    omarchy hook install theme-set "$APPLY_SHARE"
    echo "registered Omarchy theme-set hook → $APPLY_SHARE"
    echo "(fires on every theme change; script no-ops unless slug is 43pr)"
  else
    echo "omarchy CLI not found — theme-set hook skipped (templates still applied)" >&2
  fi
else
  echo "Omarchy theme-set hook not registered (pass --with-hooks to enable)"
fi

cat <<EOF

Applied. Relaunch OpenCode / Grok / Claude in a new Foot window.

Fresh Omarchy machine path:
  omarchy theme install https://github.com/Warexpor/omarchy-43pr-theme.git
  ~/.config/omarchy/themes/43pr/extras/install-tui-agents.sh
  # optional: .../install-tui-agents.sh --with-hooks
  # also run extras/install-hdr-blur.sh for Foot alpha+blur

Cursor Agent: zen mode only — see extras/tui-agents/cursor/README.md
EOF
