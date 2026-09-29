# 43PR Outline Bar

A full Omarchy Quattro bar with monochrome controls and white icons rimmed by
a thin 1px black outline (four cardinal offsets). Readable on light or dark
wallpaper without flipping ink color. Grayscale tray icons keep their shading;
colored tray pixels stay as-is. Both are rimmed.

Tray behavior lives in `warexpor.tray` (theme-bundled), not in this bar package.

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

- Reads Omarchy shell state for bar layout and theme colors.
- Composites white mono ink plus a crisp black outline in-process (no wallpaper
  sampling, no cache strip).
- Runs standard Omarchy/Hyprland commands used by bar widgets.
- Executes command-widget strings that the user explicitly puts in their bar
  configuration.
- Does not use the network or privileged commands.

## Compatibility

Requires Omarchy Quattro and its bundled Quickshell modules. The manifest
marks this as a customized replacement for `omarchy.bar`, allowing Omarchy to
restore the stock bar when the plugin is removed.

## License and origin

MIT. Derived from Omarchy's MIT-licensed `omarchy.bar`; modifications and the
outline-ink implementation are maintained by Warexpor. See [LICENSE](LICENSE).
