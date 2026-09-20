# How to set up HDR on Omarchy (battle-tested)

Practical guide from getting HDR working on Omarchy (Hyprland) without
Chromium/Electron apps looking broken — dim, washed, or mismatched.

Written against a 27" 1440p HDMI HDR10 panel. Exact mode / SDR map values
will differ on your display; the **architecture** is what matters.

Updated 2026-09-20: the real Chromium-dim fix is compositor
`reference_luminance` (local Hyprland package), not SDR launch-flag crutches.

---

## Mental model (read this first)

On Omarchy with `cm = hdr`, there are **two different ways** an app’s pixels
reach the panel:

| Path | Who maps brightness | Typical apps | Looks like |
|------|---------------------|--------------|------------|
| **Compositor SDR** | Hyprland (`sdrbrightness`, `sdr_max_luminance`) | Native GTK/Qt, apps with CM disabled | Tracks desktop; tunable |
| **Client color-managed** | The app via Wayland `wp_color_management_v1` | Chrome / Electron with native CM **enabled** | Anchored to compositor **reference white** |

Stock Hyprland hardcodes that reference at **203 nits** (BT.2408). Raising
`sdrbrightness` only brightens path 1, so CM clients look **dim** next to the
desktop. That is not an NVIDIA driver dead-end.

**Working strategy on this machine (verified):**

