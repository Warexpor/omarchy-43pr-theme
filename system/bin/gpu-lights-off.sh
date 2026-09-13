#!/bin/bash
# GPU-only lights off via OpenRGB.
# Set OPENRGB_DEVICE to the exact name from: openrgb --list-devices
# Intentionally targets ONLY that device — never a keyboard/motherboard entry.
#
# OpenRGB settings are volatile on many GPUs (firmware re-enables LEDs on
# reboot / resume), so this re-runs on boot AND on resume (systemd user units).

set -euo pipefail

DEVICE="${OPENRGB_DEVICE:-}"
if [[ -z "$DEVICE" ]]; then
  echo "gpu-lights-off: set OPENRGB_DEVICE to your GPU's OpenRGB name" >&2
  exit 1
fi

# Small delay lets i2c + user session settle when run from boot hooks
sleep 2
# NOTE: --mode Off is broken on some cards in OpenRGB 1.0rc3 (stays Rainbow).
# Direct + black is the durable workaround.
exec /usr/bin/openrgb --device "$DEVICE" --mode Direct --color 000000,000000,000000 >/dev/null 2>&1
