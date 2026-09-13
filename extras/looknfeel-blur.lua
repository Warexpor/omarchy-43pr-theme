-- 43PR blur + frosted panels for ~/.config/hypr/looknfeel.lua
-- Merge into your existing decoration block (or paste as additional hl.config).
--
-- NOT applied by `omarchy theme install` — git themes cannot ship *.lua.
--
-- Clock/calendar is KeyboardPanel → layer-shell namespace `omarchy-keyboard-panel`
-- (NOT an xdg-popup of omarchy-bar). Blur it with a layer rule, not blur_popups.
--
-- ignore_alpha / popups_ignorealpha: Hyprland skips blur on pixels with alpha
-- <= the threshold. Keep this BELOW shell.toml popups.background-alpha (0.72)
-- so the frosted fill blurs, while the full-screen transparent overlay does not.

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
      popups = true,
      popups_ignorealpha = 0.50,
    },
  },
})

hl.layer_rule({
  match = { namespace = "omarchy-bar" },
  blur_popups = true,
  ignore_alpha = 0.50,
})

hl.layer_rule({
  match = { namespace = "^(omarchy-keyboard-panel|omarchy-menu|omarchy-notifications|omarchy-osd)$" },
  blur = true,
  ignore_alpha = 0.50,
})
