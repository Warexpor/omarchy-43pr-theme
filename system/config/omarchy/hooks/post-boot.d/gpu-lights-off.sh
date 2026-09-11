#!/bin/bash
# Omarchy post-boot hook — runs ~2s after Hyprland starts (see default/hypr/autostart.lua).
# GPU-only, keyboard untouched.
"$HOME/.local/bin/gpu-lights-off.sh" &
