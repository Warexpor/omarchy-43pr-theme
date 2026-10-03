# Omarchy 43PR

Pure black monochrome Omarchy theme adapted from [43PR/dotfiles](https://github.com/43PR/dotfiles) — their noctalia kitty palette, translucent bar, and silver/white chrome.

![43PR desktop with the outline bar](preview.png)

## Install the theme

```bash
omarchy theme install https://github.com/Warexpor/omarchy-43pr-theme.git
```

That clones into `~/.config/omarchy/themes/43pr` and applies it. No hooks, plugins, or desktop mutations beyond what Omarchy's theme install already does.

## Install the complete desktop look

After installing the theme, run the setup from its clone:

```bash
~/.config/omarchy/themes/43pr/install-desktop.sh
```

The setup asks once before changing anything, then installs the five public
Omarchy shell plugins, the bundled tray fix (`warexpor.tray`), applies the
matching bar layout, and installs the frosted monochrome screensaver. It
backs up every replaced shell section and file under
`~/.local/state/omarchy-43pr/`.

It deliberately does **not** install packages, proxy settings, HDR overrides,
systemd units, udev rules, or the machine restore.

Undo the visual setup without removing the theme:

```bash
~/.config/omarchy/themes/43pr/uninstall-desktop.sh
```

The plugin sources are independently installable and reviewable:

- [Outline bar](https://github.com/Warexpor/omarchy-43pr-adaptive-bar-plugin)
- [Idle and screensaver service](https://github.com/Warexpor/omarchy-43pr-idle-plugin)
- [Image picker](https://github.com/Warexpor/omarchy-43pr-image-picker-plugin)
- [Media controls](https://github.com/Warexpor/omarchy-43pr-media-plugin)
- [Display controls](https://github.com/Warexpor/omarchy-43pr-monitor-plugin)
- Tray fix: `system/plugins/warexpor.tray/` in this theme (bundled by install-desktop)

## What you get

**Plume** look (designed around the Starship launch wallpaper):

- Clear glass everywhere: shell surfaces use a near-black tint (`#1a1a1a` @ 0.10) over Hyprland blur
- Off-white type (`#ececec`), grayscale ANSI palette, no colour accents
- Selected states are frosted patches (white @ 0.16 with a light edge), never solid fills
- Thin glass rim on windows: `rgba(ffffff99) → rgba(ffffff26)` at 45°
- Transparent bar, lock tokens matched to the glass
- Their wallpaper set under `backgrounds/`

The glass needs the blur settings in [`extras/looknfeel-blur.lua`](extras/looknfeel-blur.lua)
(`ignore_alpha` 0.08, brightness 0.90, no vibrancy/noise) and the Foot values in
[`extras/foot-blur.ini`](extras/foot-blur.ini) (`background=161616`, `alpha=0.08`).

## Showcase

### Frosted screensaver

![43PR frosted wordmark screensaver](showcase/screensaver.webp)

### Tiled windows

![43PR translucent tiled terminal and application windows](showcase/windows.webp)

## Optional extras

`omarchy theme install` regenerates executable theme files (`*.lua`, terminal configs) from `colors.toml`. Hand-copied `hyprland.lua` / `neovim.lua` in this repo are reference only.

Blurred Chromium windows, Foot TUI blur, HDR SDR launch flags, and transparent agent TUIs cannot ship inside a git-installed theme. They live under **[extras/](extras/README.md)** and are **opt-in**:

```bash
./extras/install-hdr-blur.sh              # chromium-sdr-sync only
./extras/install-hdr-blur.sh --with-hooks # + Omarchy post-update/post-boot
./extras/install-tui-agents.sh            # apply TUI templates once
./extras/install-tui-agents.sh --with-hooks
```

Then paste the Hyprland / Foot snippets `install-hdr-blur.sh` points at (also in `extras/looknfeel-blur.lua`).

## HDR notes

Battle-tested notes from running this theme on a real HDR panel:

**[docs/hdr-on-omarchy.md](docs/hdr-on-omarchy.md)**

Includes Chromium/Electron SDR launch flags, Foot blur, and **screen
recording on HDR** (desktop stays in `cm=hdr`; GSR output is washed — grade
in an editor). Wrappers + Capture-menu overrides live under `system/` for
restore.

## Machine restore

This repo also holds a **generic** Omarchy machine restore under `system/`
(Hyprland HDR example, wrappers, plugins, empty package stubs). Configs and
scripts only — no personal media, secrets, or machine fingerprint.

Agent playbook: **[system/RESTORE.md](system/RESTORE.md)**

Private same-box manifests (packages, proxy hostname, OpenRGB device name)
live outside git, e.g. `~/.local/share/omarchy-43pr-private-backup/`.

```bash
./system/restore.sh --dry-run    # preview
./system/restore.sh              # apply (prompts for packages)
```

## Credits

- Visual language and wallpapers: [43PR/dotfiles](https://github.com/43PR/dotfiles)
- Wallpapers also listed at https://wallhaven.cc/user/43pr
- Built for [Omarchy](https://omarchy.org/)

## License

[MIT](LICENSE)
