# Omarchy 43PR

Pure black monochrome Omarchy theme adapted from [43PR/dotfiles](https://github.com/43PR/dotfiles) — their noctalia kitty palette, translucent bar, and silver/white chrome.

## Install

```bash
omarchy theme install https://github.com/Warexpor/omarchy-43pr-theme.git
```

That clones into `~/.config/omarchy/themes/43pr` and applies it.

## What you get

- Near-black UI with grayscale ANSI colors (from their noctalia theme)
- Translucent bar (`#141414` @ 50% alpha), white type
- White/silver active borders via `colors.toml`
- Their wallpaper set under `backgrounds/`
- Lock tokens tuned toward their hyprlock white gradients

## Notes

`omarchy theme install` regenerates executable theme files (`*.lua`, terminal configs) from `colors.toml`. Hand-copied `hyprland.lua` / `neovim.lua` in this repo are optional reference only for manual installs.

Git-installed themes cannot ship Lua, so **rounded corners** belong in your user Hyprland config. Example `~/.config/hypr/looknfeel.lua`:

```lua
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
  },
})

hl.config({
  decoration = {
    rounding = 12,
    rounding_power = 2,
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      ignore_opacity = true,
    },
  },
})
```

Then `hyprctl reload`.

## HDR on Omarchy

Battle-tested notes from running this theme on a real HDR panel (Chromium/Electron
dimness, `sdrbrightness` traps, Foot blur, desktop-file landmines):

**[docs/hdr-on-omarchy.md](docs/hdr-on-omarchy.md)**

Also symlinked at `~/.config/omarchy/docs/hdr-on-omarchy.md` on the machine that
developed it.

## Credits

- Visual language and wallpapers: [43PR/dotfiles](https://github.com/43PR/dotfiles)
- Wallpapers also listed at https://wallhaven.cc/user/43pr
- Built for [Omarchy](https://omarchy.org/)
