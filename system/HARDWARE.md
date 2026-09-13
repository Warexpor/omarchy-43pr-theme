# Hardware notes (fill in for your machine)

`system/restore.sh` overlays configs from this tree. Values below are
**placeholders** — replace them before relying on GPU lights, tablet udev,
or monitor HDR on a rebuild.

## Display

| Item | Value |
|------|--------|
| Connector | `YOUR_CONNECTOR` (e.g. `HDMI-A-1`) |
| Panel | `YOUR_PANEL` |
| Mode | your preferred mode (example used here: `2560x1440@99.97`) |
| Color | `bitdepth=10`, `cm=hdr` when the panel supports HDR10 |
| SDR map | start from `sdrbrightness=1.3`, `sdrsaturation=1.0`, `sdr_max_luminance=300` |
| Scale | match your desktop scale (example: `1.33333`, `GDK_SCALE=1`) |

Config: `system/config/hypr/monitors.lua`.

HDR Chromium/Electron look is documented in [`docs/hdr-on-omarchy.md`](../docs/hdr-on-omarchy.md). Do **not** raise `sdrbrightness` to fix dim Chrome — use SDR launch flags instead.

## GPU / RGB

| Item | Value |
|------|--------|
| OpenRGB device name | set `OPENRGB_DEVICE` (exact name from `openrgb --list-devices`) |
| Desired state | LEDs off (`Direct` + black) |

Scripts: `system/bin/gpu-lights-off.sh`, `gpu-lights-off-resume.sh`  
Units: `gpu-lights-off.service`, `gpu-lights-off-resume.service`  
Hook: `post-boot.d/gpu-lights-off.sh`

Some GPUs ignore OpenRGB `--mode Off`; `Direct` + black is the durable workaround.

## Bootloader

Limine monochrome branding: [`extras/limine/limine-header.conf`](../extras/limine/limine-header.conf). Apply under `/etc/limine-entry-tool.d/` or the site’s Limine header path (requires root).

## Input / tablet

- fcitx5 (Omarchy user unit)
- OpenTabletDriver (`opentabletdriver` AUR) — set your tablet USB id in `system/udev/` and `OTD_VIDPID` / `OTD_USER` for `system/bin/otd-usb-autostart`
- **USB autostart:** daemon starts on plug, stops on unplug
  - udev: `/etc/udev/rules.d/` from `system/udev/` (edit vendor/product ids first)
  - helper: `/usr/local/bin/otd-usb-autostart` (+ `~/.local/bin/` copy)
  - login oneshot: `opentabletdriver-if-present.service`
  - package unit `opentabletdriver.service` is **disabled** from `graphical-session` so it does not stay running without the tablet
- Config: `system/config/OpenTabletDriver/` → `~/.config/OpenTabletDriver/` (re-export from OTD for your tablet)
- OpenTabletDriver keybinds use US keycodes — keep `us` layout active while using tablet buttons
- Krita: `system/config/kritarc` + `kritashortcutsrc` → `~/.config/`
- Middle-click paste is disabled in Hyprland (`misc.middle_click_paste = false`) and GTK primary-paste is off

## Paths

Restore rewrites `{{HOME}}` → `$HOME`. Do not hard-code a username in tracked files.
