#!/usr/bin/env bash
# After `omarchy update`, stock extra/hyprland can replace the local HDR build
# (reference_luminance + capture tonemap). If a newer-or-equal package still
# exists under hyprland-hdr-fix/packaging, reinstall it.
set -euo pipefail

PKG_DIR="${HYPRLAND_HDR_PKG_DIR:-}"
if [[ -z ${PKG_DIR} && -f ${HOME}/.config/omarchy/hyprland-hdr-pkg-dir ]]; then
  PKG_DIR=$(<"${HOME}/.config/omarchy/hyprland-hdr-pkg-dir")
  PKG_DIR=${PKG_DIR%%$'\n'*}
fi
PKG_DIR="${PKG_DIR:-${HOME}/Work/MyProjects/hyprland-hdr-fix/packaging}"

[[ -d $PKG_DIR ]] || exit 0

best=
best_ver=
shopt -s nullglob
for f in "$PKG_DIR"/hyprland-[0-9]*.pkg.tar.zst; do
  base=$(basename "$f")
  [[ $base == hyprland-debug-* ]] && continue
  ver=${base#hyprland-}
  ver=${ver%-x86_64.pkg.tar.zst}
  [[ $ver == "$base" ]] && continue
  if [[ -z $best_ver ]] || (( $(vercmp "$ver" "$best_ver") > 0 )); then
    best=$f
    best_ver=$ver
  fi
done
[[ -n $best && -n $best_ver ]] || exit 0

installed=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' || true)
[[ -n $installed ]] || exit 0
[[ $installed == "$best_ver" ]] && exit 0

cmp=$(vercmp "$best_ver" "$installed")
if (( cmp < 0 )); then
  if command -v omarchy-notification-send >/dev/null 2>&1; then
    omarchy-notification-send -u critical -g "HDR" "HDR Hyprland outdated" \
      "Installed $installed is newer than local $best_ver. Rebuild hyprland-hdr-fix, then pacman -U."
  fi
  echo "hyprland-hdr-restore: skip downgrade (installed $installed > local $best_ver)" >&2
  exit 0
fi

pkgs=("$best")
hyprpm="$PKG_DIR/hyprpm-${best_ver}-x86_64.pkg.tar.zst"
[[ -f $hyprpm ]] && pkgs+=("$hyprpm")

echo "hyprland-hdr-restore: reinstalling $best_ver (was $installed)"
sudo pacman -U --noconfirm "${pkgs[@]}"

if command -v omarchy-notification-send >/dev/null 2>&1; then
  omarchy-notification-send -u normal -g "HDR" "HDR Hyprland restored" \
    "Reinstalled $best_ver over $installed. Log out/in (or reboot) to load the patched compositor."
fi
