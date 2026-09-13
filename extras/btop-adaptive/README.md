# btop adaptive ink

btop is a TUI, so it cannot do per-pixel contrast like the Omarchy bar shader.
This script samples the current wallpaper luminance and writes either a
**light-ink** or **dark-ink** monochrome `btop.theme`, then sends `SIGUSR2`
so running btop instances reload.

Installed on this machine as:
- `~/.config/omarchy/bin/btop-adaptive-ink`
- `~/.config/omarchy/hooks/theme-set.d/btop-adaptive-ink-hook.sh`
- systemd user path units `btop-adaptive-ink.path` (+ dir watcher)

`btop.conf` should use `color_theme = "current"` with
`theme_background = false` so the wallpaper shows through the terminal.
