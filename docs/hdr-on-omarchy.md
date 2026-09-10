# How to set up HDR on Omarchy (battle-tested)

Practical guide from getting HDR working on Omarchy (Hyprland) without
Chromium/Electron apps looking broken — dim, washed, or mismatched.

Hardware context for this writeup: DEXP DQ27N1, `2560x1440@99.97`, HDMI,
10-bit HDR10. Values will differ on your panel; the **architecture** is what
matters.

---

## Mental model (read this first)

On Omarchy with `cm = hdr`, there are **two different ways** an app’s pixels
reach the panel:

| Path | Who maps brightness | Typical apps | Looks like |
|------|---------------------|--------------|------------|
| **Compositor SDR** | Hyprland (`sdrbrightness`, etc.) | Native GTK/Qt, apps with color management disabled | Tracks desktop; tunable |
| **Client color-managed** | The app itself via Wayland CM | Chrome / Electron with native CM enabled | Often **dim** vs the rest of the desktop; **ignores** `sdrbrightness` |

Most “Chromium is dim on HDR” pain is path 2. Raising `sdrbrightness` only
fixes path 1, and if you push it hard everything looks **washed**.

**Working strategy on this machine:**

1. Keep the monitor in real HDR (`cm = hdr`, 10-bit).
2. Force Chromium/Electron onto the **compositor SDR** path (launch flags).
3. Use Hyprland **opacity ~0.9** for a slight dim + blur look (not for HDR fix).
4. Leave `sdrbrightness` alone once the desktop feels right (~`1.3` here).

---

## 1. Enable HDR on the monitor

Edit `~/.config/hypr/monitors.lua` (Omarchy Lua config).

```lua
-- Example — replace output/mode/scale with your panel
hl.monitor({
  output = "HDMI-A-1",
  mode = "2560x1440@99.97",
  position = "auto",
  scale = 1.33333,
  bitdepth = 10,
  cm = "hdr",
  sdrbrightness = 1.3,
  sdrsaturation = 1.0,
  sdr_max_luminance = 300,
})
```

Verify:

```bash
hyprctl reload
hyprctl monitors -j | jq '.[0] | {currentFormat, colorManagementPreset, sdrBrightness, sdrMaxLuminance}'
```

Expect something like:

- `currentFormat`: `XBGR2101010` (10-bit)
- `colorManagementPreset`: `hdr`
- `sdrBrightness`: your value (e.g. `1.3`)

List modes / outputs: `hyprctl monitors all`.

### Don’t do this when Chromium looks dim

Do **not** keep cranking `sdrbrightness` / `sdrsaturation` to “fix Chrome”.
In practice:

- `1.3` → baseline that felt fine for the desktop  
- `1.5`–`1.6` → briefly “brighter” then **washed / gray**  
- Revert and fix Chromium with **flags**, not monitor SDR boosts  

---

## 2. Blur + translucent windows (look)

Omarchy defaults often ship blur **off**. User look lives in
`~/.config/hypr/looknfeel.lua`:

```lua
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
    },
  },
})
```

Window opacity (Hyprland) is separate from terminal background alpha.
Important Hyprland quirk:

> **Opacity rules multiply.**  
> If a window has `default-opacity` at `0.9` **and** another rule at `0.96`,
> you get `≈0.86`, which looks suddenly dim again.

Pattern that works:

```lua
-- Everyone slightly translucent
o.window({ tag = "default-opacity" }, { opacity = "0.9 0.9" })

-- Stop Auto-HDR surprises under cm=hdr
o.window(".*", { no_auto_hdr = true })

-- Chromium/Electron: strip default-opacity, set exact opacity once
o.window("(chromium|google-chrome|chrome|cursor|discord|electron|brave|…)", {
  tag = "-default-opacity",
  opacity = "0.9 0.9",
  no_auto_hdr = true,
})

-- Also override Omarchy browser tags (they set their own opacity)
o.window({ tag = "chromium-based-browser" }, {
  tag = "-default-opacity",
  opacity = "0.9 0.9",
  no_auto_hdr = true,
})

-- Terminals: keep window opaque; let the terminal own alpha+blur
o.window({ tag = "terminal" }, { tag = "-default-opacity", opacity = "1.0 1.0" })
```

Known-good Chromium opacity here: **`0.9`** (blur still visible, not eye-searing).

Optional exact override syntax if stacking fights you:

```lua
opacity = "0.9 override 0.9 override"
```

---

## 3. Force Chromium/Electron onto compositor SDR

