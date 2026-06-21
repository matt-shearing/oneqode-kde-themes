#!/usr/bin/env python3
"""Patch ONLYOFFICE Desktop Editors' BUILT-IN dark theme to OneQode Night Ride.

ONLYOFFICE's custom-theme (uithemes/*.json) loader silently ignores accent
keys, so a custom theme can only darken backgrounds — never recolour the active
tab underline, accent buttons, selection, links, etc. The built-in themes,
however, apply every colour. So we edit the real `.theme-night{...}` variable
block (the "Dark" theme) in the program files: re-tint neutral greys onto the
OneQode navy ramp, and force the accent variables to OneQode magenta/cyan.

Runs over every css/html file under the editors dir that defines `.theme-night{`
(and `.theme-contrast-dark{`, the "Modern Dark" theme). Originals are backed up
to <file>.oqbak and patched from that pristine copy each run (idempotent).

Usage (needs root, files live under /opt):
    sudo python3 patch-builtin.py            # apply OneQode Night Ride
    sudo python3 patch-builtin.py --revert   # restore the originals
"""
import os
import re
import shutil
import sys

EDITORS_DIR = "/opt/onlyoffice/desktopeditors/editors"
DARK_SELECTORS = ("theme-night", "theme-contrast-dark")
# Light themes ("Light"/"Classic Light"): keep them light, only brand the
# accents teal (Light Glass). No neutral re-tint — light surfaces stay readable.
LIGHT_SELECTORS = ("theme-classic-light", "theme-white")
ALL_SELECTORS = DARK_SELECTORS + LIGHT_SELECTORS

# OneQode Night Ride neutral ramp: luminance floor -> hex (light to dark)
RAMP = [
    (0.90, "e6ebf5"), (0.72, "c2c8d8"), (0.58, "9aa0b4"),
    (0.42, "3a4258"), (0.30, "2d3447"), (0.22, "232a3a"),
    (0.14, "1e2230"), (0.07, "191c2a"), (0.00, "12141f"),
]
# ONLYOFFICE accent colours -> OneQode (magenta = primary, cyan = links/focus)
ACCENTS = {
    "4a7be0": "ff0080", "446995": "ff0080", "366cda": "ff3399", "2a5bb9": "cc0066",
    "4a87e7": "ff0080", "1284ee": "ff0080", "486f9e": "ff0080", "4d76a8": "ff0080",
    "4473ca": "ff0080",
    "92b7f0": "00c8ff", "b7cff5": "66dbff", "3494fb": "00c8ff", "445799": "00c8ff",
    "96c8fd": "00c8ff", "b5e4ff": "66dbff",
}
# CSS variables forced to a OneQode accent regardless of their stock value
FORCE = {
    "background-accent-button": "#ff0080",
    "background-primary-dialog-button": "#ff0080",
    "highlight-primary-dialog-button-hover": "#ff3399",
    "highlight-primary-dialog-button-pressed": "#cc0066",
    "highlight-text-select": "#00c8ff",
    "border-control-focus": "#00c8ff",
    "border-preview-select": "#00c8ff",
    "border-preview-hover": "#00c8ff",
    "border-button-pressed-focus": "#00c8ff",
    "border-fill-input-focused": "#00c8ff",
    "text-link": "#00c8ff", "text-link-hover": "#66dbff",
    "text-link-active": "#66dbff", "text-link-visited": "#00c8ff",
    "icon-blue-primary": "#00c8ff", "icon-blue-secondary": "#66dbff",
}
for _ed in ("document", "spreadsheet", "presentation", "pdf", "visio"):
    FORCE["highlight-toolbar-tab-underline-" + _ed] = "#ff0080"
    FORCE["highlight-header-tab-underline-" + _ed] = "#ff0080"

# Light theme: OneQode Light Glass teal accents (applied without re-tinting).
LIGHT_FORCE = {
    "background-accent-button": "#00b4c8",
    "background-primary-dialog-button": "#00b4c8",
    "highlight-primary-dialog-button-hover": "#0095a8",
    "highlight-primary-dialog-button-pressed": "#007a8a",
    "highlight-text-select": "#00b4c8",
    "border-control-focus": "#00b4c8",
    "border-preview-select": "#00b4c8",
    "border-button-pressed-focus": "#00b4c8",
    "border-fill-input-focused": "#00b4c8",
    "text-link": "#0095a8", "text-link-hover": "#00b4c8",
    "text-link-active": "#00b4c8", "text-link-visited": "#0095a8",
}
for _ed in ("document", "spreadsheet", "presentation", "pdf", "visio"):
    LIGHT_FORCE["highlight-toolbar-tab-underline-" + _ed] = "#00b4c8"
    LIGHT_FORCE["highlight-header-tab-underline-" + _ed] = "#00b4c8"

