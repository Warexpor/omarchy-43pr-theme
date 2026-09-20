#!/bin/sh
# Package entrypoint (/usr/bin/grok-bot). HDR CM via Hyprland reference_luminance.
# Chromium bundles fontconfig 2.17; Arch's caches are from 2.18+.
export FONTCONFIG_NO_CHECK_CACHE_VERSION=1

PROXY_FLAG="${XDG_DATA_HOME:-$HOME/.local/share}/proxy-all/system-proxy.on"
proxy_on=0
if [ -f "$PROXY_FLAG" ]; then
  proxy_on=1
elif command -v gsettings >/dev/null 2>&1; then
  [ "$(gsettings get org.gnome.system.proxy mode 2>/dev/null)" = "'manual'" ] && proxy_on=1
fi

PROXY_ARGS=""
if [ "$proxy_on" -eq 1 ]; then
  export http_proxy="${http_proxy:-http://127.0.0.1:10808}"
  export https_proxy="${https_proxy:-http://127.0.0.1:10808}"
  export all_proxy="${all_proxy:-socks5h://127.0.0.1:10808}"
  export HTTP_PROXY="${HTTP_PROXY:-$http_proxy}"
  export HTTPS_PROXY="${HTTPS_PROXY:-$https_proxy}"
  export ALL_PROXY="${ALL_PROXY:-$all_proxy}"
  export no_proxy="${no_proxy:-localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12}"
  export NO_PROXY="${NO_PROXY:-$no_proxy}"
  PROXY_ARGS="--proxy-server=http://127.0.0.1:10808 --proxy-bypass-list=localhost,127.0.0.0/8,::1 --disable-quic"
fi

# shellcheck disable=SC2086
exec "/opt/Grok Bot/grok-bot" $PROXY_ARGS "$@"
