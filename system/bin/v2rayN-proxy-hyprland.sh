#!/bin/bash
# Durable proxy toggle for v2rayN on Omarchy/Hyprland (Arch)
# v2rayN calls: $0 <manual|none> [ip port ignore_hosts]
# Does 3 layers so it survives reboot:
#  1. gsettings (GTK, persistent in dconf)
#  2. systemctl --user set/unset-environment + dbus (runtime, new apps)
#  3. ~/.config/environment.d/proxy.conf (next login persistence)
set -u
MODE=${1:-}
PROXY_IP=${2:-127.0.0.1}
PROXY_PORT=${3:-10808}
IGNORE_HOSTS=${4:-localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,opencode.ai,api.opencode.ai}
ENV_FILE="$HOME/.config/environment.d/proxy.conf"

trim() {
    local -n ref=$1
    ref="${ref#"${ref%%[![:space:]]*}"}"
    ref="${ref%"${ref##*[![:space:]]}"}"
}
build_gsettings_array() {
    [[ -z "$1" ]] && echo "[]" && return
    local host joined hosts=()
    IFS=',' read -ra parts <<< "$1"
    for host in "${parts[@]}"; do trim host; [[ -n "$host" ]] && hosts+=("$host"); done
    [[ ${#hosts[@]} -eq 0 ]] && echo "[]" && return
    printf -v joined "'%s'," "${hosts[@]}"
    echo "[${joined%,}]"
}

if ! [[ "$MODE" =~ ^(manual|none)$ ]]; then echo "Invalid mode: $MODE" >&2; exit 1; fi
mkdir -p "$(dirname "$ENV_FILE")"

if [ "$MODE" == "manual" ]; then
    HTTP="http://$PROXY_IP:$PROXY_PORT"
    SOCKS="socks5h://$PROXY_IP:$PROXY_PORT"
    # 1. GTK persistent
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.system.proxy mode "manual" 2>&1 || true
        for p in http https ftp socks; do
            gsettings set org.gnome.system.proxy.$p host "$PROXY_IP" 2>&1 || true
            gsettings set org.gnome.system.proxy.$p port "$PROXY_PORT" 2>&1 || true
        done
        gsettings set org.gnome.system.proxy ignore-hosts "$(build_gsettings_array "$IGNORE_HOSTS")" 2>&1 || true
    fi
    # 2. runtime for new apps (explicit values: never inherit this shell's env)
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user set-environment http_proxy="$HTTP" https_proxy="$HTTP" all_proxy="$SOCKS" no_proxy="$IGNORE_HOSTS" 2>&1 || true
        systemctl --user set-environment HTTP_PROXY="$HTTP" HTTPS_PROXY="$HTTP" ALL_PROXY="$SOCKS" NO_PROXY="$IGNORE_HOSTS" 2>&1 || true
        command -v dbus-update-activation-environment >/dev/null 2>&1 && env http_proxy="$HTTP" https_proxy="$HTTP" all_proxy="$SOCKS" no_proxy="$IGNORE_HOSTS" HTTP_PROXY="$HTTP" HTTPS_PROXY="$HTTP" ALL_PROXY="$SOCKS" NO_PROXY="$IGNORE_HOSTS" dbus-update-activation-environment --systemd http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY 2>&1 || true
    fi
    # 3. next-login persistence
    cat > "$ENV_FILE" <<EOF
http_proxy=$HTTP
https_proxy=$HTTP
all_proxy=$SOCKS
HTTP_PROXY=$HTTP
HTTPS_PROXY=$HTTP
ALL_PROXY=$SOCKS
no_proxy=$IGNORE_HOSTS
NO_PROXY=$IGNORE_HOSTS
EOF
    echo "proxy ON : $HTTP / $SOCKS"
else
    if command -v gsettings >/dev/null 2>&1; then gsettings set org.gnome.system.proxy mode "none" 2>&1 || true; fi
    rm -f "$ENV_FILE"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user unset-environment http_proxy https_proxy all_proxy no_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY 2>&1 || true
        # No dbus-update-activation-environment here: it would re-import this
        # shell's (possibly stale) proxy env back into systemd. Reload keeps
        # unit files in sync; the unset above is what clears the manager env.
        systemctl --user daemon-reload 2>&1 || true
    fi
    echo "proxy OFF"
fi
echo "NOTE: restart Chromium/Chrome/Electron to pick up change." >&2
