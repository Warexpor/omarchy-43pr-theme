#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-43pr"
BACKUP_DIR="$STATE_DIR/file-backups"
SHELL_CONFIG="$HOME/.config/omarchy/shell.json"
ASSUME_YES=0

PLUGIN_IDS=(
  warexpor.bar
  warexpor.idle
  warexpor.image-picker
  warexpor.media
  warexpor.monitor
)
PLUGIN_REPOS=(
  https://github.com/Warexpor/omarchy-43pr-adaptive-bar-plugin.git
  https://github.com/Warexpor/omarchy-43pr-idle-plugin.git
  https://github.com/Warexpor/omarchy-43pr-image-picker-plugin.git
  https://github.com/Warexpor/omarchy-43pr-media-plugin.git
  https://github.com/Warexpor/omarchy-43pr-monitor-plugin.git
)

while (($#)); do
  case "$1" in
    --yes|-y) ASSUME_YES=1 ;;
    --help|-h)
      echo "Usage: ./uninstall-desktop.sh [--yes]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

cat <<'EOF'
This removes plugins installed from the 43PR public repositories and restores
the bar/plugin/idle shell sections and user files backed up during setup.
The 43PR theme itself and optional extras are left installed.
EOF

if (( ! ASSUME_YES )); then
  read -r -p "Undo the 43PR desktop setup? [y/N] " answer
  [[ $answer =~ ^[Yy]$ ]] || exit 0
fi

for index in "${!PLUGIN_IDS[@]}"; do
  id="${PLUGIN_IDS[$index]}"
  expected="${PLUGIN_REPOS[$index]%.git}"
  directory="$HOME/.config/omarchy/plugins/$id"

  if [[ -d $directory/.git ]]; then
    actual="$(git -C "$directory" remote get-url origin 2>/dev/null || true)"
    actual="${actual%.git}"
    if [[ $actual == "$expected" ]]; then
      echo "Removing $id"
      omarchy plugin remove "$id" --yes
    else
      echo "Leaving $id: its Git origin is not the 43PR repository" >&2
    fi
  elif [[ -d $directory ]]; then
    echo "Leaving local plugin $id: it was not installed from Git" >&2
  fi
done

if [[ -f $STATE_DIR/setup-state.json && -f $SHELL_CONFIG ]]; then
  python3 - "$SHELL_CONFIG" "$STATE_DIR/setup-state.json" <<'PY'
import json
import os
import sys
import tempfile

config_path, state_path = sys.argv[1:]
with open(config_path, encoding="utf-8") as handle:
    config = json.load(handle)
with open(state_path, encoding="utf-8") as handle:
    state = json.load(handle)

for key, snapshot in state.get("shell", {}).items():
    if snapshot.get("present"):
        config[key] = snapshot.get("value")
    else:
        config.pop(key, None)

fd, temporary = tempfile.mkstemp(
    prefix=".shell.json.", dir=os.path.dirname(config_path), text=True
)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(config, handle, indent=2)
        handle.write("\n")
    os.replace(temporary, config_path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
fi

restore_managed_file() {
  local source="$1" relative="$2"
  local destination="$HOME/$relative"
  local backup="$BACKUP_DIR/$relative"
  local absent="$BACKUP_DIR/$relative.absent"

  if [[ -e $destination && ! -e $source ]]; then
    echo "Leaving $destination: install source is unavailable" >&2
    return
  fi

  if [[ -e $destination ]] && ! cmp -s "$source" "$destination"; then
    echo "Leaving modified file $destination" >&2
    return
  fi

  if [[ -e $backup ]]; then
    mkdir -p "$(dirname "$destination")"
    mv "$backup" "$destination"
  elif [[ -e $absent ]]; then
    rm -f "$destination"
  fi
}

restore_managed_file "$ROOT/branding/screensaver.txt" \
  ".config/omarchy/branding/screensaver.txt"
for name in screensaver-alacritty.toml screensaver-foot.ini screensaver-ghostty; do
  restore_managed_file "$ROOT/system/config/omarchy/branding/$name" \
    ".config/omarchy/branding/$name"
done
for name in omarchy-launch-screensaver omarchy-screensaver; do
  restore_managed_file "$ROOT/system/config/omarchy/bin/$name" \
    ".config/omarchy/bin/$name"
done

omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
rm -f "$STATE_DIR/setup-state.json"
find "$BACKUP_DIR" -type f -name '*.absent' -delete 2>/dev/null || true

echo "43PR desktop setup removed. The theme remains available."
