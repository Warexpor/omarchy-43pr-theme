-- 43PR Plume: blur, glass rim and frosted panels for ~/.config/hypr/looknfeel.lua
-- Merge into your existing config (or paste as additional hl.config calls).
--
-- NOT applied by `omarchy theme install` — git themes cannot ship *.lua.
--
-- Clock/calendar is KeyboardPanel → layer-shell namespace `omarchy-keyboard-panel`
-- (NOT an xdg-popup of omarchy-bar). Blur it with a layer rule, not blur_popups.
-- Clipboard / emojis / image picker are also their own namespaces.
--
-- ignore_alpha / popups_ignorealpha: Hyprland skips blur on pixels with alpha
-- <= the threshold. Keep this BELOW shell.toml glass fills (0.10) and at/above
-- its scrims (0.07) so cards frost while the dimmed backdrop stays sharp.

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 14,
    border_size = 1,
  },
})

hl.config({
  decoration = {
    -- 15, not 14: at scale 4/3, 14*4/3=18.67 px so frost and the QML rim disagree.
    rounding = 15,
    rounding_power = 2,
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      -- Slightly dimmed, colourless blur so glass reads clear, not milky.
      brightness = 0.90,
      vibrancy = 0.0,
      noise = 0.0,
      popups = true,
      popups_ignorealpha = 0.08,
    },
  },
})

hl.layer_rule({
  match = { namespace = "omarchy-bar" },
  blur_popups = true,
  ignore_alpha = 0.08,
})

hl.layer_rule({
  match = {
    namespace = "^(omarchy-keyboard-panel|omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-clipboard|omarchy-emojis|omarchy-image-selector)$",
  },
  blur = true,
  ignore_alpha = 0.08,
})
