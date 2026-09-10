#!/usr/bin/env bash
# Apply 43PR TUI-agent transparency configs.
#
# Safe to re-run. Called by:
#   - extras/install-tui-agents.sh (manual / fresh setup)
#   - Omarchy theme-set hook (when theme slug is 43pr)
#
# Agents we can actually fix today:
#   OpenCode  — transparent theme + logo plugin (skips opaque letter counters)
#   Grok      — built-in theme = "terminal" (+ feature flag)
#   Claude    — theme with transparent message backgrounds (best-effort)
#   Herdr     — theme.name = "terminal" if config exists
#
# Cursor Agent CLI: no transparent paint API — we patch the bundle (see cursor/README.md).
set -euo pipefail

THEME_SLUG="${1:-}"

# theme-set hook passes the slug as $1; only act for 43pr (and empty = force).
if [[ -n "$THEME_SLUG" && "$THEME_SLUG" != "43pr" ]]; then
  exit 0
fi

log() { printf 'tui-agents: %s\n' "$*"; }

# Resolve template tree. Prefer the stable share copy (survives hook relocate),
# then the Omarchy-installed theme, then a live git checkout.
resolve_src() {
  local here candidates c
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  candidates=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/43pr-tui-agents"
    "${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/43pr/extras/tui-agents"
    "$here/.."
  )
  for c in "${candidates[@]}"; do
    if [[ -f "$c/opencode/themes/43pr.json" ]]; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

SRC="$(resolve_src)" || {
  echo "missing 43pr tui-agents templates (run extras/install-tui-agents.sh)" >&2
  exit 1
}

# --- OpenCode ---------------------------------------------------------------
if command -v opencode >/dev/null 2>&1 || [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ]]; then
  OC="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  mkdir -p "$OC/themes" "$OC/plugins"

  install -m 644 "$SRC/opencode/themes/43pr.json" "$OC/themes/43pr.json"
  install -m 644 "$SRC/opencode/plugins/transparent-logo.tsx" "$OC/plugins/transparent-logo.tsx"

  # Merge theme + plugin into tui.json without clobbering other keys.
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$OC/tui.json" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
data = {}
if path.exists():
    try:
        data = json.loads(path.read_text())
    except Exception:
        data = {}
data.setdefault("$schema", "https://opencode.ai/tui.json")
data["theme"] = "43pr"
plugins = data.get("plugin") or []
if not isinstance(plugins, list):
    plugins = [plugins]
wanted = "./plugins/transparent-logo.tsx"
if wanted not in plugins and not any(
    (isinstance(p, str) and p.endswith("transparent-logo.tsx"))
    or (isinstance(p, list) and p and str(p[0]).endswith("transparent-logo.tsx"))
    for p in plugins
):
    plugins.append(wanted)
data["plugin"] = plugins
path.write_text(json.dumps(data, indent=2) + "\n")
PY
  else
    printf '%s\n' '{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "43pr",
  "plugin": ["./plugins/transparent-logo.tsx"]
}' > "$OC/tui.json"
  fi

  # Peers for the logo plugin (bun install is idempotent).
  if [[ -f "$OC/package.json" ]] && command -v bun >/dev/null 2>&1; then
    (cd "$OC" && bun add -d '@opentui/core@>=0.4.5' '@opentui/solid@>=0.4.5' 'solid-js@*' >/dev/null 2>&1) || true
  elif [[ ! -f "$OC/package.json" ]] && command -v bun >/dev/null 2>&1; then
    printf '%s\n' '{
  "dependencies": {
    "@opencode-ai/plugin": "latest",
    "@opentui/core": ">=0.4.5",
    "@opentui/solid": ">=0.4.5",
    "solid-js": "*"
  }
}' > "$OC/package.json"
    (cd "$OC" && bun install >/dev/null 2>&1) || true
  fi

  log "OpenCode → theme 43pr + transparent-logo plugin"
else
  log "OpenCode skipped (not installed)"
fi

# --- Grok Build -------------------------------------------------------------
if command -v grok >/dev/null 2>&1 || [[ -f "$HOME/.grok/config.toml" ]]; then
  GROK="$HOME/.grok/config.toml"
  mkdir -p "$HOME/.grok"
  if [[ ! -f "$GROK" ]]; then
    cat > "$GROK" <<'EOF'
[features]
terminal_theme = true

[ui]
theme = "terminal"
EOF
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$GROK" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text() if path.exists() else ""

