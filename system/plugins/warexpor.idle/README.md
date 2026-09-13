# 43PR Idle

An Omarchy Quattro idle service with stay-awake state, reliable lock/wake
handling, and optional integration with the 43PR frosted monochrome
screensaver. Without the desktop bundle it falls back to Omarchy's stock
screensaver launcher.

## Install

```bash
omarchy plugin add https://github.com/Warexpor/omarchy-43pr-idle-plugin.git --enable
omarchy plugin disable omarchy.idle
```

The complete 43PR desktop installer adds the matching screensaver:
[`omarchy-43pr-theme`](https://github.com/Warexpor/omarchy-43pr-theme).

## Remove

```bash
omarchy plugin remove warexpor.idle
omarchy plugin enable omarchy.idle
```

## Runtime surface

- Watches Hyprland idle and screensaver-window events.
- Reads and writes `~/.local/state/omarchy/indicators/stay-awake`.
- Runs Omarchy's stock lock, wake, and screensaver commands.
- Uses the user-level 43PR screensaver launcher only when it is installed.
- Does not use the network or privileged commands.

## Compatibility

Requires Omarchy Quattro. The manifest marks this as a customized replacement
for `omarchy.idle`, allowing Omarchy to restore the stock service on removal.

## License and origin

MIT. Derived from Omarchy's MIT-licensed idle service and maintained by
Warexpor. See [LICENSE](LICENSE).
