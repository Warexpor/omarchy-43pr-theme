# Secrets checklist (not in git)

Fill these **before** enabling proxy / OpenCodex services. Nothing below is stored in this repo.

## Required for network proxy

- [ ] **v2rayN subscription / outbound** — re-import in the GUI so `127.0.0.1:10808` works
- [ ] If using standalone `proxy-all.service`: replace the placeholder outbound in `~/.local/share/proxy-all/xray-config.json` (start from `proxy/xray-config.template.json`)
- [ ] Confirm `SERVER_DOMAIN` in `proxy-all-on.sh` still matches your provider (iptables must exclude it or you loop)

## Optional agent / gateway services

- [ ] `~/.opencodex/service-api-token` — required by `opencodex-proxy.service`
- [ ] `~/.config/zen-gateway.env` — required by `zen-gateway.service` (points at `~/Work/MyProjects/opencode-zen-gateway`)
- [ ] Any API keys inside OpenCode / Claude / Cursor account stores (app-managed; not restored from this repo)

## Do not commit

- Live `xray-config.json` with real UUID / Reality keys
- `*.env`, `*token*`, OpenCodex catalog backups
- Browser cookies, Discord/Steam sessions, SSH keys, GPG keys

## Verify after restore

```bash
curl -I --proxy http://127.0.0.1:10808 https://example.com
systemctl --user status dokodemo.service
# optional:
systemctl --user status opencodex-proxy.service zen-gateway.service
```
