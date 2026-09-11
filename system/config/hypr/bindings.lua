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
-- PRINT: HDR-safe screenshot (dip sdrbrightness to 1.0 for grim, then restore).
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot (HDR-safe)", "{{HOME}}/.local/bin/omarchy-screenshot-hdr-safe")

o.bind(
  "SUPER + ALT + W",
  "Wallpaper Engine Manager",
  { launch = "{{HOME}}/.local/bin/wpe-manager-omarchy" }
)
o.bind("SUPER + ALT + SHIFT + W", "Wallpaper Engine off", "{{HOME}}/.local/bin/we-wallpaper off")

o.bind("KP_Divide", "Discord mute", "{{HOME}}/.local/bin/discord-voice mute")
o.bind("KP_Multiply", "Discord deafen", "{{HOME}}/.local/bin/discord-voice deafen")
o.bind("KP_Subtract", "Discord camera", "{{HOME}}/.local/bin/discord-voice video")
