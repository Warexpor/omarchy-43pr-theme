#!/bin/bash
# GPU-only lights off — MSI GeForce RTX 2080 SUPER Gaming X Trio
# WARNING: intentionally targets ONLY the GPU by exact name.
# Never touches Gaming Keyboard (Winbond) or Motherboard (B560M DS3H V2).
# Reason previous attempts were not durable: OpenRGB settings are volatile —
# GPU firmware re-enables LEDs on reboot / suspend-resume, so this must
# re-run on boot AND on resume (see systemd user services).

# Small delay lets i2c + user session settle when run from boot hooks
sleep 2
# NOTE: --mode Off is broken for this card in OpenRGB 1.0rc3 (stays Rainbow).
# Direct + black is proven to switch controller to [Direct] (verified via --list-devices).
exec /usr/bin/openrgb --device "MSI GeForce RTX 2080 SUPER Gaming X Trio" --mode Direct --color 000000,000000,000000 >/dev/null 2>&1
