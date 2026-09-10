-- 43PR blur + frosted popups for ~/.config/hypr/looknfeel.lua
-- Merge into your existing decoration block (or paste as additional hl.config).
--
-- NOT applied by `omarchy theme install` — git themes cannot ship *.lua.

hl.config({
  decoration = {
    rounding = 12,
    rounding_power = 2,
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      -- Clock/calendar and other xdg-popups (off by default in Hyprland).
      popups = true,
      popups_ignorealpha = 0.60,
    },
  },
})

-- Bar calendar etc. are xdg-popups of the omarchy-bar layer-shell surface.
hl.layer_rule({
  match = { namespace = "omarchy-bar" },
  blur_popups = true,
  ignore_alpha = 0.50,
})

-- Menus / notifications / OSD are their own layers (not xdg-popups).
hl.layer_rule({
  match = { namespace = "^(omarchy-menu|omarchy-notifications|omarchy-osd)$" },
  blur = true,
  ignore_alpha = 0.50,
})