HEX_RE = re.compile(r"#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b")
RGBA_RE = re.compile(r"rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*[0-9.]+\s*)?\)")


def lum(r, g, b):
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0


def sat(r, g, b):
    mx, mn = max(r, g, b), min(r, g, b)
    return (mx - mn) / 255.0 if mx else 0.0


def ramp(r, g, b):
    l = lum(r, g, b)
    for floor, h in RAMP:
        if l >= floor:
            return h
    return RAMP[-1][1]


def retint_rgb(r, g, b):
    lo = "%02x%02x%02x" % (r, g, b)
    if lo in ACCENTS:
        h = ACCENTS[lo]
    elif sat(r, g, b) > 0.22:        # keep brand/semantic colours
        return r, g, b
    else:
        h = ramp(r, g, b)            # neutral grey -> OneQode navy ramp
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def retint_token(value):
    m = HEX_RE.fullmatch(value)
    if m:
        s = m.group(1)
        if len(s) == 3:
            s = "".join(c * 2 for c in s)
        alpha = s[6:] if len(s) == 8 else ""
        r, g, b = int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)
        nr, ng, nb = retint_rgb(r, g, b)
        return "#%02x%02x%02x%s" % (nr, ng, nb, alpha)
    m = RGBA_RE.fullmatch(value)
    if m:
        r, g, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
        nr, ng, nb = retint_rgb(r, g, b)
        a = re.search(r",\s*([0-9.]+)\s*\)$", value)
        return ("rgba(%d,%d,%d,%s)" % (nr, ng, nb, a.group(1))) if a \
            else "rgb(%d,%d,%d)" % (nr, ng, nb)
    return value


def patch_block(block, dark):
    if dark:
        # re-tint every neutral colour onto the OneQode navy ramp
        block = HEX_RE.sub(lambda m: retint_token(m.group(0)), block)
        block = RGBA_RE.sub(lambda m: retint_token(m.group(0)), block)
    # force the accent variables (magenta/cyan for dark, teal for light)
    force = FORCE if dark else LIGHT_FORCE
    for var, val in force.items():
        block = re.sub(r"(--%s\s*:\s*)[^;}]+" % re.escape(var),
                       lambda m, v=val: m.group(1) + v, block)
    return block


def patch_text(text):
    changed = 0
    for sel in ALL_SELECTORS:
        dark = sel in DARK_SELECTORS
        pat = re.compile(r"\.%s\{[^}]*\}" % re.escape(sel))

        def repl(m, dark=dark):
            nonlocal changed
            changed += 1
            inner = m.group(0)
            head = inner[: inner.index("{") + 1]
            body = inner[inner.index("{") + 1: -1]
            return head + patch_block(body, dark) + "}"
        text = pat.sub(repl, text)
    return text, changed


def target_files():
    out = []
    for root, _dirs, files in os.walk(EDITORS_DIR):
        for fn in files:
            if not fn.endswith((".css", ".html")):
                continue
            p = os.path.join(root, fn)
            try:
                with open(p, encoding="utf-8", errors="replace") as f:
                    head = f.read()
            except OSError:
                continue
            if any(".%s{" % s in head for s in ALL_SELECTORS):
                out.append(p)
    return out


def main():
    revert = "--revert" in sys.argv[1:]
    files = target_files()
    if not files:
        sys.exit("No theme files found under %s — is OnlyOffice installed?" % EDITORS_DIR)
    n = 0
    for p in files:
        bak = p + ".oqbak"
        if revert:
            if os.path.exists(bak):
                shutil.copy2(bak, p)
                n += 1
            continue
        if not os.path.exists(bak):
            shutil.copy2(p, bak)                 # preserve pristine original
        src = open(bak, encoding="utf-8", errors="replace").read()
        patched, c = patch_text(src)
        if c:
            with open(p, "w", encoding="utf-8") as f:
                f.write(patched)
            n += 1
    print(("reverted " if revert else "patched ") + "%d files" % n)


if __name__ == "__main__":
    main()
