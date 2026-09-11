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
- OpenTabletDriver (`opentabletdriver` AUR)
- OpenRazer / Polychromatic for keyboard (do not point GPU-lights scripts at keyboard)

## Paths that assume this home

Restore rewrites `{{HOME}}` → `$HOME`. Same-box default is `/home/warexpor`.
