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

For a closer window layout match (gaps + light blur like their Hyprland), put this in `~/.config/hypr/looknfeel.lua`:

```lua
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 3,
  },
})

hl.config({
  decoration = {
    blur = {
      enabled = true,
      size = 5,
      passes = 1,
      vibrancy = 0.2,
      ignore_opacity = true,
    },
    shadow = {
      enabled = true,
      range = 8,
      render_power = 3,
    },
  },
})
```

Then reload Hyprland (`hyprctl reload`).

## Credits

- Visual language and wallpapers: [43PR/dotfiles](https://github.com/43PR/dotfiles)
- Wallpapers also listed at https://wallhaven.cc/user/43pr
- Built for [Omarchy](https://omarchy.org/)
