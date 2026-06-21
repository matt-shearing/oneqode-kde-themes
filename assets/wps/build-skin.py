#!/usr/bin/env python3
"""Generate OneQode WPS Office skins by re-tinting a bundled skin palette.

WPS Office (Linux, 11.1.x) draws its chrome from editable XML palette files
(*.kuip) inside a skin folder, PLUS bitmap resources (*.rcc) for the ribbon
background and icons. The stock `2019dark` skin ships no dark .rcc, so its
ribbon stays light; `2018white_dark` ("Clear (Dark Beta)") DOES ship dark .rcc
and an already-dark palette, so we base on it.

We re-tint every palette colour onto a OneQode ramp while PRESERVING luminance
(so layout/contrast is kept) and alpha. Near-neutral greys are mapped onto the
OneQode blue-black ramp; saturated colours (accents) are left alone except for
explicit accent swaps (WPS blue -> OneQode cyan/teal). The dark .rcc files are
copied verbatim from the base skin so the ribbon bitmaps are dark too.

Usage: build-skin.py <theme: nightride|lightglass> <src_skin_dir> <out_skin_dir>
"""
import os
import re
import shutil
import sys

# OneQode ramps: ordered light -> dark, each (luminance_floor, hex). A neutral
# grey of luminance L is mapped to the first entry whose floor it meets, so the
# perceived lightness (and thus contrast/legibility) is preserved.
THEMES = {
    "nightride": {
        "ramp": [
            (0.90, "e6ebf5"),  # near-white text
            (0.72, "c2c8d8"),
            (0.58, "9aa0b4"),  # muted text
            (0.42, "3a4258"),
            (0.30, "2d3447"),  # raised panel
            (0.22, "232a3a"),  # panel
            (0.14, "1e2230"),  # ribbon/base
            (0.07, "191c2a"),  # window base
            (0.00, "12141f"),  # deepest
        ],
        "accents": {
            "1f75cc": "00c8ff", "0d6fcc": "00c8ff", "3b8bea": "33d4ff",
            "1664c8": "00c8ff", "417ff5": "33d4ff",
        },
    },
    "lightglass": {
        "ramp": [
            (0.90, "fafcff"),  # page/base
            (0.78, "f0f4f8"),
            (0.64, "e4ebf2"),
            (0.50, "d4dde6"),
            (0.36, "5a6776"),
            (0.22, "3a4654"),
            (0.10, "232d37"),  # primary text
            (0.00, "151b22"),
        ],
        "accents": {
            "1f75cc": "00b4c8", "0d6fcc": "0095a8", "3b8bea": "00b4c8",
            "1664c8": "0095a8", "417ff5": "00b4c8",
        },
    },
}

COLOR_RE = re.compile(r'(<color\b[^>]*?value=")(#[0-9a-fA-F]{3,8})(")')


def luminance(r, g, b):
    return (0.2126 * r + 0.7152 * g + 0.4587 * b) / 255.0


def saturation(r, g, b):
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) / 255.0


def parse_hex(value):
    """#RGB / #RRGGBB / #RRGGBBAA -> (r,g,b, alpha_hex_or_empty) or None."""
    s = value[1:]
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    if len(s) == 8:
        rgb, alpha = s[:6], s[6:]
    elif len(s) == 6:
        rgb, alpha = s, ""
    else:
        return None
    return int(rgb[0:2], 16), int(rgb[2:4], 16), int(rgb[4:6], 16), alpha


def ramp_for(theme, lum):
    for floor, hexv in theme["ramp"]:
        if lum >= floor:
            return hexv
    return theme["ramp"][-1][1]


def remap(theme, value):
    parsed = parse_hex(value)
    if parsed is None:
        return value
    r, g, b, alpha = parsed
    lo = "%02x%02x%02x" % (r, g, b)

    # explicit accent swaps win
    if lo in theme["accents"]:
        return "#" + theme["accents"][lo] + alpha

    # leave saturated colours (brand reds/greens/yellows, links) untouched
    if saturation(r, g, b) > 0.22:
        return value

    # neutral grey: re-tint onto the OneQode ramp at matching luminance
    return "#" + ramp_for(theme, luminance(r, g, b)) + alpha


def transform(theme, text):
    return COLOR_RE.sub(lambda m: m.group(1) + remap(theme, m.group(2)) + m.group(3), text)


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    theme_name, src, out = sys.argv[1], sys.argv[2], sys.argv[3]
    theme = THEMES[theme_name]
    base = os.path.basename(src.rstrip("/"))

    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(out)

    n = 0
    for fn in os.listdir(src):
        sp = os.path.join(src, fn)
        if fn.endswith(".kuip") and os.path.isfile(sp):
            with open(sp, encoding="utf-8") as f:
                txt = f.read()
            with open(os.path.join(out, fn), "w", encoding="utf-8") as f:
                f.write(transform(theme, txt))
            n += 1

    # copy the base skin's dark bitmap resources (ribbon background, icons)
    src_default = os.path.join(src, "default")
    if os.path.isdir(src_default):
        shutil.copytree(src_default, os.path.join(out, "default"))

    # reuse the base skin's skin.ini verbatim. We copy ALL of the base skin's
    # palettes and .rcc resources, so we keep its original baseSkin (e.g.
    # 2018white) rather than chaining onto the source folder — chaining onto a
    # hidden "Beta" skin made WPS reject the skin and fall back to light.
    with open(os.path.join(src, "skin.ini"), encoding="utf-8") as f:
        ini = f.read()
    with open(os.path.join(out, "skin.ini"), "w", encoding="utf-8") as f:
        f.write(ini)

    print(f"wrote {theme_name}: {n} palettes, base={base} -> {out}")


if __name__ == "__main__":
    main()
