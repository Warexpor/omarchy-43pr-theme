#!/usr/bin/env bash
# Build Foot so text selection frosts under alpha-mode=all, shadow stock Foot,
# and stay rebuilt across `omarchy update` / pacman foot upgrades.
#
#   ./extras/install-foot-selection-alpha.sh           # build + register post-update hook
#   ./extras/install-foot-selection-alpha.sh --force   # rebuild even if stamp matches
#   ./extras/install-foot-selection-alpha.sh --no-hooks
#
# Hook path (durable, not tied to a git checkout):
#   ~/.local/share/43pr-foot/install.sh
#   ~/.config/omarchy/hooks/post-update.d/43pr-foot-selection-alpha.sh
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
OMARCHY_BIN="${OMARCHY_BIN:-$HOME/.config/omarchy/bin}"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/43pr-foot"
BUILD_ROOT="${BUILD_ROOT:-$HOME/.cache/43pr-foot-build}"
STAMP="$SHARE/stamp"
FORCE=0
WITH_HOOKS=1
FROM_HOOK=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] [--no-hooks] [--from-hook]

  --force       Rebuild even when stamp matches the installed foot package
  --no-hooks    Do not register / refresh the Omarchy post-update hook
  --from-hook   Quiet skip-if-current mode (used by post-update.d)
  -h, --help    Show this help
EOF
}

while (( $# > 0 )); do
  case "$1" in
  --force) FORCE=1; shift ;;
  --no-hooks) WITH_HOOKS=0; shift ;;
  --from-hook) FROM_HOOK=1; shift ;;
  -h|--help) usage; exit 0 ;;
  *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

log() { printf '43pr-foot: %s\n' "$*"; }
notify() {
  if command -v omarchy-notification-send >/dev/null 2>&1; then
    omarchy-notification-send -u "${1:-normal}" -g "Foot" "$2" "$3"
  fi
}