### The two flags

```text
--force-color-profile=srgb
--disable-features=WaylandWpColorManagerV1
```

That disables the client CM path that ignores `sdrbrightness` and makes UI
look dim next to the rest of the desktop.

### Apps that read `*-flags.conf`

Arch/Omarchy wrappers often load:

| File | Used by |
|------|---------|
| `~/.config/chrome-flags.conf` | Google Chrome |
| `~/.config/chromium-flags.conf` | Chromium |
| `~/.config/brave-flags.conf` (etc.) | Brave / Edge / … |
| `~/.config/electron-flags.conf` | `/usr/bin/electron*` fallback |
| `~/.config/electron42-flags.conf` / `electron43-…` | Versioned electron |
| `~/.config/spotify-flags.conf` | Spotify |
| `~/.config/cursor-flags.conf` | Only if launched via `/usr/bin/cursor` |
| `~/.config/obsidian/user-flags.conf` | Obsidian |

On this machine those files are kept in sync by:

```bash
~/.local/bin/chromium-sdr-sync
```

…also installed as an Omarchy **post-update** hook so package updates don’t
quietly drop the flags:

```bash
omarchy hook install post-update ~/.local/bin/chromium-sdr-sync
```

### Bundled Electron apps need wrappers

Self-contained apps **do not** read `electron-flags.conf`. They must get flags
on the command line.

| App | WM class | What worked |
|-----|----------|-------------|
| Cursor | `cursor` | `.desktop` must run **`/usr/bin/cursor`** (reads `cursor-flags.conf`), **not** `/usr/share/cursor/cursor` |
| Discord | `discord` | Custom launcher passes `--force-color-profile=srgb` (Discord already disables Wayland CM) |
| Grok Bot | `grok-bot` | `~/.local/bin/grok-bot` wrapper + `.desktop` **absolute** `Exec=` + `/usr/local/bin/grok-bot` symlink (PATH: `/usr/bin` beats `~/.local/bin`) |
| Claude Desktop | `com.anthropic.Claude` | `~/.local/bin/claude-desktop` wrapper + local `.desktop` with absolute `Exec=` |

Example wrapper:

```sh
#!/bin/sh
exec "/opt/Grok Bot/grok-bot" \
  --force-color-profile=srgb \
  --disable-features=WaylandWpColorManagerV1 \
  "$@"
```

### Prove flags actually applied

```bash
# Main process only (no --type=)
pgrep -af '/opt/Grok Bot/grok-bot' | head -1
# Expect: --force-color-profile=srgb and WaylandWpColorManagerV1
```

If the main process **lacks** those flags, the app is still on the dim CM path
no matter what Hyprland opacity says.

---

## 4. Desktop file landmines (this burned hours)

### CRLF kills user `.desktop` files

If `~/.local/share/applications/foo.desktop` has Windows `CRLF` endings:

```text
desktop-file-validate: … carriage return …
```

XDG **ignores** it and falls back to `/usr/share/applications/…`, which often
runs `/usr/bin/app` with **no SDR flags**.

Always:

```bash
file ~/.local/share/applications/*.desktop   # must NOT say "CRLF"
sed -i 's/\r$//' ~/.local/share/applications/problematic.desktop
update-desktop-database ~/.local/share/applications
```

### PATH order

Typical Omarchy PATH has `/usr/bin` **before** `~/.local/bin`. So:

- `Exec=grok-bot` → `/usr/bin/grok-bot` (stock, no flags)  
- Fix: `Exec=/home/YOU/.local/bin/grok-bot` **or** symlink into `/usr/local/bin`
  (which sorts before `/usr/bin`)

### Cursor-specific trap

Proxy-customized `.desktop` that launches `/usr/share/cursor/cursor` **bypasses**
`cursor-flags.conf`. Use `/usr/bin/cursor` and keep proxy args.

---

## 5. Terminal / TUI blur (Foot)

Hyprland window opacity on terminals fades **text** too. Better: keep the
window opaque and use Foot’s own alpha + compositor blur protocol.

Foot **1.28+**: there is **no** `[colors]` section. Use:

```ini
[colors-dark]
alpha=0.8
blur=yes

[colors-light]
alpha=0.8
blur=yes
```

Notes:

- `blur=yes` needs Hyprland’s `ext-background-effect-v1` (Omarchy/Hyprland 0.56+ has it).
- A comment containing the literal text `[colors]` can be parsed as a section
  and error: `invalid section name: colors`. Don’t put that string in comments.
