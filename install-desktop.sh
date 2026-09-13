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

usage() {
  cat <<'EOF'
Usage: ./install-desktop.sh [--yes]

Installs the public 43PR visual setup: theme, five Omarchy shell plugins,
the matching bar layout, and the frosted monochrome screensaver.

This does not install packages, proxy settings, HDR overrides, systemd units,
udev rules, or anything under system/restore.sh.
EOF
}

while (($#)); do
  case "$1" in
    --yes|-y) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

command -v omarchy >/dev/null || {
  echo "Omarchy is required." >&2
  exit 1
}
command -v jq >/dev/null || {
  echo "jq is required (it ships with Omarchy)." >&2
  exit 1
}
command -v python3 >/dev/null || {
  echo "python3 is required (it ships with Omarchy)." >&2
  exit 1
}

cat <<'EOF'
This will:
  - apply the 43PR theme
  - install and enable five public warexpor.* shell plugins
  - replace the current bar/plugin/idle layout with the 43PR layout
  - install user-level screensaver overrides under ~/.config/omarchy/

The replaced shell sections and files are backed up under:
  ~/.local/state/omarchy-43pr/
EOF

if (( ! ASSUME_YES )); then
  read -r -p "Install the 43PR desktop setup? [y/N] " answer
  [[ $answer =~ ^[Yy]$ ]] || exit 0
fi

mkdir -p "$STATE_DIR" "$BACKUP_DIR"

if ! omarchy theme dir 43pr >/dev/null 2>&1; then
  echo "Installing the 43PR theme"
  omarchy theme install https://github.com/Warexpor/omarchy-43pr-theme.git
fi

install_managed_file() {
  local source="$1" relative="$2" mode="$3"
  local destination="$HOME/$relative"
  local backup="$BACKUP_DIR/$relative"
  local absent="$BACKUP_DIR/$relative.absent"

  mkdir -p "$(dirname "$destination")" "$(dirname "$backup")"

  if [[ ! -e $backup && ! -e $absent ]]; then
    if [[ -e $destination ]]; then
      cp -a "$destination" "$backup"
    else
      : >"$absent"
    fi
  fi

  install -m "$mode" "$source" "$destination"
}

for index in "${!PLUGIN_IDS[@]}"; do
  id="${PLUGIN_IDS[$index]}"
  repo="${PLUGIN_REPOS[$index]}"
  directory="$HOME/.config/omarchy/plugins/$id"

  if [[ -d $directory/.git ]]; then
    echo "Updating $id"
    omarchy plugin update "$id" --yes
  elif [[ -d $directory ]]; then
    echo "Using existing local plugin $id"
    omarchy plugin validate "$directory"
    omarchy plugin enable "$id"
  else
    echo "Installing $id"
    omarchy plugin add "$repo" --enable --yes
  fi
done

install_managed_file "$ROOT/branding/screensaver.txt" \
  ".config/omarchy/branding/screensaver.txt" 644
for name in screensaver-alacritty.toml screensaver-foot.ini screensaver-ghostty; do
  install_managed_file "$ROOT/system/config/omarchy/branding/$name" \
    ".config/omarchy/branding/$name" 644
done
for name in omarchy-launch-screensaver omarchy-screensaver; do
  install_managed_file "$ROOT/system/config/omarchy/bin/$name" \
    ".config/omarchy/bin/$name" 755
done

python3 - "$SHELL_CONFIG" "$ROOT/system/config/omarchy/shell.json" \
  "$STATE_DIR/setup-state.json" <<'PY'
import json
import os
import sys
import tempfile

config_path, bundle_path, state_path = sys.argv[1:]
keys = ("bar", "cloneSourceRestores", "disabledPlugins", "idle", "plugins")

with open(bundle_path, encoding="utf-8") as handle:
    bundle = json.load(handle)

if os.path.exists(config_path):
    with open(config_path, encoding="utf-8") as handle:
        config = json.load(handle)
else:
    config = {}

if os.path.exists(state_path):
    with open(state_path, encoding="utf-8") as handle:
        state = json.load(handle)
else:
    state = {
        "shell": {
            key: {"present": key in config, "value": config.get(key)}
            for key in keys
        }
    }

installed = {}
for key in keys:
    if key in bundle:
        config[key] = bundle[key]
        installed[key] = bundle[key]
state["installedShell"] = installed

os.makedirs(os.path.dirname(config_path), exist_ok=True)
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

with open(state_path, "w", encoding="utf-8") as handle:
    json.dump(state, handle, indent=2)
    handle.write("\n")
PY

omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
omarchy theme set 43pr

cat <<'EOF'

43PR desktop setup installed.

Optional HDR, Foot blur, and transparent agent TUI helpers remain opt-in:
  ./extras/install-hdr-blur.sh
  ./extras/install-tui-agents.sh

Undo the visual setup with:
  ./uninstall-desktop.sh
EOF
