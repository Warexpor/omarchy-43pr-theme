#!/bin/bash
# Re-apply GPU-only lights-off after suspend/resume.
# Listens for logind PrepareForSleep(false) == resume finished.
# Uses same dbus-monitor pattern as omarchy-system-sleep-monitor, but user-level (no sudo).

set -u
OFF_SCRIPT="$HOME/.local/bin/gpu-lights-off.sh"

dbus-monitor --system "type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" 2>/dev/null | while IFS= read -r line; do
  if [[ "$line" == *"boolean false"* ]]; then
    # GPU needs a moment after resume before i2c is usable
    sleep 4
    bash "$OFF_SCRIPT"
  fi
done
