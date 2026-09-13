# 43PR Image Picker

A self-contained Omarchy Quattro image-grid overlay for choosing wallpapers,
themes, and images from arbitrary directories.

## Install

```bash
omarchy plugin add https://github.com/Warexpor/omarchy-43pr-image-picker-plugin.git --enable
omarchy plugin disable omarchy.image-picker
```

## Remove

```bash
omarchy plugin remove warexpor.image-picker
omarchy plugin enable omarchy.image-picker
```

## Runtime surface

- Reads image directories supplied by Omarchy's image-selector environment.
- Generates and reads thumbnails under `~/.cache/omarchy/image-selector/`.
- Writes the selected path only to the selection file requested by Omarchy.
- Uses the bundled `list.sh`; no downloads, network access, or privileged
  commands.

## Compatibility

Requires Omarchy Quattro, `md5sum`, and standard filesystem tools shipped by
Omarchy. The manifest marks this as a customized replacement for
`omarchy.image-picker`.

## License and origin

MIT. Derived from Omarchy's MIT-licensed image picker and maintained by
Warexpor. See [LICENSE](LICENSE).
