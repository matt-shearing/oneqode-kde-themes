#!/usr/bin/env python3
"""Push /theme grokday|groknight into live Herdr Grok panes.

Grok does not hot-reload [ui].theme from config.toml. Idle/done panes
get the slash command immediately. Working panes are retried until they
settle so we do not type into an in-flight prompt.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time


def list_grok() -> list[dict]:
    try:
        raw = subprocess.check_output(["herdr", "agent", "list"], text=True)
        agents = json.loads(raw).get("result", {}).get("agents", [])
    except Exception:
        return []
    return [a for a in agents if a.get("agent") == "grok" and a.get("pane_id")]


def flip(pane: str, theme: str) -> None:
    subprocess.run(
        ["herdr", "pane", "send-text", pane, f"/theme {theme}"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(
        ["herdr", "pane", "send-keys", pane, "enter"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> int:
    theme = os.environ.get("GROK_THEME") or (sys.argv[1] if len(sys.argv) > 1 else "")
    if theme not in {"grokday", "groknight"}:
        return 0

    pending: set[str] = set()
    for agent in list_grok():
        pane = agent["pane_id"]
        if agent.get("agent_status") == "working":
            pending.add(pane)
        else:
            flip(pane, theme)

    deadline = time.time() + 180
    while pending and time.time() < deadline:
        time.sleep(2)
        live = {a["pane_id"]: a.get("agent_status") for a in list_grok()}
        for pane in list(pending):
            status = live.get(pane)
            if status is None:
                pending.discard(pane)
            elif status != "working":
                flip(pane, theme)
                pending.discard(pane)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
