#!/usr/bin/env bash
# Keep Plymouth in sync when switching to (or refreshing) the 43PR theme.
set -euo pipefail

theme="${1:-}"
[[ $theme == "43pr" ]] || exit 0

apply="${HOME}/.config/omarchy/bin/43pr-plymouth-apply"
[[ -x $apply ]] || apply="${HOME}/.local/bin/43pr-plymouth-apply"
[[ -x $apply ]] || exit 0

exec "$apply" 43pr '#2a2a2a'
