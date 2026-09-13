-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.33333

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Example HDR10 panel (edit connector / mode for your display).
-- Prefer a high refresh mode when available — 60Hz preferred often feels sluggish.
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@99.97", position = "auto", scale = omarchy_monitor_scale, bitdepth = 10, cm = "hdr", sdrbrightness = 1.3, sdrsaturation = 1.0, sdr_max_luminance = 300 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
