#!/usr/bin/env python3
# [macos] Average wallpaper colour along the top bar's strip, for the bar's adaptive ink (BarInk.qml).
# usage: wallstrip.py <wallpaper> <screen>:<logical width>:<logical height> ...
# prints {"<screen>": [[r, g, b], ...]} (sRGB 0..1, COLS columns left to right). The wallpaper is
# fitted like Caelestia draws it (PreserveAspectCrop, centred). Prints {} if it can't be read.
import json
import sys

COLS = 64
STRIP = (4, 34)  # logical px from the top: the pills (y 8..30) plus a little around them

out = {}
try:
    from PIL import Image, ImageOps

    src = Image.open(sys.argv[1])
    src.draft("RGB", (1024, 1024))  # JPEGs decode at a fraction of their size
    src = src.convert("RGB")
    for arg in sys.argv[2:]:
        name, w, h = arg.rsplit(":", 2)
        w, h = int(w), int(h)
        sw = COLS * 8
        sh = max(1, round(sw * h / w))
        img = ImageOps.fit(src, (sw, sh), Image.Resampling.BOX, centering=(0.5, 0.5))
        y0, y1 = (max(1, round(v * sh / h)) for v in STRIP)
        strip = img.crop((0, y0 - 1, sw, y1)).resize((COLS, 1), Image.Resampling.BOX)
        out[name] = [[round(c / 255, 4) for c in strip.getpixel((x, 0))] for x in range(COLS)]
except Exception as e:  # missing file / PIL: the bar keeps the scheme's colours
    print(f"wallstrip: {e}", file=sys.stderr)
    out = {}

print(json.dumps(out))
