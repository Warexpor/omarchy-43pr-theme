# Cursor Agent CLI — transparency

Upstream paints opaque Ink `backgroundColor` fills on the prompt bar and
user-message bubbles (blended from OSC 11 / theme constants). There is still
no `cli-config.json` field for transparent surfaces.

## What 43PR does

`extras/tui-agents/bin/patch-cursor-agent-prompt.sh` (via `install-tui-agents.sh`):

1. Sets `display.mode = "zen"`
2. Removes the prompt bar's opaque `backgroundColor` fill
3. Forces half-block ▄/▀ padding rows off (those were the thick black lines)
4. Removes the user-message bubble's opaque `backgroundColor` fill

Backup: `1931.index.js.43pr-bak`. Re-run after `agent update`.

## Manual

```bash
~/.local/share/43pr-tui-agents/bin/patch-cursor-agent-prompt.sh
# or
./extras/install-tui-agents.sh
```

Then open a **new** Foot window and launch `agent`.