- After changing alpha/blur, open a **new** terminal; old windows may not update.
- Hyprland: leave `terminal` tagged windows at opacity `1.0`.

(Values here drifted over time; use whatever alpha you like — the structure is
what matters.)

---

## 6. Diagnosing “still dim” vs “too bright”

### A/B: is it opacity or color management?

```bash
# Temporarily force one app fully solid
hyprctl eval 'o.window("cursor", { opacity = "1.0 override 1.0 override" })'
```

- **Blur gone, still dim** → CM / HDR path (flags / launch wrapper).  
- **Brightens when solid** → opacity / blur wash (nudge `0.9` ↔ `0.96`).  

### Discord bright, Cursor dim (classic)

Almost always: **Discord already on compositor SDR**, **Cursor still on native CM**
because the desktop bypassed the flags wrapper. Fix launch path; don’t raise
global SDR brightness.

### Opacity changes “do nothing” to dimness

Then you’re not fighting Hyprland opacity — you’re fighting client CM. Check
process argv for the two flags.

### Washed gray desktop after “fixing”

You probably raised `sdrbrightness` / `sdrsaturation`. Put them back
(`1.3` / `1.0` here) and fix apps instead.

---

## 7. Checklist (new Omarchy HDR box)

1. [ ] Monitor: `bitdepth = 10`, `cm = "hdr"`, sane `sdrbrightness` (~1.2–1.4).  
2. [ ] `hyprctl monitors` shows 10-bit + `hdr`.  
3. [ ] Blur on in `looknfeel.lua` if you want glass.  
4. [ ] `no_auto_hdr` on windows; Chromium opacity `0.9` without stacking.  
5. [ ] Run `chromium-sdr-sync` (or equivalent) for `*-flags.conf`.  
6. [ ] Wrappers + **LF-only** user `.desktop` files for Cursor / Claude / Grok / Discord.  
7. [ ] Confirm running processes actually have the SDR flags.  
8. [ ] Foot: `[colors-dark]` / `[colors-light]` alpha + `blur=yes`.  
9. [ ] Post-update hook so package updates don’t strip flags.  
10. [ ] Never use `sdrbrightness` as the Chromium dim hammer.  

---

## 8. File map (this machine)

```text
~/.config/hypr/monitors.lua          # HDR monitor
~/.config/hypr/looknfeel.lua         # blur / rounding
~/.config/hypr/hyprland.lua          # opacity + no_auto_hdr + class list

~/.config/chrome-flags.conf          # Chrome SDR flags (+ Omarchy extras)
~/.config/cursor-flags.conf
~/.config/electron-flags.conf
~/.config/spotify-flags.conf
~/.config/obsidian/user-flags.conf

~/.local/bin/chromium-sdr-sync       # maintain flags confs
~/.local/bin/grok-bot                # wrapper
~/.local/bin/claude-desktop          # wrapper
~/.local/bin/discord-no-nvenc-golive # Discord launcher (+ SDR flag)
/usr/local/bin/grok-bot              # symlink → wrapper (PATH win)

~/.local/share/applications/cursor.desktop
~/.local/share/applications/grok-bot.desktop
~/.local/share/applications/com.anthropic.Claude.desktop

~/.config/omarchy/hooks/post-update.d/chromium-sdr-sync

~/.config/foot/foot.ini              # colors-dark/light alpha + blur
```

---

## 9. References / upstream context

- Hyprland issue: Chromium/Electron look dim under HDR when native Wayland CM
  is on — they bypass compositor `sdrbrightness`.  
- Hyprland: opacity rules **multiply** unless you use `override`.  
- Foot 1.28+: `colors-dark` / `colors-light` only; `ext-background-effect-v1` for blur.  
- Omarchy: user Hyprland Lua under `~/.config/hypr/`; never edit `/usr/share/omarchy/` for this.

---

## 10. Adding a new Electron app later

1. Find `StartupWMClass` / `hyprctl clients` class.  
2. Add it to the Chromium/Electron regex in `hyprland.lua`.  
3. If it uses Arch `electron*`: `chromium-sdr-sync` is enough.  
4. If it’s a bundled binary under `/opt/...`: write a wrapper + user `.desktop`
   with **absolute** `Exec=` and **Unix LF** endings.  
5. Fully quit/relaunch; verify argv has the two SDR flags.  
6. Match opacity to `0.9` (or your preferred value).  

That’s the whole loop — HDR on the panel, SDR forced for Chromium-family apps,
opacity only for aesthetics, never “fix dim” with monitor wash.
