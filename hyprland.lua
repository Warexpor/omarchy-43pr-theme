-- Optional when copying this theme by hand. `omarchy theme install` regenerates
-- hyprland.lua from colors.toml (borders only). Put rounding in looknfeel.lua —
-- git-installed themes cannot ship Lua.
local active_border_color = { colors = { "rgba(aaaaaaee)", "rgba(d0d0d0cc)" }, angle = 45 }
local inactive_border_color = "rgba(59595966)"

hl.config({
  general = {
    border_size = 2,
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
    rounding = 12,
    rounding_power = 2,
  },
})
