# 43PR adaptive tint

Service plugin that keeps the 43PR shell glass readable on any wallpaper.
On every wallpaper or theme change it runs `43pr-adaptive-tint`, which samples
the wallpaper (brightest cell of a 3x3 grid, 85th percentile) and sets
`background-alpha` for popups, tooltip, notifications, launcher, menu, polkit
and lock: 0.10 clear glass on dark wallpapers, up to 0.75 smoked on bright ones.

Only acts while the 43pr theme is current. Without it the theme's static
0.75 applies. Check the last pick in `~/.cache/omarchy/43pr-adaptive-tint`,
or dry-run with `43pr-adaptive-tint --print`.

## Install

Bundled by `install-desktop.sh` from this theme tree into
`~/.config/omarchy/plugins/warexpor.tint/`, together with
`~/.config/omarchy/bin/43pr-adaptive-tint` and the theme-set hook.
