-- Keep only your personal keybinding overrides here.

-- Switch US/RU with Alt+Shift in either press order.
o.bind("ALT + Shift_L", "Switch keyboard layout", "hyprctl switchxkblayout all next")
o.bind("SHIFT + Alt_L", "Switch keyboard layout", "hyprctl switchxkblayout all next")

-- Select text (e.g. Ctrl+A), then flip EN↔RU by key position.
-- code:53 = physical X (works on RU layout too).
-- Fire on press; patched retypexd waits for Ctrl/Shift up before wtype.
-- Logged wrapper: ~/.local/state/retypex/cli.log (+ daemon.log).
o.bind(
  "CTRL + SHIFT + code:53",
  "Flip EN/RU selection",
  "{{HOME}}/.local/bin/retypex-logged sel"
)
-- PRINT: HDR-aware screenshot (SDR swap when toggle ON; stock when OFF).
-- Toggle: SUPER + SHIFT + PRINT -> ~/.local/bin/omarchy-toggle-hdr-safe-screenshot
-- Was: omarchy-capture-screenshot
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot (HDR-aware)", "{{HOME}}/.local/bin/omarchy-screenshot-hdr-safe")
o.bind(
  "SUPER + SHIFT + PRINT",
  "Toggle HDR-safe screenshot",
  "{{HOME}}/.local/bin/omarchy-toggle-hdr-safe-screenshot"
)

-- ALT+PRINT: stock Omarchy screenrecord via PATH shim (desktop stays HDR;
-- GSR -k auto; file may look washed — grade in editor). See docs/hdr-on-omarchy.md.
hl.unbind("ALT + PRINT")
o.bind(
  "ALT + PRINT",
  "Screenrecording (HDR)",
  "{{HOME}}/.config/omarchy/bin/omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord"
)

o.bind("KP_Divide", "Discord mute", "{{HOME}}/.local/bin/discord-voice mute")
o.bind("KP_Multiply", "Discord deafen", "{{HOME}}/.local/bin/discord-voice deafen")
o.bind("KP_Subtract", "Discord camera", "{{HOME}}/.local/bin/discord-voice video")

-- Electron/Cursor ignore compositor middle_click_paste; clear primary so MMB
-- has nothing to paste. non_consuming keeps real middle-click (e.g. Krita pan).
o.bind("mouse:274", "Clear primary selection", "wl-copy -pc", { non_consuming = true })
