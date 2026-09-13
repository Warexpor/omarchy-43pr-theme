#!/usr/bin/env bash
# Patch Cursor Agent CLI for Foot transparency + readable white text.
#
# Upstream paints:
#   1. An opaque Ink backgroundColor fill on the prompt row
#   2. Optional ▄/▀ "half-block" padding rows in that same color
#   3. chalk.dim / Ink dimColor on placeholder / ghost / empty-prompt chrome
#   4. An opaque Ink backgroundColor fill on user-message bubbles
#      (blended from OSC 11 + theme constants in user-message-ui.tsx)
#
# There is no cli-config knob, so we patch the installed bundle. Idempotent.
# Re-run after `agent update`.
set -euo pipefail

log() { printf 'cursor-agent-patch: %s\n' "$*"; }

FILL_OLD='backgroundColor:e,paddingLeft:1,paddingY:s?0:1'
USER_MSG_FILL_OLD='backgroundColor:v,paddingLeft:1,paddingRight:5,paddingY:1,marginX:1,width:h.width-2'
HALF_OLD='const s=!(0,W.t)(process.env.AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR)&&!(!(null===(i=process.stdout)||void 0===i?void 0:i.isTTY)||"dumb"===process.env.TERM)&&"none"!==(0,B.PT)()&&(0,G.E)(process.env)&&(0,X.terminalSupportsPromptBarHalfPadding)();'
ARROW_DIM_OLD='color:fo||bo.active?"magenta":W?"yellow":"foreground",dimColor:!fo&&!bo.active&&!W&&0===e.length'
ARROW_DIM_NEW='color:fo||bo.active?"magenta":W?"yellow":"white"/*43pr-white-text*/,dimColor:!1/*43pr-no-empty-dim*/'
PLACEHOLDER_DIM_OLD='ht=n?c.Ay.dim(n):void 0'
PLACEHOLDER_DIM_NEW='ht=n?c.Ay.white(n)/*43pr-white-placeholder*/:void 0'
PLACEHOLDER_SLICE_OLD='ht=n.length>0?t(n[0])+c.Ay.dim(n.slice(1)):t(" ")'
PLACEHOLDER_SLICE_NEW='ht=n.length>0?t(n[0])+c.Ay.white(n.slice(1)):t(" ")'

