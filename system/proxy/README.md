# Proxy stack (this machine)

Local SOCKS/HTTP on **127.0.0.1:10808**, optional transparent redirect on **:10809**.

```text
Apps / environment.d
        |
        v
  HTTP/SOCKS 127.0.0.1:10808  <--- v2rayN (primary) OR proxy-all.service (standalone xray)
        ^
        |
  dokodemo :10809  (optional transparent iptables REDIRECT)
```

## Pieces

| Piece | Role |
|-------|------|
| **v2rayN** (`v2rayn-bin`) | GUI + mixed inbound on `:10808`. Source of truth for real outbounds. |
| `v2rayN-proxy-hyprland.sh` | Durable proxy toggle: gsettings + user env + `environment.d/proxy.conf` |
| `environment.d/proxy.conf` | Login-persistent `HTTP(S)_PROXY` / `ALL_PROXY` |
| `dokodemo.service` | xray dokodemo-door on `:10809` -> SOCKS `:10808` |
| `proxy/scripts/proxy-all-on.sh` | iptables NAT REDIRECT of outbound TCP into `:10809` |
| `proxy-all.service` | Optional standalone xray (template outbounds) — usually unused when v2rayN owns `:10808` |
| Desktop overrides | Chromium / Chrome / Cursor / Discord Exec lines pin `--proxy-server=http://127.0.0.1:10808` |

## Restore (after secrets checklist)

1. Install `v2rayn-bin` (see `packages/aur-foreign.txt`).
2. Export / re-import your subscription in v2rayN so `:10808` works.
3. Copy templates:

```bash
mkdir -p ~/.local/share/proxy-all
# Fill real outbound first (see secrets.checklist.md), then:
# cp system/proxy/xray-config.template.json ~/.local/share/proxy-all/xray-config.json
cp system/proxy/dokodemo-config.template.json ~/.local/share/proxy-all/dokodemo-config.json
cp system/proxy/scripts/* ~/.local/share/proxy-all/
chmod +x ~/.local/share/proxy-all/*.sh
```

4. Install systemd units from `system/config/systemd/user/` (`dokodemo.service`, optionally `proxy-all.service`).
5. `systemctl --user daemon-reload && systemctl --user enable --now dokodemo.service`
6. Only if you need transparent capture: `~/.local/share/proxy-all/proxy-all-on.sh` (needs sudo).

## Ports

| Port | Protocol | Owner |
|------|----------|-------|
| 10808 | SOCKS5 + HTTP mixed | v2rayN (preferred) |
| 10809 | dokodemo-door (transparent) | dokodemo.service |
| 10100 | OpenCodex `ocx` | opencodex-proxy.service |