1. Keep the monitor in real HDR (`cm = hdr`, 10-bit).
2. Run a Hyprland build with per-monitor **`reference_luminance`**
   (local package `0.56.2-3.1` from sibling repo
   [`hyprland-hdr-fix`](../../hyprland-hdr-fix/) — patch from closed
   [Hyprland PR #16247](https://github.com/hyprwm/Hyprland/pull/16247)).
3. Set `reference_luminance ≈ sdr_max_luminance × sdrbrightness`
   (here: `300 × 1.3 = 390`) so CM clients match compositor-SDR white.
4. Leave Chromium/Electron on **native CM** (no
   `WaylandWpColorManagerV1` kill-switch) so in-browser HDR video still works.
5. Use Hyprland **opacity ~0.9** only for glass look — not as the HDR fix.
6. Leave `sdrbrightness` alone once the desktop feels right (~`1.3` here).

**Do not** “fix dim Chrome” by cranking `sdrbrightness` (washes the desktop)
or by permanently disabling Wayland CM (kills HDR video).

---

## 1. Enable HDR on the monitor

Edit `~/.config/hypr/monitors.lua` (Omarchy Lua config).

```lua
-- Example — replace output/mode/scale with your panel
-- reference_luminance requires Hyprland with the PR #16247 patch (0.56.2-3.1+ local).
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
  reference_luminance = 390, -- ≈ sdr_max * sdrbrightness; stock Hyprland rejects this field
})
```

Verify:

```bash
hyprctl reload
hyprctl monitors -j | jq '.[0] | {currentFormat, colorManagementPreset, sdrBrightness, sdrMaxLuminance}'
# Patched binary must be what is running (relogin after pacman -U):
strings /proc/$(pgrep -n Hyprland)/exe | grep reference_luminance
```

Expect something like:

- `currentFormat`: `XBGR2101010` (10-bit)
- `colorManagementPreset`: `hdr`
- `sdrBrightness`: your value (e.g. `1.3`)
- Running `Hyprland` contains the string `reference_luminance`

Prove CM clients see the new reference:

```bash
WAYLAND_DEBUG=1 timeout 5 google-chrome-stable \
  --user-data-dir=/tmp/cm-test --no-first-run --disable-extensions \
  --ozone-platform=wayland about:blank 2>&1 \
  | grep luminances
# Expect: luminances(..., 390)  — third value is reference white (nits)
```

List modes / outputs: `hyprctl monitors all`.

### Don’t do this when Chromium looks dim

Do **not** keep cranking `sdrbrightness` / `sdrsaturation` to “fix Chrome”.
In practice:

- `1.3` → baseline that felt fine for the desktop  
- `1.5`–`1.6` → briefly “brighter” then **washed / gray**  
- Revert and raise **`reference_luminance`** (or install the patched compositor),
  not monitor SDR boosts  

If Chrome still looks a bit soft after luminance matches, check **opacity 0.9**
window rules (aesthetics) separately from CM.

### Local Hyprland package

Sibling project: `/home/warexpor/Work/MyProjects/hyprland-hdr-fix`

```bash
cd ~/Work/MyProjects/hyprland-hdr-fix/packaging
# after deps: glaze hyprland-protocols hyprwayland-scanner meson ninja
makepkg -f
sudo pacman -U hyprland-0.56.2-3.2-*.pkg.tar.zst hyprpm-0.56.2-3.2-*.pkg.tar.zst
# Full compositor restart (logout), not only hyprctl reload
```

`omarchy update` can replace this with stock `extra/hyprland`. The post-update
hook `~/.config/omarchy/hooks/post-update.d/hyprland-hdr-restore.sh` re-runs
`pacman -U` on the newest packages under
`~/.config/omarchy/hyprland-hdr-pkg-dir` (default:
`~/Work/MyProjects/hyprland-hdr-fix/packaging`) when they are still
newer-or-equal than the installed version. If upstream jumps ahead (e.g. 0.57),
it notifies instead of downgrading — rebuild the local package first.

Upstream has not landed `reference_luminance` yet (PR closed on contributor
policy, not technical rejection). See also Hyprland discussions #14999 / #15578.

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

Theme paste helpers: [`extras/hyprland-blur-chromium.lua`](../extras/hyprland-blur-chromium.lua),
[`extras/looknfeel-blur.lua`](../extras/looknfeel-blur.lua).

---

## 3. Chromium / Electron color management

### Preferred: native CM + `reference_luminance`

With the patched compositor and a correct `reference_luminance`, **do not** add:

```text
--force-color-profile=srgb
--disable-features=WaylandWpColorManagerV1
```

Those force the compositor-SDR path, fix dim UI the blunt way, and **disable
in-browser HDR**. They are retired on this machine (flags stripped; sync hooks
paused).

Confirm a process is on CM:

```bash
pgrep -af '/opt/google/chrome/chrome' | grep -v -- '--type=' | head -1
# Should NOT contain WaylandWpColorManagerV1 or force-color-profile=srgb
```

### Legacy workaround (stock Hyprland only)

If you are stuck on **unpatched** Hyprland (no `reference_luminance`), the old
crutch still works: inject the two flags via
[`extras/chromium-sdr-sync`](../extras/chromium-sdr-sync) /
[`extras/install-hdr-blur.sh`](../extras/install-hdr-blur.sh).

On this box the sync script **no-ops** while
`~/.local/share/chromium-sdr/CM-TEST-ACTIVE` exists, and Omarchy
`post-boot` / `post-update` hooks are renamed `*.disabled-for-cm-test`.
Do not re-enable those hooks unless you intentionally roll back to the crutch.

Apps that used to need flag files / wrappers (now CM-clean here): Chrome,
Chromium, Cursor, Electron42/43, Brave*, Edge, Spotify, Obsidian, Grok Bot,
Claude Desktop, MarkText, Unity Hub, ZCode, etc.

### Desktop file landmines (still real)

If `~/.local/share/applications/foo.desktop` has Windows `CRLF` endings, XDG
ignores it and falls back to `/usr/share/applications/…`. Always LF-only;
prefer absolute `Exec=` when wrapping. Cursor must launch via `/usr/bin/cursor`
so it reads `cursor-flags.conf`.

---

## 4. Discord Go Live / screen share

`reference_luminance` fixes **UI dimness**. Discord streaming is a separate
pipeline (HDR/10-bit desktop → PipeWire → encode), but on this box the combo
below is **verified stable** (2026-09-20 — no Voice/Media SIGTRAP after the
compositor fix + CM-on Discord launcher).

| Layer | Mitigation |
|-------|------------|
| Matched paper white for Electron CM | Hyprland `reference_luminance` (required) |
| 10-bit negotiation (`no more input formats`) | `misc:screencopy_force_8b = true` |
| NVIDIA DMA-BUF OOM / “Out of buffers” | xdph `force_shm = true` |
| Soft-encode pressure | xdph `max_fps = 24` |
| NVENC H.265 Go Live SIGTRAP | `discord-no-nvenc-golive` disables `go_live_hardware` + helper |
| Soft-encode / GPU buffer path | `--disable-accelerated-video-encode`, `--disable-gpu-memory-buffer-video-frames` |

CM kill-switches are **not** used on Discord (same as Chrome). Encode/capture
rows above are streaming hygiene, not the old “force SDR for brightness” crutch.

Further capture tonemap polish (erikwb-style HDR→SDR mirrors) is optional if
shares look washed; it is not required for crash-free Go Live here.

---

## 5. Terminal / TUI blur (Foot)

Hyprland window opacity on terminals fades **text** too. Better: keep the
window opaque and use Foot’s own alpha + compositor blur protocol.

Foot **1.28+**: there is **no** `[colors]` section. Use:

```ini
[colors-dark]
alpha=0.8
alpha-mode=all
blur=yes

[colors-light]
alpha=0.8
alpha-mode=all
blur=yes
```

**`alpha-mode=all` is the systemic TUI glass fix.** Default mode only applies
alpha to cells using the terminal’s default background. Gum, Bubble Tea, OpenTUI,
and similar apps paint **explicit** backgrounds, so those plates stay fully
opaque unless you set `all`. Theme paste: [`extras/foot-blur.ini`](../extras/foot-blur.ini).

**Text selection is a separate hole:** stock Foot always paints the highlight
opaque (upstream #2073). With blur + `alpha-mode=all`, that reads as a solid
plate that kills frost under the selection. Install the patched binary:

```bash
./extras/install-foot-selection-alpha.sh   # also registers Omarchy post-update hook
```

Durable: `~/.local/share/43pr-foot/` + `post-update.d/43pr-foot-selection-alpha.sh`
rebuilds when the stock `foot` package version changes. Theme `selection` is
`#666666` so the frosted highlight stays readable (darker `#2a2a2a` disappears
once selection shares window alpha).

Notes:

- `blur=yes` needs Hyprland’s `ext-background-effect-v1` (Omarchy/Hyprland 0.56+).
- Do not put the literal text `[colors]` in comments (Foot may parse it).
- After changing alpha / blur, open a **new** terminal.
- Hyprland: leave `terminal` tagged windows at opacity `1.0`.

---

## 6. Diagnosing “still dim” vs “too bright”

### A/B: opacity vs color management

```bash
hyprctl eval 'o.window("google-chrome", { opacity = "1.0 override 1.0 override" })'
```

- **Blur gone, still dim** → reference / CM path (`reference_luminance`, or
  accidental SDR kill-switch still in argv).  
- **Brightens when solid** → opacity / blur wash (nudge `0.9` ↔ `0.96`).  

### Chrome dim with CM on, desktop bright

Almost always: `reference_luminance` too low vs `sdr_max_luminance * sdrbrightness`.
Bump reference (or set `sdrbrightness = 1.0` and `reference_luminance = sdr_max`).

### Washed gray desktop after “fixing”

You probably raised `sdrbrightness` / `sdrsaturation`. Put them back and fix
**reference**, not the whole desktop.

### Screen recording looks washed / overbright

Omarchy’s stock recorder runs `gpu-screen-recorder` on the live HDR
framebuffer. GSR’s HDR→SDR tonemap does not match this box’s
`sdrbrightness` / `sdr_max_luminance`.

**Choice on this machine:** keep **stock HDR recording**. Grade the file in an
editor if it matters. Capture menu / Alt+Print stay on stock HDR (`-k auto`).

---

## 7. Checklist (new Omarchy HDR box)

1. [ ] Local Hyprland with `reference_luminance` installed; **full session restart**.  
2. [ ] Monitor: `bitdepth = 10`, `cm = "hdr"`, sane `sdrbrightness` (~1.2–1.4).  
3. [ ] `reference_luminance ≈ sdr_max_luminance × sdrbrightness`.  
4. [ ] `hyprctl monitors` shows 10-bit + `hdr`; binary contains `reference_luminance`.  
5. [ ] Chromium/Electron: **no** SDR kill-switch flags in argv.  
6. [ ] WAYLAND_DEBUG `luminances` third value matches your reference.  
7. [ ] Blur on in `looknfeel.lua` if you want glass; Chromium opacity `0.9` without stacking.  
8. [ ] `no_auto_hdr` on windows.  
9. [ ] Foot: `[colors-dark]` / `[colors-light]` alpha + `alpha-mode=all` + `blur=yes`.  
10. [ ] Never use `sdrbrightness` as the Chromium dim hammer.  
11. [ ] Discord: encode/capture mitigations only; CM left on.  
12. [ ] `screencopy_force_8b` + xdph `force_shm` for share stability.  

---

## 8. File map (this machine)

```text
~/.config/hypr/monitors.lua          # HDR + reference_luminance
~/.config/hypr/looknfeel.lua         # blur / screencopy_force_8b
~/.config/hypr/hyprland.lua          # opacity + no_auto_hdr + class list
~/.config/hypr/xdph.conf             # force_shm, max_fps for Discord share

~/.config/chrome-flags.conf          # Omarchy extras only — no SDR kill-switches
~/.config/cursor-flags.conf          # empty / comments (CM on)
~/.config/electron*-flags.conf

~/Work/MyProjects/hyprland-hdr-fix/ # local Hyprland 0.56.2-3.1 package + patch

~/.local/bin/grok-bot                # proxy helper only (no SDR flags)
~/.local/bin/claude-desktop
~/.local/bin/marktext
~/.local/bin/discord-no-nvenc-golive # encode mitigations; CM on
~/.local/share/chromium-sdr/CM-TEST-ACTIVE  # blocks chromium-sdr-sync re-inject

~/.config/omarchy/bin/gpu-screen-recorder
~/.config/foot/foot.ini              # colors-dark/light alpha + blur
```

---

## 9. References / upstream context

- Hyprland discussions #14999 / #15578 — CM clients stuck at 203 nits;
  `reference_luminance` / proper anchoring.  
- Closed PR #16247 — working patch; closed for vouching/AI policy, not tech.  
- Sibling `hyprland-hdr-fix` — local package + `FIX-PATH.md`.  
- Hyprland: opacity rules **multiply** unless you use `override`.  
- Foot 1.28+: `colors-dark` / `colors-light` only; `ext-background-effect-v1` for blur.  
- Omarchy: user Hyprland Lua under `~/.config/hypr/`; never edit `/usr/share/omarchy/` for this.

---

## 10. Adding a new Electron app later

1. Install the app. **Do not** run `chromium-sdr-sync` while CM-TEST-ACTIVE exists.  
2. Fully quit/relaunch. Confirm argv has **no** SDR kill-switches.  
3. If dim: check `reference_luminance` and `hyprctl clients` class / opacity stacking
   (CRLF `.desktop` bypass still applies).  
4. Opacity: default `0.9` usually already applies via the Chromium class regex.  
5. Never “fix dim” by raising monitor `sdrbrightness`.

That’s the loop — HDR on the panel, **matched reference white** for CM clients,
opacity only for aesthetics, Discord encode path treated separately.
