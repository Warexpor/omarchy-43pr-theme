#!/usr/bin/env bash
# Idempotent same-box restore for omarchy-43pr-theme/system.
# See RESTORE.md for the human/agent playbook.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYS="$ROOT/system"
HOME_DIR="${HOME:?}"

DRY_RUN=0
SKIP_PACKAGES=0
SKIP_PROXY=0
SKIP_THEME=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  --dry-run          Print actions; write nothing
  --skip-packages    Skip pacman/AUR/mise installs
  --skip-proxy       Skip proxy template + unit install
  --skip-theme       Skip omarchy theme install/set
  -h, --help         Show help
EOF
}

while (( $# > 0 )); do
  case "$1" in
  --dry-run) DRY_RUN=1; shift ;;
  --skip-packages) SKIP_PACKAGES=1; shift ;;
  --skip-proxy) SKIP_PROXY=1; shift ;;
  --skip-theme) SKIP_THEME=1; shift ;;
  -h|--help) usage; exit 0 ;;
  *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

log() { printf '+ %s\n' "$*"; }
run() {
  if (( DRY_RUN )); then
    log "DRY: $*"
  else
    log "$*"
    "$@"
  fi
}

# Expand {{HOME}} placeholders while copying a file into place.
install_templated() {
  local src="$1" dst="$2" mode="${3:-}"
  if (( DRY_RUN )); then
    log "DRY: install $src -> $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  sed "s|{{HOME}}|$HOME_DIR|g" "$src" > "$dst"
  if [[ -n "$mode" ]]; then
    chmod "$mode" "$dst"
  elif [[ -x "$src" ]] || [[ "$src" == *.sh ]]; then
    chmod +x "$dst"
  fi
}

copy_tree_templated() {
  local src_root="$1" dst_root="$2"
  [[ -d "$src_root" ]] || return 0
  while IFS= read -r -d '' f; do
    local rel="${f#"$src_root"/}"
    install_templated "$f" "$dst_root/$rel"
  done < <(find "$src_root" -type f -print0)
}

echo "=== omarchy-43pr system restore ==="
echo "repo: $ROOT"
echo "home: $HOME_DIR"
(( DRY_RUN )) && echo "(dry-run)"

