#!/usr/bin/env bash
# Stock Omarchy leaves Plymouth progress_box.png as Tokyo-Night violet, and
# `omarchy plymouth set` restores that asset. If 43PR is the active Plymouth
# theme but the track is still tinted, invite a one-command retint.
set -euo pipefail

current=$(omarchy plymouth current 2>/dev/null || true)
[[ $current == "43pr" ]] || exit 0

box=/usr/share/plymouth/themes/omarchy/progress_box.png
[[ -f $box ]] || exit 0

hex=$(magick "$box" -format '%[hex:u.p{0,0}]' info: 2>/dev/null || true)
hex=${hex#\#}
hex=${hex:0:6}
[[ ${hex,,} == "292e42" ]] || exit 0

apply="${HOME}/.config/omarchy/bin/43pr-plymouth-apply"
[[ -x $apply ]] || apply="${HOME}/.local/bin/43pr-plymouth-apply"
[[ -x $apply ]] || exit 0

if omarchy-done ensure 43pr-plymouth-mono-track-invite 2>/dev/null; then
  omarchy-notification-send -u normal -g "󰸉" "43PR Plymouth track" \
    "Boot progress track is still violet. Click to retint it gray." \
    --exec omarchy-launch-floating-terminal-with-presentation "$apply"
fi
