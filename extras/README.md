# Optional extras (not auto-applied)

For a **full same-box rebuild** (Hyprland, proxies, plugins, packages), use
[`system/RESTORE.md`](../system/RESTORE.md) / `system/restore.sh` instead.
This `extras/` tree is the theme-safe HDR/TUI subset only.

`omarchy theme install` keeps colors, wallpapers, `shell.toml`, etc. — but it
**drops / regenerates** anything that runs code:

| Dropped on install | Why |
|--------------------|-----|
| `*.lua` | Hyprland / Neovim load theme Lua at login |
| `alacritty.toml`, `foot.ini`, `ghostty.conf`, `kitty.conf` | Terminal configs name launch programs |
| `vscode.json` | Can trigger extension installs |

So **blurred Chromium windows**, **Foot TUI alpha/blur/`alpha-mode=all`**, and
**TUI agent transparency** do not auto-apply from the theme alone. They live
here as optional helpers.

**HDR Chromium brightness** is no longer fixed by launch-flag crutches on this
machine. Use compositor `reference_luminance` (local Hyprland package in
`~/Work/MyProjects/hyprland-hdr-fix`). See
[`docs/hdr-on-omarchy.md`](../docs/hdr-on-omarchy.md).
`chromium-sdr-sync` remains only as a **legacy workaround** for stock Hyprland
without that patch.

Nothing here registers Omarchy hooks unless you pass `--with-hooks`.

## Quick install

From a clone (or from `~/.config/omarchy/themes/43pr` after theme install):

```bash
./extras/install-hdr-blur.sh              # blur helpers + (legacy) sync binary
./extras/install-tui-agents.sh            # apply once

# Optional Omarchy automation:
./extras/install-hdr-blur.sh --with-hooks   # only if you still need SDR flags
./extras/install-tui-agents.sh --with-hooks
```

`install-hdr-blur.sh` installs `chromium-sdr-sync` and prints the manual paste
targets (Hyprland + Foot). With `--with-hooks` it also registers Omarchy
`post-update` / `post-boot` hooks. **Skip hooks** if you already run patched
Hyprland with `reference_luminance` — re-enabling them would re-inject SDR
kill-switches and disable in-browser HDR.

`install-tui-agents.sh` writes transparent configs for OpenCode / Grok / Claude
(and Herdr). With `--with-hooks` it registers an Omarchy `theme-set` hook that
re-syncs when you re-apply `43pr` (no-ops for other themes).

## Files

| File | Purpose |
|------|---------|
| `chromium-sdr-sync` | **Legacy:** `*-flags.conf` + Electron wrappers that disable Wayland CM |
| `hyprland-blur-chromium.lua` | Opacity / `no_auto_hdr` window rules |
| `looknfeel-blur.lua` | Decorations blur + omarchy layer popup blur |
| `foot-blur.ini` | Foot 1.28+ `[colors-dark]` / `[colors-light]` alpha + `alpha-mode=all` + blur |
| `foot-selection-alpha.patch` | Foot: frost text selection under `alpha-mode=all` (stock paints opaque) |
| `install-foot-selection-alpha.sh` | Build+install patched foot + Omarchy `post-update` rebuild hook |
| `gtk-3.0-gtk.css` | 43PR black/white GTK3 chrome (copy → `~/.config/gtk-3.0/gtk.css`); popovers stay transparent |
| `gtk-4.0-gtk.css` | Same for Nautilus/libadwaita (`~/.config/gtk-4.0/gtk.css`); opaque popover fill causes the black square behind rounded menus |
| `install-hdr-blur.sh` | Installer for blur helpers (+ optional legacy sync) |
| `install-tui-agents.sh` | Installer for agent TUIs |
| `tui-agents/` | Templates (OpenCode theme+plugin, Grok/Claude/Cursor notes) |

### TUI glass (systemic)

Paste [`foot-blur.ini`](foot-blur.ini) into `~/.config/foot/foot.ini` (or keep the
same keys under `[colors-dark]` / `[colors-light]`). **`alpha-mode=all`** is the
important line: without it, Foot only frosts the terminal default background, and
every TUI that paints explicit cell colors (gum, agents, …) stays as opaque plates.

**Selection highlight still punches opaque on stock Foot** (deliberate after
upstream #2073 — selections skip `alpha`). Fix:

```bash
./extras/install-foot-selection-alpha.sh           # build + register post-update hook
./extras/install-foot-selection-alpha.sh --force   # rebuild now
./extras/install-foot-selection-alpha.sh --no-hooks
```

That builds Foot with [`foot-selection-alpha.patch`](foot-selection-alpha.patch),
installs to `~/.local/bin/foot`, shadows it from `~/.config/omarchy/bin/foot`, and
pins `~/.local/share/applications/foot.desktop`. A durable copy lives under
`~/.local/share/43pr-foot/`; the Omarchy **post-update** hook rebuilds when
`pacman`’s `foot` package version changes (skips if the stamp already matches).
Open a **new** window after install/rebuild. Theme `selection = "#666666"` stays
readable once the highlight shares window alpha (darker `#2a2a2a` vanishes).

Per-app templates under `tui-agents/` remain optional polish (logo letter-counters,
Cursor bundle quirks). They are no longer required for basic glass.

### TUI agents — what actually works

| Agent | Fix | Notes |
|-------|-----|-------|
| **OpenCode** | Transparent `43pr` theme + `transparent-logo` plugin | Plugin skips opaque letter-counter fills |
| **Grok Build** | `theme = "terminal"` + `terminal_theme = true` | Built-in; paints no surfaces |
| **Claude Code** | `43PR Transparent` theme | Clears message backgrounds (best-effort) |
| **Herdr** | `theme.name = "terminal"` | Uses `Color::Reset` |
| **Cursor Agent CLI** | Bundle patch + half-block env | Removes opaque prompt fill; re-run after `agent update` |

Full battle notes: [`docs/hdr-on-omarchy.md`](../docs/hdr-on-omarchy.md).
