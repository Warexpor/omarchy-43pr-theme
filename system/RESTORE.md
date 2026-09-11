# Same-box machine restore

Agent playbook for rebuilding **this** Omarchy desktop from this git repo after breakage.

Theme-only install (`omarchy theme install`) is **not** enough. Run the phases below (or `./system/restore.sh`).

Related docs:

- [`HARDWARE.md`](HARDWARE.md) — monitor HDR, GPU lights, Limine
- [`secrets.checklist.md`](secrets.checklist.md) — tokens / VPN outbounds (manual)
- [`proxy/README.md`](proxy/README.md) — :10808 / :10809 stack
- [`docs/hdr-on-omarchy.md`](../docs/hdr-on-omarchy.md) — Chromium/Electron on HDR
- [`extras/README.md`](../extras/README.md) — theme-safe HDR/TUI helpers

## Prerequisites

- Fresh or broken Omarchy install on the **same** hardware (DEXP DQ27N1 + RTX 2080 SUPER)
- Network enough to clone this repo and install packages
- Do **not** expect Steam libraries, VMs, browser profiles, or `~/Work` projects from this tree

## One-shot

From the repo root:

```bash
./system/restore.sh                  # full (asks before packages)
./system/restore.sh --dry-run        # show actions only
./system/restore.sh --skip-packages  # configs/wrappers only
./system/restore.sh --skip-proxy     # skip proxy units/templates
```

Then finish [`secrets.checklist.md`](secrets.checklist.md) and enable services.

## Phases (what restore.sh does)

### 1. Packages

- Official: `packages/pacman-explicit.txt` via `omarchy pkg add` / `pacman -S` as available
- AUR: `packages/aur-foreign.txt` via `yay` / `omarchy pkg aur add`
- Tools: `mise install` from `packages/mise-tools.toml` → `~/.config/mise/config.toml`

Skip huge personal data; package lists only install software.

### 2. Theme

```bash
omarchy theme install https://github.com/Warexpor/omarchy-43pr-theme.git
# or, if this clone is already the theme tree linked elsewhere:
omarchy theme set 43pr
```

### 3. Extras (HDR sync + TUI agents)

```bash
./extras/install-hdr-blur.sh --with-hooks
./extras/install-tui-agents.sh --with-hooks
```

### 4. Overlay machine configs

Copy (with `{{HOME}}` → `$HOME`):

| Repo | Destination |
|------|-------------|
| `system/config/hypr/*` | `~/.config/hypr/` |
| `system/config/foot/` | `~/.config/foot/` |
| `system/config/gtk-3.0/` `gtk-4.0/` | `~/.config/gtk-*` |
| `system/config/environment.d/` | `~/.config/environment.d/` |
| `system/config/uwsm/` | `~/.config/uwsm/` |
| `system/config/omarchy/shell.json` | `~/.config/omarchy/shell.json` |
| `system/config/omarchy/bin/` | `~/.config/omarchy/bin/` |
| `system/config/omarchy/hooks/` | `~/.config/omarchy/hooks/` |
| `system/config/systemd/user/` | `~/.config/systemd/user/` |
| `system/bin/*` | `~/.local/bin/` |
| `system/applications/*.desktop` | `~/.local/share/applications/` |
| `system/plugins/warexpor.*` | `~/.config/omarchy/plugins/` |

Then: `hyprctl reload`, `systemctl --user daemon-reload`, `omarchy restart shell`.

### 5. Third-party plugin

See [`plugins/THIRD_PARTY.md`](plugins/THIRD_PARTY.md) — clone `vm.steam-progress`.

### 6. Proxy templates

Install templates/scripts under `~/.local/share/proxy-all/` (see proxy README). **Do not enable** until secrets checklist is done.

### 7. Manual / not vendored

| Item | Why |
|------|-----|
| `herdr` binary | Fat binary — reinstall from upstream |
| OpenCodex token / zen-gateway `.env` | Secrets |
| v2rayN real outbound | Secrets |
| Limine header | Needs root — see `extras/limine/` |
| Steam / Wallpaper Engine assets | Personal bulk |
| `/usr/local/bin` symlinks (`grok-bot`, `marktext`) | Recreate after wrappers exist |

## Verify

```bash
hyprctl monitors
hyprctl configerrors
# Chromium argv should include SDR flags after chromium-sdr-sync:
pgrep -a chrome | head
curl -I --proxy http://127.0.0.1:10808 https://example.com
omarchy theme current
```
