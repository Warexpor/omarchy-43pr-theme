#!/bin/bash
# theme-set re-copies shell.toml with the static 0.75 fill; retune it for the
# wallpaper. The warexpor.tint plugin covers plain wallpaper changes.
[[ ${1:-} == 43pr ]] || exit 0
exec "$HOME/.config/omarchy/bin/43pr-adaptive-tint"
