#!/usr/bin/env python3
"""Generate OneQode interface themes for ONLYOFFICE Desktop Editors.

ONLYOFFICE themes are a JSON object {name,id,type,colors{}} where `colors`
maps CSS-variable names (without the leading `--`) to hex/rgba values. The
desktop app loads user themes from <userdata>/uithemes/*.json.

We take the stock built-in theme variables (extracted from the app's compiled
CSS: `.theme-night` for dark, `.theme-classic-light` for light) and re-tint
every COLOUR value onto a OneQode ramp, preserving luminance and alpha so
contrast/legibility is kept. Neutral greys map onto the OneQode blue-black
(Night Ride) or soft-white (Light Glass) ramp; ONLYOFFICE's accent blues map to
OneQode magenta/cyan/teal. Non-colour values (sizes, filters) pass through.

The document *page* (`canvas-content-background`) is deliberately left at the
stock value — a genuinely dark page with readable text is handled by the
editor's separate "dark document" toggle, which our installer enables.

Usage: build-theme.py <nightride|lightglass> <app-all.css> <out.json>
"""
import json
import re
import sys

THEMES = {
    "nightride": {
        "id": "theme-oneqode-nightride",
        "name": "OneQode Night Ride",
        "type": "dark",
        "css_selector": "theme-night",
        "ramp": [  # luminance floor -> hex (light to dark)
            (0.90, "e6ebf5"), (0.72, "c2c8d8"), (0.58, "9aa0b4"),
            (0.42, "3a4258"), (0.30, "2d3447"), (0.22, "232a3a"),
            (0.14, "1e2230"), (0.07, "191c2a"), (0.00, "12141f"),
        ],
        "accents": {
            # ONLYOFFICE blue accent family -> OneQode magenta (matches KDE accent)
            "4a7be0": "ff0080", "446995": "ff0080", "366cda": "ff3399",
            "2a5bb9": "cc0066", "4a87e7": "ff0080", "1284ee": "ff0080",
            # links / selection / hovers -> OneQode cyan
            "92b7f0": "00c8ff", "b7cff5": "66dbff", "3494fb": "00c8ff",
            "445799": "00c8ff",
        },
        # explicit brand touches: magenta = primary/active, cyan = focus/links
        "overrides": {
            # active ribbon-tab underline (the signature always-visible cue)
            "highlight-toolbar-tab-underline-document": "#ff0080",
            "highlight-toolbar-tab-underline-spreadsheet": "#ff0080",
            "highlight-toolbar-tab-underline-presentation": "#ff0080",
            "highlight-toolbar-tab-underline-pdf": "#ff0080",
            "highlight-toolbar-tab-underline-visio": "#ff0080",
            "highlight-header-tab-underline-document": "#ff0080",
            "highlight-header-tab-underline-spreadsheet": "#ff0080",
            "highlight-header-tab-underline-presentation": "#ff0080",
            "highlight-header-tab-underline-pdf": "#ff0080",
            "highlight-header-tab-underline-visio": "#ff0080",
            # primary buttons -> magenta
            "background-accent-button": "#ff0080",
            "background-primary-dialog-button": "#ff0080",
            "highlight-primary-dialog-button-hover": "#ff3399",
            "highlight-primary-dialog-button-pressed": "#cc0066",
            "background-fill-button": "#ff0080",
            "highlight-fill-button-hover": "#ff3399",
            "highlight-fill-button-pressed": "#cc0066",
            # sliders / progress -> magenta
            "slider-track-background-filled": "#ff0080",
            "slider-thumb-background-normal": "#ff0080",
            "slider-thumb-background-active": "#ff3399",
            "slider-thumb-background-hover": "#ff3399",
            # selection + focus + links -> cyan
            "highlight-text-select": "#00c8ff",
            "border-control-focus": "#00c8ff",
            "border-preview-select": "#00c8ff",
            "border-preview-hover": "#00c8ff",
            "border-fill-input-focused": "#00c8ff",
            "border-button-pressed-focus": "#00c8ff",
            "border-control": "#00c8ff",
            "text-link": "#00c8ff", "text-link-hover": "#66dbff",
            "text-link-active": "#66dbff", "text-link-visited": "#00c8ff",
            # accent icons -> cyan
            "icon-blue-primary": "#00c8ff",
            "icon-blue-secondary": "#66dbff",
        },
    },
    "lightglass": {
        "id": "theme-oneqode-lightglass",
        "name": "OneQode Light Glass",
        "type": "light",
        "css_selector": "theme-classic-light",
        "ramp": [
            (0.90, "fafcff"), (0.78, "f0f4f8"), (0.64, "e4ebf2"),
            (0.50, "d4dde6"), (0.36, "5a6776"), (0.22, "3a4654"),
            (0.10, "232d37"), (0.00, "151b22"),
        ],
        "accents": {
            "446995": "00b4c8", "4a7be0": "00b4c8", "366cda": "0095a8",
            "2a5bb9": "0095a8", "445799": "0095a8", "848484": "0095a8",
            "92b7f0": "00b4c8", "3494fb": "00b4c8",
        },
        "overrides": {
            "highlight-toolbar-tab-underline-document": "#00b4c8",
            "highlight-toolbar-tab-underline-spreadsheet": "#00b4c8",
            "highlight-toolbar-tab-underline-presentation": "#00b4c8",
            "highlight-toolbar-tab-underline-pdf": "#00b4c8",
            "background-accent-button": "#00b4c8",
            "background-primary-dialog-button": "#00b4c8",
            "highlight-primary-dialog-button-hover": "#0095a8",
            "highlight-primary-dialog-button-pressed": "#007a8a",
            "slider-track-background-filled": "#00b4c8",
            "slider-thumb-background-normal": "#00b4c8",
            "highlight-text-select": "#00b4c8",
            "border-control-focus": "#00b4c8",
            "border-preview-select": "#00b4c8",
            "border-fill-input-focused": "#00b4c8",
            "text-link": "#0095a8", "text-link-hover": "#00b4c8",
            "text-link-active": "#00b4c8", "text-link-visited": "#0095a8",
        },
    },
}

