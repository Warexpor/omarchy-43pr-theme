# 43PR Display

A monochrome Omarchy Quattro bar widget for display brightness and laptop
panel controls.

## Install

```bash
omarchy plugin add https://github.com/Warexpor/omarchy-43pr-monitor-plugin.git --enable
omarchy plugin disable omarchy.monitor
```

## Remove

```bash
omarchy plugin remove warexpor.monitor
omarchy plugin enable omarchy.monitor
```

## Runtime surface

- Reads monitor state through Omarchy and Hyprland helpers.
- Changes brightness or display state only after user interaction.
- Uses standard Omarchy monitor commands.
- Does not use the network or privileged commands.

## Compatibility

Requires Omarchy Quattro. The manifest marks this as a customized replacement
for `omarchy.monitor`, allowing the stock display widget to return on removal.

## License and origin

MIT. Derived from Omarchy's MIT-licensed monitor plugin and maintained by
Warexpor. See [LICENSE](LICENSE).
