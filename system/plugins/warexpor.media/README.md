# 43PR Media

A monochrome Omarchy Quattro MPRIS service and compact now-playing bar widget
with playback controls and artwork-aware presentation.

## Install

```bash
omarchy plugin add https://github.com/Warexpor/omarchy-43pr-media-plugin.git --enable
omarchy plugin disable omarchy.media
```

## Remove

```bash
omarchy plugin remove warexpor.media
omarchy plugin enable omarchy.media
```

## Runtime surface

- Reads local MPRIS player metadata and PipeWire state through Quickshell.
- Sends play, pause, previous, and next commands only after user interaction.
- Uses Omarchy's local OSD service.
- Does not write files, use the network, or run privileged commands.

## Compatibility

Requires Omarchy Quattro. The manifest marks this as a customized replacement
for `omarchy.media`, which lets the shell route its stock service facade to
this implementation and restore the stock plugin on removal.

## License and origin

MIT. Derived from Omarchy's MIT-licensed media plugin and maintained by
Warexpor. See [LICENSE](LICENSE).