# Prefer share copy (hook-safe), then live checkout next to this script.
resolve_patch() {
  local here candidates c
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  candidates=(
    "$SHARE/foot-selection-alpha.patch"
    "$here/foot-selection-alpha.patch"
    "$here/../extras/foot-selection-alpha.patch"
  )
  for c in "${candidates[@]}"; do
    if [[ -f "$c" ]]; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

stock_pkg() {
  pacman -Q foot 2>/dev/null | awk '{print $2}' || true
}

pkg_to_tag() {
  local pkg="$1"
  pkg="${pkg##*:}"   # drop epoch
  printf '%s\n' "${pkg%-*}"
}

sync_share() {
  local here patch_src install_src hook_src
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  mkdir -p "$SHARE"

  patch_src="$(resolve_patch)" || return 1
  install -m 644 "$patch_src" "$SHARE/foot-selection-alpha.patch"

  # Keep a stable installer in share (this file, or extras copy).
  if [[ -f "$here/install-foot-selection-alpha.sh" ]]; then
    install_src="$here/install-foot-selection-alpha.sh"
  elif [[ -f "$here/../extras/install-foot-selection-alpha.sh" ]]; then
    install_src="$here/../extras/install-foot-selection-alpha.sh"
  else
    install_src="${BASH_SOURCE[0]}"
  fi
  install -m 755 "$install_src" "$SHARE/install.sh"

  # Basename becomes the post-update.d filename via `omarchy hook install`.
  cat > "$SHARE/43pr-foot-selection-alpha.sh" <<'HOOK'
#!/usr/bin/env bash
# Omarchy post-update: rebuild patched Foot when the stock package changes.
set -euo pipefail
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/43pr-foot"
exec "$SHARE/install.sh" --from-hook
HOOK
  chmod 755 "$SHARE/43pr-foot-selection-alpha.sh"
}

ensure_shadow() {
  mkdir -p "$OMARCHY_BIN"
  ln -sfn "$PREFIX/bin/foot" "$OMARCHY_BIN/foot"

  local desktop_dir desktop
  desktop_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  desktop="$desktop_dir/foot.desktop"
  mkdir -p "$desktop_dir"
  if [[ -f "$desktop" ]]; then
    sed -i \
      -e "s|^TryExec=.*|TryExec=$PREFIX/bin/foot|" \
      -e "s|^Exec=.*|Exec=$PREFIX/bin/foot|" \
      "$desktop"
  elif [[ -f /usr/share/applications/foot.desktop ]]; then
    sed \
      -e "s|^TryExec=.*|TryExec=$PREFIX/bin/foot|" \
      -e "s|^Exec=.*|Exec=$PREFIX/bin/foot|" \
      /usr/share/applications/foot.desktop > "$desktop"
  fi
  update-desktop-database "$desktop_dir" 2>/dev/null || true
}

register_hooks() {
  if ! command -v omarchy >/dev/null 2>&1; then
    log "omarchy CLI not found — post-update hook skipped"
    return 0
  fi
  omarchy hook install post-update "$SHARE/43pr-foot-selection-alpha.sh"
  log "registered Omarchy post-update hook → $HOME/.config/omarchy/hooks/post-update.d/43pr-foot-selection-alpha.sh"
}

write_stamp() {
  local pkg="$1" tag="$2"
  mkdir -p "$SHARE"
  cat > "$STAMP" <<EOF
pkg=$pkg
tag=$tag
binary=$PREFIX/bin/foot
built_at=$(date -Iseconds)
EOF
}

read_stamp_pkg() {
  [[ -f "$STAMP" ]] || { printf '\n'; return 0; }
  awk -F= '/^pkg=/ { print $2; exit }' "$STAMP"
}

PKG="$(stock_pkg)"
if [[ -z "$PKG" ]]; then
  log "foot package not installed — nothing to do"
  exit 0
fi

TAG="${FOOT_TAG:-$(pkg_to_tag "$PKG")}"
PATCH="$(resolve_patch)" || {
  echo "missing foot-selection-alpha.patch (run from theme extras/ once)" >&2
  exit 1
}

# Fast path for hooks: already built against this exact pacman package.
if (( FORCE == 0 )) && [[ -x "$PREFIX/bin/foot" ]]; then
  stamped="$(read_stamp_pkg)"
  if [[ "$stamped" == "$PKG" ]]; then
    ensure_shadow
    if (( FROM_HOOK )); then
      exit 0
    fi
    log "already current for foot $PKG (pass --force to rebuild)"
    (( WITH_HOOKS )) && sync_share && register_hooks
    exit 0
  fi
fi

if (( FROM_HOOK )); then
  log "foot $PKG — rebuilding selection-alpha binary (tag $TAG)"
fi

sync_share
PATCH="$SHARE/foot-selection-alpha.patch"

mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

if [[ ! -d foot/.git ]]; then
  rm -rf foot
  git clone --depth 1 --branch "$TAG" https://codeberg.org/dnkl/foot.git foot
fi

cd foot
if ! git fetch --depth 1 origin "tag/$TAG:refs/tags/$TAG" 2>/dev/null; then
  # Some tags are annotated / non-commit; fall back to branch tip named for version.
  git fetch --depth 1 origin "refs/tags/$TAG:refs/tags/$TAG" 2>/dev/null || true
fi

if ! git checkout -f "$TAG" 2>/dev/null; then
  msg="Could not check out foot $TAG — selection-alpha rebuild skipped"
  log "$msg"
  notify critical "Foot patch rebuild failed" "$msg. Keep using the previous ~/.local/bin/foot or set FOOT_TAG."
  (( FROM_HOOK )) && exit 0
  exit 1
fi

git clean -fdx

if ! patch -p1 < "$PATCH"; then
  msg="Patch failed to apply on foot $TAG — upstream render.c may have changed"
  log "$msg"
  notify critical "Foot patch rebuild failed" "$msg. Report/update extras/foot-selection-alpha.patch."
  (( FROM_HOOK )) && exit 0
  exit 1
fi

meson setup build \
  --prefix="$PREFIX" \
  --buildtype=release \
  -Dterminfo-base-name=foot-extra \
  -Ddocs=disabled \
  -Dtests=false \
  -Dterminfo=disabled

ninja -C build
install -Dm755 build/foot "$PREFIX/bin/foot"
ensure_shadow
write_stamp "$PKG" "$TAG"

if (( WITH_HOOKS )); then
  register_hooks
elif (( FROM_HOOK == 0 )); then
  log "Omarchy hooks not registered (pass without --no-hooks to enable)"
fi

log "Installed $PREFIX/bin/foot for foot $PKG (tag $TAG)"
"$PREFIX/bin/foot" --version
if (( FROM_HOOK == 0 )); then
  echo
  echo "Open a NEW foot window and select text — highlight should frost, not punch opaque."
  echo "post-update will rebuild automatically when pacman upgrades foot."
fi

if (( FROM_HOOK )); then
  notify normal "Foot selection patch rebuilt" "Rebuilt against foot $PKG. Open a new terminal to pick it up."
fi
