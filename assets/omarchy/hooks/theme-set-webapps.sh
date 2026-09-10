#!/usr/bin/env bash
# After `omarchy theme set`, reload Chromium/Brave app windows so WhatsApp,
# Proton Mail, and Superhuman re-read prefers-color-scheme. Those sites
# cache the scheme at load; the portal bounce in gtk-theme.sh is not
# enough on its own. Ctrl+R is sent to the window without focusing it.
# Grok Bot and Mattermost are not reloaded — they have their own adapters.

set -euo pipefail

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 - <<'PY'
from __future__ import annotations

import json
import subprocess
import time

PREFIXES = (
    "chrome-web.whatsapp.com",
    "brave-web.whatsapp.com",
    "chrome-mail.proton.me",
    "brave-mail.proton.me",
    "chrome-mail.superhuman.com",
    "brave-mail.superhuman.com",
    "brave-cabkgbgkeonbpeoedbaeolhgfkempoka",
    "chrome-cabkgbgkeonbpeoedbaeolhgfkempoka",
)


def clients() -> list[dict]:
    try:
        raw = subprocess.check_output(["hyprctl", "-j", "clients"], text=True)
    except Exception:
        return []
    try:
        data = json.loads(raw)
    except Exception:
        return []
    return data if isinstance(data, list) else []


def reload(address: str) -> None:
    target = "address:" + address
    for state in ("down", "up"):
        subprocess.run(
            [
                "hyprctl",
                "dispatch",
                'hl.dsp.send_key_state({ mods = "CTRL", key = "R", state = "%s", window = "%s" })'
                % (state, target),
            ],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if state == "down":
            time.sleep(0.05)


seen: set[str] = set()
for client in clients():
    cls = client.get("class") or ""
    address = client.get("address") or ""
    if not address or address in seen:
        continue
    if not any(cls.startswith(prefix) for prefix in PREFIXES):
        continue
    seen.add(address)
    reload(address)
PY
