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

So **blurred Chromium windows**, **Foot TUI alpha/blur**, **HDR SDR launch
flags**, and **TUI agent transparency** do not auto-apply from the theme alone.
They live here as optional helpers.

Nothing here registers Omarchy hooks unless you pass `--with-hooks`.

## Quick install

From a clone (or from `~/.config/omarchy/themes/43pr` after theme install):

```bash
./extras/install-hdr-blur.sh              # binary only
./extras/install-tui-agents.sh            # apply once

# Optional Omarchy automation:
./extras/install-hdr-blur.sh --with-hooks
./extras/install-tui-agents.sh --with-hooks
```

`install-hdr-blur.sh` installs `chromium-sdr-sync`, runs it once, then prints
the three manual paste targets (Hyprland + Foot). With `--with-hooks` it also
registers Omarchy `post-update` / `post-boot` hooks when the CLI is present.

`install-tui-agents.sh` writes transparent configs for OpenCode / Grok / Claude
(and Herdr). With `--with-hooks` it registers an Omarchy `theme-set` hook that
re-syncs when you re-apply `43pr` (no-ops for other themes).

## Files

| File | Purpose |
|------|---------|
| `chromium-sdr-sync` | Idempotent: `*-flags.conf` + auto wrappers for bundled Electron apps |
| `hyprland-blur-chromium.lua` | Opacity / `no_auto_hdr` window rules |
| `looknfeel-blur.lua` | Decoration blur + omarchy layer popup blur |
| `foot-blur.ini` | Foot 1.28+ `[colors-dark]` / `[colors-light]` alpha+blur |
| `gtk-3.0-gtk.css` | 43PR black/white GTK3 chrome (copy → `~/.config/gtk-3.0/gtk.css`) |
| `gtk-4.0-gtk.css` | Same for Nautilus/libadwaita (`~/.config/gtk-4.0/gtk.css`) |
| `install-hdr-blur.sh` | Installer for the sync helper |
| `install-tui-agents.sh` | Installer for agent TUIs |
| `tui-agents/` | Templates (OpenCode theme+plugin, Grok/Claude/Cursor notes) |

### TUI agents — what actually works

| Agent | Fix | Notes |
|-------|-----|-------|
| **OpenCode** | Transparent `43pr` theme + `transparent-logo` plugin | Plugin skips opaque letter-counter fills |
| **Grok Build** | `theme = "terminal"` + `terminal_theme = true` | Built-in; paints no surfaces |
| **Claude Code** | `43PR Transparent` theme | Clears message backgrounds (best-effort) |
| **Herdr** | `theme.name = "terminal"` | Uses `Color::Reset` |
| **Cursor Agent CLI** | Bundle patch + half-block env | Removes opaque prompt fill; re-run after `agent update` |

Full battle notes: [`docs/hdr-on-omarchy.md`](../docs/hdr-on-omarchy.md).