HEX_RE = re.compile(r"^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")
RGBA_RE = re.compile(r"^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([0-9.]+)\s*)?\)$")


def luminance(r, g, b):
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0  # Rec.709


def saturation(r, g, b):
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) / 255.0 if mx else 0.0


def ramp_for(theme, lum):
    for floor, hexv in theme["ramp"]:
        if lum >= floor:
            return hexv
    return theme["ramp"][-1][1]


def retint(theme, r, g, b):
    lo = "%02x%02x%02x" % (r, g, b)
    if lo in theme["accents"]:
        h = theme["accents"][lo]
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    if saturation(r, g, b) > 0.22:          # keep brand/semantic colours
        return r, g, b
    h = ramp_for(theme, luminance(r, g, b))  # neutral grey -> OneQode ramp
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def remap_value(theme, value):
    value = value.strip()
    m = HEX_RE.match(value)
    if m:
        s = m.group(1)
        if len(s) == 3:
            s = "".join(c * 2 for c in s)
        alpha = s[6:] if len(s) == 8 else ""
        r, g, b = int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)
        nr, ng, nb = retint(theme, r, g, b)
        return "#%02x%02x%02x%s" % (nr, ng, nb, alpha)
    m = RGBA_RE.match(value)
    if m:
        r, g, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
        a = m.group(4)
        nr, ng, nb = retint(theme, r, g, b)
        return ("rgba(%d,%d,%d,%s)" % (nr, ng, nb, a)) if a is not None \
            else ("rgb(%d,%d,%d)" % (nr, ng, nb))
    return None  # not a colour -> skip (sizes, filters, var() refs, etc.)


def extract_vars(css, selector):
    m = re.search(r"\.%s\s*\{(.*?)\}" % re.escape(selector), css, re.S)
    if not m:
        sys.exit("could not find .%s block in CSS" % selector)
    return re.findall(r"(--[a-z0-9-]+)\s*:\s*([^;]+);", m.group(1))


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    which, css_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
    theme = THEMES[which]
    css = open(css_path, encoding="utf-8", errors="replace").read()

    colors = {}
    for var, value in extract_vars(css, theme["css_selector"]):
        key = var[2:]  # drop leading --
        # leave var()-references and non-colours alone (theme inherits them)
        if "var(" in value:
            continue
        new = remap_value(theme, value)
        if new is not None:
            colors[key] = new
    colors.update(theme["overrides"])

    out_obj = {
        "name": theme["name"],
        "id": theme["id"],
        "type": theme["type"],
        "colors": colors,
    }
    with open(out, "w", encoding="utf-8") as f:
        json.dump(out_obj, f, indent=2)
    print(f"wrote {theme['name']}: {len(colors)} colours -> {out}")


if __name__ == "__main__":
    main()
