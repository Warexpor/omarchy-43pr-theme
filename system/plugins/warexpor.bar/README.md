# 43PR Adaptive Ink Bar

A full Omarchy Quattro bar with monochrome controls and per-pixel adaptive
contrast. Icons sample the current wallpaper so they remain readable over
light and dark areas while preserving tray artwork.

## Install

```bash
omarchy plugin add https://github.com/Warexpor/omarchy-43pr-adaptive-bar-plugin.git --enable
omarchy bar use warexpor.bar
```

For the complete matching layout, theme, companion plugins, and screensaver,
use the desktop installer in
[`omarchy-43pr-theme`](https://github.com/Warexpor/omarchy-43pr-theme).

## Remove

```bash
omarchy bar reset
omarchy plugin remove warexpor.bar
```

## Runtime surface

- Reads Omarchy shell state and the current wallpaper.
- Writes a generated contrast strip under `~/.cache/omarchy/`.
- Runs bundled `bin/bar-wallpaper-strip` and standard Omarchy/Hyprland
  commands used by bar widgets.
- Executes command-widget strings that the user explicitly puts in their bar
  configuration.
- Does not use the network or privileged commands.

## Compatibility

Requires Omarchy Quattro and its bundled Quickshell modules. The manifest
marks this as a customized replacement for `omarchy.bar`, allowing Omarchy to
restore the stock bar when the plugin is removed.

## License and origin

MIT. Derived from Omarchy's MIT-licensed `omarchy.bar`; modifications and the
adaptive-ink implementation are maintained by Warexpor. See [LICENSE](LICENSE).
