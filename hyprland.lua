-- Optional when copying this theme by hand. `omarchy theme install` regenerates
-- hyprland.lua from colors.toml (borders only). Put rounding in looknfeel.lua —
-- git-installed themes cannot ship Lua.
local active_border_color = { colors = { "rgba(ffffff99)", "rgba(ffffff26)" }, angle = 45 }
local inactive_border_color = "rgba(ffffff1f)"

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
    rounding = 14,
    rounding_power = 2,
  },
})
