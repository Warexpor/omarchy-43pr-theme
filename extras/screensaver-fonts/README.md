# Screensaver bake fonts (OFL)

Preview candidates in a browser:

```bash
xdg-open extras/screensaver-fonts/preview.html
# or open file:///.../extras/screensaver-fonts/preview.html
```

Install into the font cache (needed only to re-bake braille art):

```bash
mkdir -p ~/.local/share/fonts/omarchy-screensaver
cp extras/screensaver-fonts/*.ttf ~/.local/share/fonts/omarchy-screensaver/
fc-cache -f ~/.local/share/fonts/omarchy-screensaver
```

Candidates: UnifrakturCook, Pirata One, New Rocker, Metamorphous, MedievalSharp, Cinzel Decorative.
