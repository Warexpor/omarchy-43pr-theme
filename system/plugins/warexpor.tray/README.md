# 43PR System tray

Cloned Omarchy tray with fixes so RMB menus stay usable:

- Drawer stays open while a menu or manage popup is up
- Menu opens on click (not press), so RMB release into the popup gap
  cannot clear `HyprlandFocusGrab` and dismiss the menu
- Zero popup margin so there is no dead strip between icon and card

## Install

Bundled by `install-desktop.sh` from this theme tree into
`~/.config/omarchy/plugins/warexpor.tray/`. Manual:

```bash
rsync -a --delete system/plugins/warexpor.tray/ ~/.config/omarchy/plugins/warexpor.tray/
omarchy plugin validate ~/.config/omarchy/plugins/warexpor.tray
omarchy plugin enable warexpor.tray
```

The bar layout entry is `warexpor.tray` (stock `omarchy.tray` stays disabled).

## Notes

This is theme-local, not a separate public git plugin. `omarchy update` does
not overwrite it. Re-run `install-desktop.sh` (or the rsync above) to refresh
from the theme source.