collect_js() {
  local root="$1" f
  for f in \
    "$root/1931.index.js" \
    "$root/1218.index.js" \
    "$root/dist-package/1931.index.js" \
    "$root/dist-package/1218.index.js" \
    "$root"/*.index.js \
    "$root/dist-package"/*.index.js
  do
    [[ -f "$f" ]] || continue
    printf '%s\n' "$f"
  done
}

is_prompt_bar_js() {
  local js="$1"
  grep -qF 'AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR' "$js" 2>/dev/null \
    || grep -qF "$FILL_OLD" "$js" 2>/dev/null \
    || grep -qF '43pr-transparent-prompt' "$js" 2>/dev/null
}

is_user_message_js() {
  local js="$1"
  grep -qF 'user-message-ui.tsx' "$js" 2>/dev/null \
    || grep -qF "$USER_MSG_FILL_OLD" "$js" 2>/dev/null \
    || grep -qF '43pr-transparent-user-msg' "$js" 2>/dev/null
}

is_text_input_js() {
  local js="$1"
  grep -qF 'rightPlaceholder:e,ghostText:r' "$js" 2>/dev/null \
    || grep -qF "$PLACEHOLDER_DIM_OLD" "$js" 2>/dev/null \
    || grep -qF '43pr-white-placeholder' "$js" 2>/dev/null
}

roots=()
add_root() {
  local d="$1"
  [[ -d "$d" ]] || return 0
  roots+=("$d")
}

if command -v cursor-agent >/dev/null 2>&1; then
  add_root "$(dirname "$(readlink -f "$(command -v cursor-agent)")")"
fi
if command -v agent >/dev/null 2>&1; then
  add_root "$(dirname "$(readlink -f "$(command -v agent)")")"
fi
for d in "$HOME/.local/share/cursor-agent/versions"/*; do
  add_root "$d"
done
for d in "$HOME/.local/share/mise/installs/cursor-agent"/*/bin "$HOME/.local/share/mise/installs/cursor-agent/latest/bin"; do
  add_root "$d"
done
# mise http-tarball unpacks sometimes used at runtime
for d in "$HOME/.local/share/mise/http-tarballs"/*/dist-package; do
  add_root "$(dirname "$d")"
  add_root "$d"
done

mapfile -t roots < <(printf '%s\n' "${roots[@]}" | awk 'NF && !seen[$0]++')

if [[ ${#roots[@]} -eq 0 ]]; then
  log "no cursor-agent install found — skip"
  exit 0
fi

patched=0
seen_js=()
for root in "${roots[@]}"; do
  while IFS= read -r js; do
    [[ -f "$js" ]] || continue
    for s in "${seen_js[@]+"${seen_js[@]}"}"; do
      [[ "$s" == "$js" ]] && continue 2
    done
    seen_js+=("$js")

    if ! is_prompt_bar_js "$js" && ! is_text_input_js "$js" && ! is_user_message_js "$js"; then
      continue
    fi

    need=0
    if is_prompt_bar_js "$js"; then
      grep -qF "$FILL_OLD" "$js" 2>/dev/null && need=1
      grep -qF "$HALF_OLD" "$js" 2>/dev/null && need=1
      grep -qF "$ARROW_DIM_OLD" "$js" 2>/dev/null && need=1
      if grep -qF '43pr-transparent-prompt' "$js" 2>/dev/null \
        && ! grep -qF '43pr-white-text' "$js" 2>/dev/null; then
        need=1
      fi
      if grep -qF '43pr-transparent-prompt' "$js" 2>/dev/null \
        && ! grep -qF '43pr-no-empty-dim' "$js" 2>/dev/null; then
        need=1
      fi
      if grep -qF 'dimColor:!0' "$js" 2>/dev/null; then
        need=1
      fi
      if grep -qF 'color:"foreground"' "$js" 2>/dev/null; then
        need=1
      fi
    fi
    if is_user_message_js "$js"; then
      grep -qF "$USER_MSG_FILL_OLD" "$js" 2>/dev/null && need=1
    fi
    if is_text_input_js "$js"; then
      grep -qF "$PLACEHOLDER_DIM_OLD" "$js" 2>/dev/null && need=1
      grep -qF "$PLACEHOLDER_SLICE_OLD" "$js" 2>/dev/null && need=1
      if grep -qF 'dimColor:!0,children:r' "$js" 2>/dev/null \
        || grep -qF 'dimColor:!0,children:e' "$js" 2>/dev/null; then
        need=1
      fi
      if ! grep -qF '43pr-white-placeholder' "$js" 2>/dev/null; then
        # Unpatched or partial text-input still needs a pass when markers missing
        # but only if the component is present.
        if grep -qF 'rightPlaceholder:e,ghostText:r' "$js" 2>/dev/null; then
          need=1
        fi
      fi
    fi

    if [[ "$need" -eq 0 ]]; then
      log "already patched: $js"
      patched=1
      continue
    fi

    cp -a "$js" "$js.43pr-bak"
    python3 - "$js" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(errors="ignore")
changed = False

subs = [
    (
        "backgroundColor:e,paddingLeft:1,paddingY:s?0:1",
        "/*43pr-transparent-prompt*/paddingLeft:1,paddingY:s?0:1",
    ),
    # user-message-ui.tsx: opaque blended fill behind user prompts
    (
        "backgroundColor:v,paddingLeft:1,paddingRight:5,paddingY:1,marginX:1,width:h.width-2",
        "/*43pr-transparent-user-msg*/paddingLeft:1,paddingRight:5,paddingY:1,marginX:1,width:h.width-2",
    ),
    (
        'const s=!(0,W.t)(process.env.AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR)&&!(!(null===(i=process.stdout)||void 0===i?void 0:i.isTTY)||"dumb"===process.env.TERM)&&"none"!==(0,B.PT)()&&(0,G.E)(process.env)&&(0,X.terminalSupportsPromptBarHalfPadding)();',
        "const s=!1;/*43pr-no-halfblock*/",
    ),
    (
        'color:fo||bo.active?"magenta":W?"yellow":"foreground",dimColor:!fo&&!bo.active&&!W&&0===e.length',
        'color:fo||bo.active?"magenta":W?"yellow":"white"/*43pr-white-text*/,dimColor:!1/*43pr-no-empty-dim*/',
    ),
    # text-input.tsx: placeholder is chalk.dim → near-invisible on Foot blur
    (
        "ht=n?c.Ay.dim(n):void 0",
        "ht=n?c.Ay.white(n)/*43pr-white-placeholder*/:void 0",
    ),
    (
        'ht=n.length>0?t(n[0])+c.Ay.dim(n.slice(1)):t(" ")',
        'ht=n.length>0?t(n[0])+c.Ay.white(n.slice(1)):t(" ")',
    ),
    (
        "(0,o.jsx)(s.EY,{dimColor:!0,children:r})",
        '(0,o.jsx)(s.EY,{color:"white",children:r})',
    ),
    (
        "(0,o.jsx)(s.EY,{dimColor:!0,children:e})",
        '(0,o.jsx)(s.EY,{color:"white",children:e})',
    ),
]
for old, new in subs:
    if old in text:
        text = text.replace(old, new, 1)
        changed = True

# Broader chrome whitening on the prompt-bar chunk only (color tokens, not
# execution:"foreground" job mode strings).
if "AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR" in text or "43pr-transparent-prompt" in text:
    color_subs = [
        ('color:"foreground"', 'color:"white"/*43pr-white-text*/'),
        ('color:n?"foreground"', 'color:n?"white"'),
        ('color:g||"foreground"', 'color:g||"white"'),
        ('a?e:"foreground"', 'a?e:"white"'),
        ('default:return"foreground"', 'default:return"white"'),
        ('highlightColor:null!=wr?wr:"foreground"', 'highlightColor:null!=wr?wr:"white"'),
    ]
    for old, new in color_subs:
        if old in text:
            text = text.replace(old, new)
            changed = True
    if "dimColor:!0" in text:
        text = text.replace("dimColor:!0", 'color:"white"')
        changed = True

if changed:
    path.write_text(text)
PY
    log "patched: $js"
    patched=1
  done < <(collect_js "$root")
done

# Belt-and-suspenders env (harmless once half-blocks are forced off in JS).
ENV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
mkdir -p "$ENV_DIR"
cat > "$ENV_DIR/43pr-cursor-agent.conf" <<'EOF'
AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR=true
EOF

SNIPPET="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/43pr-cursor-agent-env.sh"
cat > "$SNIPPET" <<'EOF'
export AGENT_CLI_DISABLE_HALF_BLOCK_PROMPT_BAR=true
EOF

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [[ -f "$rc" ]] || continue
  if ! grep -qF '43pr-cursor-agent-env.sh' "$rc" 2>/dev/null; then
    printf '\n# 43PR Cursor Agent transparent prompt\n[[ -f %s ]] && source %s\n' "$SNIPPET" "$SNIPPET" >> "$rc"
  fi
done

if [[ "$patched" -eq 0 ]]; then
  log "no matching prompt-bar / text-input bundle found (CLI layout may have changed)"
  exit 0
fi

log "done — quit agent and relaunch in a new Foot window"
