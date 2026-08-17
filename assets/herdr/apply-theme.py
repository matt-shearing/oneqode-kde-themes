#!/usr/bin/env python3
"""Merge a OneQode Herdr theme fragment into config.toml.

Herdr only ships built-in theme names plus a [theme.custom] override table.
These fragments are the OneQode Light Glass / Night Ride palettes; the
day/night switcher rewrites the managed block and reloads the server.
"""

from __future__ import annotations

import argparse
import os
import re
import sys

BEGIN = "# BEGIN ONEQODE THEME"
END = "# END ONEQODE THEME"

DEFAULT_CONFIG = os.path.expanduser("~/.config/herdr/config.toml")


def strip_theme_tables(text: str) -> str:
    """Drop unmanaged [theme] / [theme.*] tables (pre-marker installs)."""
    out: list[str] = []
    skipping = False
    for line in text.splitlines(True):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            name = stripped[1:-1].strip()
            if name == "theme" or name.startswith("theme."):
                skipping = True
                continue
            skipping = False
        if not skipping:
            out.append(line)
    return "".join(out)


def extract_accent(fragment: str) -> str | None:
    match = re.search(r'(?m)^accent\s*=\s*("#[0-9A-Fa-f]{6}")\s*$', fragment)
    return match.group(1) if match else None


def set_ui_accent(text: str, accent: str) -> str:
    """Set ui.accent without clobbering the rest of [ui]."""
    lines = text.splitlines(True)
    ui_idx = None
    next_section = len(lines)
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "[ui]":
            ui_idx = i
            continue
        if ui_idx is not None and i > ui_idx and stripped.startswith("[") and stripped.endswith("]"):
            next_section = i
            break

    if ui_idx is None:
        suffix = "" if text.endswith("\n") or not text else "\n"
        return f"{text}{suffix}\n[ui]\naccent = {accent}\n"

    for i in range(ui_idx + 1, next_section):
        if re.match(r"^accent\s*=", lines[i]):
            lines[i] = f"accent = {accent}\n"
            return "".join(lines)

    lines.insert(ui_idx + 1, f"accent = {accent}\n")
    return "".join(lines)


def strip_ui_accent(text: str) -> str:
    """Remove a ui.accent line we added. Leaves an empty [ui] alone."""
    lines = text.splitlines(True)
    ui_idx = None
    out: list[str] = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped == "[ui]":
            ui_idx = i
            out.append(line)
            continue
        if ui_idx is not None and stripped.startswith("[") and stripped.endswith("]"):
            ui_idx = None
        if ui_idx is not None and re.match(r"^accent\s*=", line):
            continue
        out.append(line)

    # Drop a now-empty [ui] table left behind after removing accent.
    cleaned: list[str] = []
    i = 0
    while i < len(out):
        if out[i].strip() == "[ui]":
            j = i + 1
            while j < len(out) and out[j].strip() == "":
                j += 1
            if j == len(out) or (out[j].strip().startswith("[") and out[j].strip().endswith("]")):
                i = j
                continue
        cleaned.append(out[i])
        i += 1
    return "".join(cleaned)


def wrap_block(fragment: str) -> str:
    body = fragment.strip() + "\n"
    return f"{BEGIN}\n{body}{END}\n"


def replace_block(text: str, block: str) -> str:
    pattern = re.compile(
        re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?",
        flags=re.S,
    )
    if pattern.search(text):
        return pattern.sub(block, text, count=1)
    cleaned = strip_theme_tables(text).rstrip() + "\n"
    if cleaned.strip():
        return cleaned + "\n" + block
    return block


def apply_fragment(config_path: str, fragment_path: str) -> None:
    with open(fragment_path, encoding="utf-8") as handle:
        fragment = handle.read()
    if os.path.exists(config_path):
        with open(config_path, encoding="utf-8") as handle:
            text = handle.read()
    else:
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        text = "onboarding = false\n\n"

    text = replace_block(text, wrap_block(fragment))
    accent = extract_accent(fragment)
    if accent:
        text = set_ui_accent(text, accent)

    with open(config_path, "w", encoding="utf-8") as handle:
        handle.write(text)


def remove_theme(config_path: str) -> None:
    if not os.path.exists(config_path):
        return
    with open(config_path, encoding="utf-8") as handle:
        text = handle.read()
    pattern = re.compile(
        re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?",
        flags=re.S,
    )
    if pattern.search(text):
        text = pattern.sub("", text)
    else:
        text = strip_theme_tables(text)
    text = strip_ui_accent(text)
    text = text.rstrip() + "\n"
    with open(config_path, "w", encoding="utf-8") as handle:
        handle.write(text)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fragment", nargs="?", help="Path to a OneQode Herdr theme fragment")
    parser.add_argument("--config", default=DEFAULT_CONFIG, help="Herdr config.toml path")
    parser.add_argument("--remove", action="store_true", help="Strip the OneQode theme block")
    args = parser.parse_args()

    if args.remove:
        remove_theme(args.config)
        return 0
    if not args.fragment:
        parser.error("fragment path is required unless --remove is set")
    if not os.path.isfile(args.fragment):
        print(f"theme fragment not found: {args.fragment}", file=sys.stderr)
        return 1
    apply_fragment(args.config, args.fragment)
    return 0


if __name__ == "__main__":
    sys.exit(main())
