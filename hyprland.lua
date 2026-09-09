-- Optional when copying this theme by hand. `omarchy theme install` regenerates
-- hyprland.lua from colors.toml, so git installs rely on hyprland_* keys there.
local active_border_color = { colors = { "rgba(ffffffff)", "rgba(e5e5e5ee)" }, angle = 45 }
local inactive_border_color = "rgba(0d0d0daa)"

hl.config({
  general = {
    border_size = 1,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    rounding = 8,
    rounding_power = 2,
  },
})