def ensure_section(src: str, header: str, key: str, value: str) -> str:
    import re
    # Already set?
    if re.search(rf"(?m)^\s*{re.escape(key)}\s*=\s*{re.escape(value)}\s*$", src):
        return src
    # Section exists — replace key or append under it
    m = re.search(rf"(?m)^\[{re.escape(header)}\]\s*$", src)
    if not m:
        return src.rstrip() + f"\n\n[{header}]\n{key} = {value}\n"
    start = m.end()
    nxt = re.search(r"(?m)^\[", src[start:])
    end = start + nxt.start() if nxt else len(src)
    body = src[start:end]
    if re.search(rf"(?m)^\s*{re.escape(key)}\s*=", body):
        body = re.sub(rf"(?m)^\s*{re.escape(key)}\s*=.*$", f"{key} = {value}", body, count=1)
    else:
        body = "\n" + f"{key} = {value}\n" + body.lstrip("\n")
    return src[:start] + body + src[end:]

text = ensure_section(text, "features", "terminal_theme", "true")
text = ensure_section(text, "ui", "theme", '"terminal"')
path.write_text(text if text.endswith("\n") else text + "\n")
PY
  else
    log "Grok: install python3 to merge config, or edit ~/.grok/config.toml manually"
  fi
  log "Grok → theme terminal (transparent surfaces)"
else
  log "Grok skipped (not installed)"
fi

# --- Herdr ------------------------------------------------------------------
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml" ]]; then
  HERDR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$HERDR" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
text = path.read_text()
if re.search(r"(?m)^\[theme\]", text):
    if re.search(r"(?m)^\s*name\s*=", text):
        text = re.sub(r"(?m)^(\s*name\s*=\s*).*$", r'\1"terminal"', text, count=1)
    else:
        text = re.sub(r"(?m)^(\[theme\]\s*)$", r'\1\nname = "terminal"', text, count=1)
else:
    text = text.rstrip() + '\n\n[theme]\nname = "terminal"\n'
path.write_text(text if text.endswith("\n") else text + "\n")
PY
  fi
  log "Herdr → theme terminal"
fi

# --- Claude Code ------------------------------------------------------------
if command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]; then
  mkdir -p "$HOME/.claude/themes"
  install -m 644 "$SRC/claude/43pr-transparent.json" "$HOME/.claude/themes/43pr-transparent.json"
  # Best-effort: point settings at the theme if settings is empty/object.
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import json
from pathlib import Path
p = Path.home() / ".claude" / "settings.json"
data = {}
if p.exists():
    try:
        data = json.loads(p.read_text() or "{}")
    except Exception:
        data = {}
# Don't overwrite an explicit non-43pr theme choice.
theme = data.get("theme")
if theme in (None, "", "Omarchy", "omarchy", "dark", "default"):
    data["theme"] = "43PR Transparent"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2) + "\n")
PY
  fi
  log "Claude → theme 43PR Transparent (message backgrounds cleared)"
else
  log "Claude skipped (not installed)"
fi

# --- Cursor Agent CLI -------------------------------------------------------
# No public transparent paint API. We:
#   1. Prefer display.mode=zen
#   2. Patch the installed bundle to drop prompt-bar + user-message fills
#   3. Export AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR (half-block ▄/▀ strips)
CLI_CFG=""
for cand in \
  "${XDG_CONFIG_HOME:-$HOME/.config}/cursor/cli-config.json" \
  "$HOME/.cursor/cli-config.json"
do
  [[ -f "$cand" ]] && CLI_CFG="$cand" && break
done
if [[ -n "$CLI_CFG" ]] && command -v python3 >/dev/null 2>&1; then
  python3 - "$CLI_CFG" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception:
    raise SystemExit(0)
display = data.setdefault("display", {})
if display.get("mode") != "zen":
    display["mode"] = "zen"
    path.write_text(json.dumps(data, indent=2) + "\n")
PY
fi

PATCH="$SRC/bin/patch-cursor-agent-prompt.sh"
if [[ -f "$PATCH" ]]; then
  chmod +x "$PATCH" || true
  "$PATCH" || log "Cursor Agent patch skipped/failed"
else
  log "Cursor Agent patch script missing under $SRC/bin"
fi

if command -v agent >/dev/null 2>&1 || command -v cursor-agent >/dev/null 2>&1 || [[ -n "$CLI_CFG" ]]; then
  log "Cursor Agent → zen + transparent prompt/user-message patch"
else
  log "Cursor Agent skipped (not installed)"
fi

log "done. Relaunch agent TUIs in a new Foot window to pick up changes."
