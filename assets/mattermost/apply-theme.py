#!/usr/bin/env python3
"""Push the OneQode Mattermost theme for the logged-in desktop-app user.

Reads MMAUTHTOKEN from the desktop app's cookie DB and PUTs Light Glass or
Night Ride to /api/v4/users/me/preferences for every team plus the all-teams
default. All clients that share the account update live.

Exit codes:
  0  applied, or already on the requested variant
  1  transient (network, cookie snapshot) — safe to retry
  2  nothing we can do (not set up, logged out, bad asset)
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
MM_DIR = os.path.join(HOME, ".config", "Mattermost")
COOKIES = os.path.join(MM_DIR, "Cookies")
CONFIG = os.path.join(MM_DIR, "config.json")

ASSET_CANDIDATES = (
    os.path.join(HOME, ".local", "share", "oneqode", "mattermost"),
    os.path.join(HOME, "dev", "oneqode-kde-themes", "assets", "mattermost"),
    "/usr/share/oneqode-kde-themes/mattermost",
)

LIGHT_ALIASES = {"light", "day", "light-glass", "lightglass", "omarchy-oq-light-glass"}
NIGHT_ALIASES = {"night", "dark", "night-ride", "nightride", "omarchy-oq-night-ride"}

COMPARE_KEYS = (
    "sidebarBg",
    "sidebarText",
    "sidebarHeaderBg",
    "centerChannelBg",
    "centerChannelColor",
    "linkColor",
    "buttonBg",
    "mentionBg",
    "codeTheme",
)


def bail(code: int, msg: str) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def parse_variant(raw: str) -> str:
    key = raw.strip().lower()
    if key in LIGHT_ALIASES:
        return "light"
    if key in NIGHT_ALIASES:
        return "night"
    bail(2, "unknown variant %r (expected light or night)" % raw)


def find_assets(explicit: str | None) -> str:
    if explicit:
        if os.path.isfile(os.path.join(explicit, "oneqode-night-ride.json")):
            return explicit
        bail(2, "no Mattermost theme JSON in %s" % explicit)
    for directory in ASSET_CANDIDATES:
        if os.path.isfile(os.path.join(directory, "oneqode-night-ride.json")):
            return directory
    bail(2, "Mattermost assets not found")


def load_theme(assets_dir: str, variant: str) -> dict:
    fname = "oneqode-light-glass.json" if variant == "light" else "oneqode-night-ride.json"
    path = os.path.join(assets_dir, fname)
    try:
        theme = json.load(open(path))
    except Exception as exc:
        bail(2, "unreadable theme asset %s: %s" % (fname, exc))
    theme.pop("mentionBj", None)
    theme["type"] = "custom"
    return theme


def load_server() -> tuple[str, str]:
    if not (os.path.exists(COOKIES) and os.path.exists(CONFIG)):
        bail(2, "desktop app not set up")
    try:
        servers = json.load(open(CONFIG)).get("servers", [])
    except Exception as exc:
        bail(2, "unreadable config.json: %s" % exc)
    if not servers:
        bail(2, "no server configured")
    base = servers[0]["url"].rstrip("/")
    host = urllib.parse.urlsplit(base).hostname or ""
    return base, host


def read_token(host: str) -> str:
    # Snapshot rather than reading in place. Mattermost holds the cookie DB
    # open, and opening it immutable=1 tells SQLite to ignore a hot journal,
    # so a mid-write read silently returns an expired token.
    try:
        with tempfile.TemporaryDirectory() as tmp:
            snap = os.path.join(tmp, "Cookies")
            shutil.copy2(COOKIES, snap)
            for suffix in ("-journal", "-wal", "-shm"):
                src = COOKIES + suffix
                if os.path.exists(src):
                    shutil.copy2(src, snap + suffix)
            con = sqlite3.connect(snap)
            row = con.execute(
                "SELECT value FROM cookies WHERE name='MMAUTHTOKEN'"
                " AND host_key IN (?, ?) ORDER BY last_access_utc DESC LIMIT 1",
                (host, "." + host),
            ).fetchone()
            token = row[0] if row else ""
            con.close()
    except Exception as exc:
        bail(1, "cookie read failed: %s" % exc)
    if not token:
        bail(2, "logged out (no MMAUTHTOKEN for %s)" % host)
    return token


def api(base: str, token: str, method: str, path: str, data=None):
    req = urllib.request.Request(
        base + path,
        method=method,
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
        },
    )
    body = json.dumps(data).encode() if data is not None else None
    with urllib.request.urlopen(req, body, timeout=10) as resp:
        return json.loads(resp.read() or "null")


def colors_of(theme: dict) -> dict:
    return {key: theme.get(key) for key in COMPARE_KEYS}


def already_applied(prefs: list, desired: dict) -> bool:
    want = colors_of(desired)
    theme_prefs = [p for p in prefs if p.get("category") == "theme"]
    if not theme_prefs:
        return False
    for pref in theme_prefs:
        try:
            have = colors_of(json.loads(pref.get("value") or "{}"))
        except Exception:
            return False
        if have != want:
            return False
    return True


def current_swatch(prefs: list) -> str:
    for pref in prefs:
        if pref.get("category") != "theme":
            continue
        try:
            theme = json.loads(pref.get("value") or "{}")
        except Exception:
            continue
        bg = theme.get("centerChannelBg") or theme.get("sidebarBg") or "?"
        kind = theme.get("type") or "unknown"
        return "%s %s (teams=%d)" % (kind, bg, sum(1 for p in prefs if p.get("category") == "theme"))
    return "no theme preference"


def apply(variant: str, assets_dir: str, force: bool) -> str:
    theme = load_theme(assets_dir, variant)
    base, host = load_server()
    token = read_token(host)
    try:
        uid = api(base, token, "GET", "/api/v4/users/me")["id"]
        prefs = api(base, token, "GET", "/api/v4/users/me/preferences")
        if not force and already_applied(prefs, theme):
            return "already %s" % variant
        names = sorted({p["name"] for p in prefs if p["category"] == "theme"})
        if "" not in names:
            names.append("")
        value = json.dumps(theme)
        api(
            base,
            token,
            "PUT",
            "/api/v4/users/me/preferences",
            [{"user_id": uid, "category": "theme", "name": n, "value": value} for n in names],
        )
    except urllib.error.HTTPError as exc:
        bail(2 if exc.code in (401, 403) else 1, "API %s %s" % (exc.code, exc.reason))
    except Exception as exc:
        bail(1, "API call failed: %s" % exc)
    return "applied %s" % variant


def status(assets_dir: str) -> None:
    base, host = load_server()
    token = read_token(host)
    try:
        prefs = api(base, token, "GET", "/api/v4/users/me/preferences")
    except urllib.error.HTTPError as exc:
        bail(2 if exc.code in (401, 403) else 1, "API %s %s" % (exc.code, exc.reason))
    except Exception as exc:
        bail(1, "API call failed: %s" % exc)
    print("server:  %s" % base)
    print("current: %s" % current_swatch(prefs))
    for variant in ("light", "night"):
        want = colors_of(load_theme(assets_dir, variant))
        mark = "yes" if already_applied(prefs, load_theme(assets_dir, variant)) else "no"
        print("matches %s (%s): %s" % (variant, want["centerChannelBg"], mark))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "variant",
        nargs="?",
        help="light/night, or an OQ theme slug. Omit with --status.",
    )
    parser.add_argument(
        "assets_dir",
        nargs="?",
        help="directory containing oneqode-*.json (auto-detected if omitted)",
    )
    parser.add_argument("--status", action="store_true", help="print the live server theme and exit")
    parser.add_argument("--force", action="store_true", help="PUT even if the server already matches")
    args = parser.parse_args()

    assets_dir = find_assets(args.assets_dir)

    if args.status:
        status(assets_dir)
        return

    if not args.variant:
        parser.error("variant is required unless --status is set")

    variant = parse_variant(args.variant)
    print(apply(variant, assets_dir, args.force))


if __name__ == "__main__":
    main()
