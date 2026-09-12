# Hardware notes (same box)

Captured for rebuild on **this** machine only. Other hardware will need monitor / OpenRGB edits.

## Display

| Item | Value |
|------|--------|
| Connector | `HDMI-A-1` |
| Panel | DEXP DQ27N1 (Shenzhen KTC) |
| Mode | `2560x1440@99.97` |
| Color | `bitdepth=10`, `cm=hdr` |
| SDR map | `sdrbrightness=1.3`, `sdrsaturation=1.0`, `sdr_max_luminance=300` |
| Scale | `1.33333` (`GDK_SCALE=1`) |

Config: `system/config/hypr/monitors.lua`.

HDR Chromium/Electron look is documented in [`docs/hdr-on-omarchy.md`](../docs/hdr-on-omarchy.md). Do **not** raise `sdrbrightness` to fix dim Chrome — use SDR launch flags instead.

## GPU / RGB

| Item | Value |
|------|--------|
| GPU | NVIDIA GeForce RTX 2080 SUPER (TU104) |
| OpenRGB device name | `MSI GeForce RTX 2080 SUPER Gaming X Trio` |
| Desired state | LEDs off (`Direct` + black) |

Scripts: `system/bin/gpu-lights-off.sh`, `gpu-lights-off-resume.sh`  
Units: `gpu-lights-off.service`, `gpu-lights-off-resume.service`  
Hook: `post-boot.d/gpu-lights-off.sh`

OpenRGB `--mode Off` is broken on this card in 1.0rc3; scripts use `--mode Direct --color 000000,...`.

## Bootloader

Limine monochrome branding: [`extras/limine/limine-header.conf`](../extras/limine/limine-header.conf). Apply under `/etc/limine-entry-tool.d/` or the site’s Limine header path (requires root).

## Input / tablet

- fcitx5 (Omarchy user unit)
- OpenTabletDriver (`opentabletdriver` AUR) — XP-Pen Deco 01 V3 (`28bd:0947`), Artist Mode
- **USB autostart:** daemon starts on plug, stops on unplug
  - udev: `/etc/udev/rules.d/99-xppen-deco01v3-otd.rules` (from `system/udev/`)
  - helper: `/usr/local/bin/otd-usb-autostart` (+ `~/.local/bin/` copy)
  - login oneshot: `opentabletdriver-if-present.service` (if already plugged at session start)
  - package unit `opentabletdriver.service` is **disabled** from `graphical-session` so it does not stay running without the tablet
- Config: `system/config/OpenTabletDriver/` → `~/.config/OpenTabletDriver/`
- Preset `krita-pixel` (express keys, top → bottom):

  | # | Binding | Krita action |
  |---|---------|--------------|
  | 1 | Space (hold) | Pan — hold button, drag with pen tip |
  | 2 | Ctrl (hold) | Color sample — hold button, tap with pen tip |
  | 3 | Shift (hold) | Brush size — hold button, drag with pen tip |
  | 4 | F7 | Eraser mode |
  | 5 | Ctrl+Z | Undo |
  | 6 | Ctrl+Shift+Z | Redo |
  | 7 | Ctrl+= | Zoom in |
  | 8 | Ctrl+- | Zoom out |

- Apply live: `otd loadsettings ~/.config/OpenTabletDriver/settings.json` or `otd applypreset krita-pixel`
- OpenTabletDriver keybinds use US keycodes — keep `us` layout active (not `ru`) while using tablet buttons
- If Ctrl/Space/Shift stick: tap that express key once, or `systemctl --user restart opentabletdriver`
- Middle-click paste is disabled in Hyprland (`misc.middle_click_paste = false`) and GTK primary-paste is off; bindings also clear primary on MMB for Electron
- Krita: `system/config/kritarc` + `kritashortcutsrc` → `~/.config/` (nearest-neighbour zoom, pixel grid; `B`/`E`/`P`; F7 eraser; `show_brush_presets` unbound from F6)
- Brush size uses stock canvas **Change Primary Setting** (Shift+drag); tablet button 3 sends Shift
- After changing Krita shortcut / canvas input files, restart Krita
- OpenRazer / Polychromatic for keyboard (do not point GPU-lights scripts at keyboard)

## Paths that assume this home

Restore rewrites `{{HOME}}` → `$HOME`. Same-box default is `/home/warexpor`.
