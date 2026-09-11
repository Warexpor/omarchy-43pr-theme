-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
  },
})

-- Capture path only: keep HDR/10-bit on the monitor, force 8-bit frames into
-- PipeWire/Discord (Hyprland default is already true; set explicitly).
hl.config({
  misc = {
    screencopy_force_8b = true,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
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
      -- Real xdg-popups only. Clock/calendar is KeyboardPanel layer-shell.
      popups = true,
      -- ignore_alpha: skip blur on pixels with alpha <= this. Keep below
      -- popups.background-alpha (0.72) so the frosted fill still blurs.
      popups_ignorealpha = 0.50,
    },
  },
})

-- Legacy: any remaining xdg-popups parented to the bar surface.
hl.layer_rule({
  match = { namespace = "omarchy-bar" },
  blur_popups = true,
  ignore_alpha = 0.50,
})

-- Clock/calendar + other bar panels use KeyboardPanel
-- (layer-shell `omarchy-keyboard-panel`), not xdg-popups of the bar.
-- ignore_alpha 0.50: transparent overlay stays clear; card fill (0.72) frosts.
hl.layer_rule({
  match = { namespace = "^(omarchy-keyboard-panel|omarchy-menu|omarchy-notifications|omarchy-osd)$" },
  blur = true,
  ignore_alpha = 0.50,
})
