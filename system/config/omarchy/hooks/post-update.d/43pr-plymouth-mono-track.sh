#!/usr/bin/env bash
# After Omarchy updates, packaged Plymouth assets return to the stock green
# logo / Tokyo-Night violet track. When the desktop theme is 43PR, re-apply
# white logo + gray track (and rebuild initramfs) so the next boot stays mono.
set -euo pipefail

theme_slug=$(cat "${HOME}/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
[[ $theme_slug == "43pr" ]] || exit 0

apply="${HOME}/.config/omarchy/bin/43pr-plymouth-apply"
[[ -x $apply ]] || apply="${HOME}/.local/bin/43pr-plymouth-apply"
[[ -x $apply ]] || exit 0

logo=/usr/share/plymouth/themes/omarchy/logo.png
box=/usr/share/plymouth/themes/omarchy/progress_box.png
unlock=$(omarchy-theme-dir 43pr)/unlock.png

needs_apply=0
if [[ ! -f $logo ]] || ! cmp -s "$unlock" "$logo"; then
  needs_apply=1
fi

if [[ -f $box ]]; then
  hex=$(magick "$box" -format '%[hex:u.p{0,0}]' info: 2>/dev/null || true)
  hex=${hex#\#}
  hex=${hex:0:6}
  # Stock Omarchy track is Tokyo-Night violet #292e42
  if [[ ${hex,,} == "292e42" ]]; then
    needs_apply=1
  fi
fi

[[ $needs_apply -eq 1 ]] || exit 0

exec "$apply" 43pr '#2a2a2a'
