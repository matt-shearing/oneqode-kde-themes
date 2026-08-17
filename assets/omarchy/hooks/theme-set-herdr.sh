#!/usr/bin/env bash
# After `omarchy theme set`, retint Herdr + Grok so they match the desktop.
# OQ themes get the OneQode palettes; everything else falls back to Omarchy's
# stock `terminal` theme (inherit the terminal).

set -euo pipefail

THEME=${1:-}
THEMES_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/themes
APPLY="$THEMES_DIR/apply-theme.py"

[[ -x $APPLY ]] || exit 0

grok_theme=groknight
case "$THEME" in
omarchy-oq-light-glass)
  fragment=$THEMES_DIR/oneqode-light-glass.toml
  grok_theme=grokday
  ;;
omarchy-oq-night-ride)
  fragment=$THEMES_DIR/oneqode-night-ride.toml
  grok_theme=groknight
  ;;
*)
  if [[ -f ${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme/light.mode ]]; then
    fragment=$THEMES_DIR/oneqode-light-glass.toml
    grok_theme=grokday
  else
    fragment=$THEMES_DIR/terminal.toml
    grok_theme=groknight
  fi
  ;;
esac

[[ -f $fragment ]] || exit 0

python3 "$APPLY" "$fragment" --grok-theme "$grok_theme" || {
  echo "herdr-theme hook: apply failed" >&2
  exit 0
}

if herdr status server >/dev/null 2>&1; then
  herdr server reload-config >/dev/null 2>&1 || true
  GROK_THEME=$grok_theme python3 - <<'PY' || true
import json, os, subprocess

theme = os.environ["GROK_THEME"]
try:
    raw = subprocess.check_output(["herdr", "agent", "list"], text=True)
    agents = json.loads(raw).get("result", {}).get("agents", [])
except Exception:
    raise SystemExit(0)

for agent in agents:
    if agent.get("agent") != "grok":
        continue
    if agent.get("agent_status") == "working":
        continue
    pane = agent.get("pane_id")
    if not pane:
        continue
    subprocess.run(["herdr", "pane", "send-text", pane, f"/theme {theme}"], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["herdr", "pane", "send-keys", pane, "enter"], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
fi
