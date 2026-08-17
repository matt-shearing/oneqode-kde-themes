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
import tomllib

BEGIN = "# BEGIN ONEQODE THEME"
END = "# END ONEQODE THEME"

DEFAULT_CONFIG = os.path.expanduser("~/.config/herdr/config.toml")
DEFAULT_GROK_CONFIG = os.path.expanduser("~/.grok/config.toml")


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


SIDEBAR_TITLE_TOKENS = {"workspace", "tab", "agent", "state_text"}
SIDEBAR_SUBTITLE_TOKENS = {
    "terminal_title",
    "terminal_title_stripped",
    "branch",
    "git_status",
    "pane",
}
SIDEBAR_UNSTYLED_TOKENS = {"state_icon"}
DEFAULT_SPACE_ROWS = [["state_icon", "workspace"], ["branch", "git_status"]]


def extract_sidebar_colors(fragment: str) -> tuple[str, dict[str, str]]:
    """Pull [sidebar] title/subtitle out of a fragment so Herdr never sees it."""
    pattern = re.compile(r"(?ms)^\[sidebar\]\n.*?(?=^\[|\Z)")
    match = pattern.search(fragment)
    colors: dict[str, str] = {}
    if match:
        parsed = tomllib.loads(match.group(0))
        raw = parsed.get("sidebar") or {}
        for key in ("title", "subtitle"):
            value = raw.get(key)
            if isinstance(value, str) and re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
                colors[key] = value
        fragment = pattern.sub("", fragment)
    return fragment, colors


def _token_name(item: object) -> str | None:
    if isinstance(item, str):
        return item
    if isinstance(item, dict) and isinstance(item.get("token"), str):
        return item["token"]
    return None


def _style_token(item: object, title: str, subtitle: str) -> object:
    name = _token_name(item)
    if name is None or name in SIDEBAR_UNSTYLED_TOKENS or name.startswith("$"):
        return name or item
    if name in SIDEBAR_TITLE_TOKENS:
        return {"token": name, "fg": title, "dim": False}
    if name in SIDEBAR_SUBTITLE_TOKENS:
        return {"token": name, "fg": subtitle, "dim": False}
    return {"token": name, "fg": subtitle, "dim": False}


def _format_row_item(item: object) -> str:
    if isinstance(item, str):
        return f'"{item}"'
    if isinstance(item, dict):
        token = item["token"]
        fg = item["fg"]
        dim = "true" if item.get("dim") else "false"
        return f'{{ token = "{token}", fg = "{fg}", dim = {dim} }}'
    raise TypeError(f"unsupported sidebar token: {item!r}")


def _format_rows(rows: list[list[object]]) -> str:
    lines = ["rows = ["]
    for row in rows:
        rendered = ", ".join(_format_row_item(item) for item in row)
        lines.append(f"  [{rendered}],")
    lines.append("]")
    return "\n".join(lines)


def _section_span(text: str, header: str) -> tuple[int, int] | None:
    lines = text.splitlines(True)
    start = None
    offset = 0
    start_off = 0
    parent = header[1:-1]
    for i, line in enumerate(lines):
        stripped = line.strip()
        if start is None:
            if stripped == header:
                start = i
                start_off = offset
        elif stripped.startswith("[") and stripped.endswith("]"):
            name = stripped[1:-1]
            if name != parent and not name.startswith(parent + "."):
                return start_off, offset
        offset += len(line)
    if start is None:
        return None
    return start_off, len(text)


def _replace_rows_block(section: str, rows_toml: str) -> str:
    pattern = re.compile(r"(?ms)^rows\s*=\s*\[.*?^\]\s*\n?")
    if pattern.search(section):
        return pattern.sub(rows_toml + "\n", section, count=1)
    if section.endswith("\n"):
        return section + rows_toml + "\n"
    return section + "\n" + rows_toml + "\n"


def apply_sidebar_styles(text: str, title: str, subtitle: str) -> str:
    """Restyle sidebar title/subtitle tokens so they stay readable on the theme."""
    agents_span = _section_span(text, "[ui.sidebar.agents]")
    if agents_span:
        start, end = agents_span
        section = text[start:end]
        try:
            parsed = tomllib.loads(section)
            rows = parsed["ui"]["sidebar"]["agents"]["rows"]
        except Exception:
            rows = [["state_icon", "workspace", "tab"], ["terminal_title_stripped"]]
        styled = [[_style_token(item, title, subtitle) for item in row] for row in rows]
        section = _replace_rows_block(section, _format_rows(styled))
        text = text[:start] + section + text[end:]

    spaces_span = _section_span(text, "[ui.sidebar.spaces]")
    if spaces_span:
        start, end = spaces_span
        section = text[start:end]
        try:
            parsed = tomllib.loads(section)
            rows = parsed["ui"]["sidebar"]["spaces"]["rows"]
        except Exception:
            rows = DEFAULT_SPACE_ROWS
        styled = [[_style_token(item, title, subtitle) for item in row] for row in rows]
        section = _replace_rows_block(section, _format_rows(styled))
        text = text[:start] + section + text[end:]
    else:
        styled = [[_style_token(item, title, subtitle) for item in row] for row in DEFAULT_SPACE_ROWS]
        block = "[ui.sidebar.spaces]\n" + _format_rows(styled) + "\n"
        text = text.rstrip() + "\n\n" + block
    return text


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


def set_grok_theme(theme: str, config_path: str = DEFAULT_GROK_CONFIG) -> None:
    """Set [ui].theme in Grok's config.toml without touching other keys."""
    if not theme:
        return
    if os.path.exists(config_path):
        with open(config_path, encoding="utf-8") as handle:
            text = handle.read()
    else:
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        text = "[ui]\n"

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
        text = f"{text}{suffix}\n[ui]\ntheme = \"{theme}\"\n"
    else:
        replaced = False
        for i in range(ui_idx + 1, next_section):
            if re.match(r"^theme\s*=", lines[i]):
                lines[i] = f'theme = "{theme}"\n'
                replaced = True
                break
        if not replaced:
            lines.insert(ui_idx + 1, f'theme = "{theme}"\n')
        text = "".join(lines)

    with open(config_path, "w", encoding="utf-8") as handle:
        handle.write(text)


def apply_fragment(config_path: str, fragment_path: str) -> None:
    with open(fragment_path, encoding="utf-8") as handle:
        fragment = handle.read()
    if os.path.exists(config_path):
        with open(config_path, encoding="utf-8") as handle:
            text = handle.read()
    else:
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        text = "onboarding = false\n\n"

    fragment, sidebar = extract_sidebar_colors(fragment)
    text = replace_block(text, wrap_block(fragment))
    accent = extract_accent(fragment)
    if accent:
        text = set_ui_accent(text, accent)
    if sidebar.get("title") and sidebar.get("subtitle"):
        text = apply_sidebar_styles(text, sidebar["title"], sidebar["subtitle"])

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
    parser.add_argument("--grok-config", default=DEFAULT_GROK_CONFIG, help="Grok config.toml path")
    parser.add_argument("--grok-theme", help="Also set [ui].theme in Grok's config.toml")
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
    if args.grok_theme:
        set_grok_theme(args.grok_theme, args.grok_config)
    return 0


if __name__ == "__main__":
    sys.exit(main())