# --- 1. packages ---
if (( ! SKIP_PACKAGES )); then
  echo
  echo "=== 1. packages ==="
  if (( ! DRY_RUN )); then
    read -r -p "Install packages from manifests? [y/N] " ans || true
  else
    ans=y
  fi
  if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
    if command -v omarchy >/dev/null 2>&1; then
      # Official packages — best-effort; skip already installed
      mapfile -t official < <(grep -v '^$' "$SYS/packages/pacman-explicit.txt" || true)
      if ((${#official[@]})); then
        run omarchy pkg add "${official[@]}" || true
      fi
      mapfile -t aur < <(grep -v '^$' "$SYS/packages/aur-foreign.txt" || true)
      if ((${#aur[@]})); then
        if omarchy pkg aur add --help >/dev/null 2>&1; then
          run omarchy pkg aur add "${aur[@]}" || true
        elif command -v yay >/dev/null 2>&1; then
          run yay -S --needed --noconfirm "${aur[@]}" || true
        else
          echo "WARN: no AUR helper; install manually: ${aur[*]}" >&2
        fi
      fi
    elif command -v pacman >/dev/null 2>&1; then
      echo "WARN: omarchy CLI missing; use pacman/yay manually with packages/*.txt" >&2
    fi
    if command -v mise >/dev/null 2>&1; then
      install_templated "$SYS/packages/mise-tools.toml" "$HOME_DIR/.config/mise/config.toml"
      run mise install || true
    else
      echo "WARN: mise not installed; skip mise-tools.toml" >&2
      install_templated "$SYS/packages/mise-tools.toml" "$HOME_DIR/.config/mise/config.toml"
    fi
  else
    echo "skipped packages"
  fi
else
  echo "=== 1. packages (skipped) ==="
fi

# --- 2. theme ---
echo
echo "=== 2. theme ==="
if (( ! SKIP_THEME )); then
  if command -v omarchy >/dev/null 2>&1; then
    if [[ -d "$HOME_DIR/.config/omarchy/themes/43pr" ]]; then
      run omarchy theme set 43pr || true
    else
      run omarchy theme install https://github.com/Warexpor/omarchy-43pr-theme.git || true
    fi
  else
    echo "WARN: omarchy CLI missing; install theme later" >&2
  fi
else
  echo "skipped theme"
fi

# --- 3. extras ---
echo
echo "=== 3. extras (HDR + TUI agents) ==="
if [[ -x "$ROOT/extras/install-hdr-blur.sh" ]]; then
  if (( DRY_RUN )); then
    log "DRY: $ROOT/extras/install-hdr-blur.sh --with-hooks"
    log "DRY: $ROOT/extras/install-tui-agents.sh --with-hooks"
  else
    "$ROOT/extras/install-hdr-blur.sh" --with-hooks || true
    "$ROOT/extras/install-tui-agents.sh" --with-hooks || true
  fi
else
  echo "WARN: extras installers missing" >&2
fi

# --- 4. configs / bins / desktops ---
echo
echo "=== 4. overlay configs ==="
copy_tree_templated "$SYS/config/hypr" "$HOME_DIR/.config/hypr"
copy_tree_templated "$SYS/config/foot" "$HOME_DIR/.config/foot"
copy_tree_templated "$SYS/config/gtk-3.0" "$HOME_DIR/.config/gtk-3.0"
copy_tree_templated "$SYS/config/gtk-4.0" "$HOME_DIR/.config/gtk-4.0"
copy_tree_templated "$SYS/config/environment.d" "$HOME_DIR/.config/environment.d"
copy_tree_templated "$SYS/config/uwsm" "$HOME_DIR/.config/uwsm"
install_templated "$SYS/config/omarchy/shell.json" "$HOME_DIR/.config/omarchy/shell.json"
copy_tree_templated "$SYS/config/omarchy/bin" "$HOME_DIR/.config/omarchy/bin"
copy_tree_templated "$SYS/config/omarchy/hooks" "$HOME_DIR/.config/omarchy/hooks"
copy_tree_templated "$SYS/config/omarchy/extensions" "$HOME_DIR/.config/omarchy/extensions"
install_templated "$SYS/config/mpv/mpv.conf" "$HOME_DIR/.config/mpv/mpv.conf"
copy_tree_templated "$SYS/config/OpenTabletDriver" "$HOME_DIR/.config/OpenTabletDriver"
install_templated "$SYS/config/kritarc" "$HOME_DIR/.config/kritarc"
install_templated "$SYS/config/kritashortcutsrc" "$HOME_DIR/.config/kritashortcutsrc"
# Make hooks executable
if (( ! DRY_RUN )); then
  find "$HOME_DIR/.config/omarchy/hooks" -type f ! -name '*.sample' -exec chmod +x {} + 2>/dev/null || true
  find "$HOME_DIR/.config/omarchy/bin" -type f -exec chmod +x {} + 2>/dev/null || true
fi

copy_tree_templated "$SYS/config/systemd/user" "$HOME_DIR/.config/systemd/user"

# bins
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  install_templated "$f" "$HOME_DIR/.local/bin/$base" 755
done < <(find "$SYS/bin" -type f -print0)

# OpenTabletDriver: USB plug/unplug autostart (needs root for udev + /usr/local/bin)
if [[ -f "$SYS/udev/99-xppen-deco01v3-otd.rules" && -f "$SYS/bin/otd-usb-autostart" ]]; then
  echo
  echo "=== 4b. OpenTabletDriver USB autostart (root) ==="
  if (( DRY_RUN )); then
    log "DRY: install otd-usb-autostart + udev rules; disable always-on OTD; enable if-present"
  else
    if command -v pkexec >/dev/null 2>&1; then
      pkexec bash -c "
        install -m755 '$SYS/bin/otd-usb-autostart' /usr/local/bin/otd-usb-autostart
        install -m644 '$SYS/udev/99-xppen-deco01v3-otd.rules' /etc/udev/rules.d/99-xppen-deco01v3-otd.rules
        udevadm control --reload-rules
        udevadm trigger --subsystem-match=usb --action=add || true
      " || echo "WARN: pkexec failed; install udev/OTD autostart manually (see HARDWARE.md)" >&2
    else
      echo "WARN: pkexec missing; copy system/udev + otd-usb-autostart as root" >&2
    fi
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user disable opentabletdriver.service 2>/dev/null || true
    systemctl --user enable opentabletdriver-if-present.service 2>/dev/null || true
  fi
fi

# desktops
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  install_templated "$f" "$HOME_DIR/.local/share/applications/$base"
done < <(find "$SYS/applications" -type f -name '*.desktop' -print0)

# --- 5. plugins ---
echo
echo "=== 5. plugins ==="
while IFS= read -r -d '' p; do
  name=$(basename "$p")
  dest="$HOME_DIR/.config/omarchy/plugins/$name"
  if (( DRY_RUN )); then
    log "DRY: rsync plugin $name -> $dest"
  else
    mkdir -p "$dest"
    rsync -a --delete --exclude='.git' "$p/" "$dest/"
    log "plugin $name"
  fi
done < <(find "$SYS/plugins" -mindepth 1 -maxdepth 1 -type d -name 'warexpor.*' -print0)

# --- 6. proxy ---
echo
echo "=== 6. proxy templates ==="
if (( ! SKIP_PROXY )); then
  PROXY_DIR="$HOME_DIR/.local/share/proxy-all"
  if (( DRY_RUN )); then
    log "DRY: install proxy templates into $PROXY_DIR"
  else
    mkdir -p "$PROXY_DIR"
    # Only install template as .template alongside; don't overwrite live secrets
    install_templated "$SYS/proxy/xray-config.template.json" "$PROXY_DIR/xray-config.template.json"
    install_templated "$SYS/proxy/dokodemo-config.template.json" "$PROXY_DIR/dokodemo-config.template.json"
    if [[ ! -f "$PROXY_DIR/dokodemo-config.json" ]]; then
      install_templated "$SYS/proxy/dokodemo-config.template.json" "$PROXY_DIR/dokodemo-config.json"
    else
      log "keep existing $PROXY_DIR/dokodemo-config.json"
    fi
    if [[ ! -f "$PROXY_DIR/xray-config.json" ]]; then
      echo "NOTE: create $PROXY_DIR/xray-config.json from template after filling secrets"
    fi
    copy_tree_templated "$SYS/proxy/scripts" "$PROXY_DIR"
    find "$PROXY_DIR" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  fi
else
  echo "skipped proxy"
fi

# --- 7. reload ---
echo
echo "=== 7. reload ==="
if (( ! DRY_RUN )); then
  systemctl --user daemon-reload 2>/dev/null || true
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload 2>/dev/null || true
    hyprctl configerrors 2>/dev/null || true
  fi
  if command -v omarchy >/dev/null 2>&1; then
    omarchy restart shell 2>/dev/null || true
  fi
  if command -v otd >/dev/null 2>&1 && [[ -f "$HOME_DIR/.config/OpenTabletDriver/settings.json" ]]; then
    otd loadsettings "$HOME_DIR/.config/OpenTabletDriver/settings.json" 2>/dev/null || true
  fi
else
  log "DRY: systemctl --user daemon-reload; hyprctl reload; omarchy restart shell; otd loadsettings"
fi

cat <<EOF

=== done ===
Next:
  1. Finish secrets:  $SYS/secrets.checklist.md
  2. Hardware check:  $SYS/HARDWARE.md
  3. Proxy guide:     $SYS/proxy/README.md
  4. Enable user units you need, e.g.:
       systemctl --user enable --now dokodemo.service gpu-lights-off.service
EOF
