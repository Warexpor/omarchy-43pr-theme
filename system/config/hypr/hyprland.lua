-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Translucent windows so the blur shows through (1.0 = solid).
o.window({ tag = "default-opacity" }, { opacity = "0.9 0.9" })

-- Under monitor HDR: never let apps flip into Auto-HDR on their own.
o.window(".*", { no_auto_hdr = true })

-- WORKING Chromium/Electron look (HDR monitor, bearable dim + blur):
--   opacity 0.9, -default-opacity (Hyprland multiplies opacities — don't stack),
--   launch flags (force compositor SDR path):
--     --force-color-profile=srgb
--     --disable-features=WaylandWpColorManagerV1
--   maintained by ~/.local/bin/chromium-sdr-sync (post-update hook) into
--   ~/.config/*-flags.conf, plus wrappers for bundled Electron apps
--   (Cursor /usr/bin/cursor desktop, Grok Bot, Claude Desktop, Discord).
--   Do NOT "fix dim" by raising sdrbrightness — that washes the whole desktop.
--   Foot TUIs: alpha=0.8 blur=yes under [colors-dark]/[colors-light] in foot.ini.
--
-- Class list is the Hyprland side; flags sync covers new browser/Electron
-- packages that read *-flags.conf. Bundled apps still need wrappers (see sync).
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

-- TUIs/terminals: window stays opaque; foot owns alpha + native blur.
o.window({ tag = "terminal" }, { tag = "-default-opacity", opacity = "1.0 1.0" })

-- Screensaver: stock uses exclusive fullscreen, which does not composite
-- wallpaper behind the surface — Foot's ext-background-effect blur stays black.
-- Maximize + float keeps the live adaptive wallpaper frosting behind ttfx.
o.window("org.omarchy.screensaver", { fullscreen = false })
o.window("org.omarchy.screensaver", { float = true })
o.window("org.omarchy.screensaver", { maximize = true })
o.window("org.omarchy.screensaver", { border_size = 0 })
o.window("org.omarchy.screensaver", { rounding = 0 })

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Smaller cursor (Omarchy default is 24).
hl.env("XCURSOR_SIZE", "21")
hl.env("HYPRCURSOR_SIZE", "21")

-- NOTE: the ~/.config/omarchy/bin override is applied session-wide via
-- ~/.config/uwsm/env.d/20-omarchy-bin-override, which Hyprland inherits.
-- Don't prepend PATH here too, or the entry stacks up on every layer.
