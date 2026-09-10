-- 43PR HDR / blur window rules for ~/.config/hypr/hyprland.lua
-- Paste below your require("hypr.*") / omarchy defaults block.
--
-- NOT applied by `omarchy theme install` — git themes cannot ship *.lua.
-- See extras/README.md and docs/hdr-on-omarchy.md.

-- Translucent windows so blur shows through (1.0 = solid).
o.window({ tag = "default-opacity" }, { opacity = "0.9 0.9" })

-- Under monitor HDR: never let apps flip into Auto-HDR on their own.
o.window(".*", { no_auto_hdr = true })

-- Chromium/Electron: strip default-opacity, set opacity once (rules multiply).
local chromium_electron_class =
  "(chromium|google-chrome|chrome|cursor|discord|electron|brave|grok-bot"
  .. "|com\\.anthropic\\.Claude|Spotify|spotify|obsidian|1Password"
  .. "|signal|slack|vesktop|webcord|Code|code-oss|opencode|marktext)"

o.window(chromium_electron_class, {
  tag = "-default-opacity",
  opacity = "0.9 0.9",
  no_auto_hdr = true,
})
o.window({ tag = "chromium-based-browser" }, {
  tag = "-default-opacity",
  opacity = "0.9 0.9",
  no_auto_hdr = true,
})
o.window({ tag = "firefox-based-browser" }, {
  tag = "-default-opacity",
  opacity = "0.9 0.9",
  no_auto_hdr = true,
})

-- TUIs/terminals: window stays opaque; Foot owns alpha + native blur.
o.window({ tag = "terminal" }, { tag = "-default-opacity", opacity = "1.0 1.0" })
