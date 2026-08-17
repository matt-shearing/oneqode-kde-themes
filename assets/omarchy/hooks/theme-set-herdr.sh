#!/usr/bin/env bash
# After `omarchy theme set`, retint Herdr + Grok so they match the desktop.
# OQ themes get the OneQode palettes; everything else falls back to Omarchy's
# stock `terminal` theme (inherit the terminal).

set -euo pipefail

THEME=${1:-}
THEMES_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/themes
HOOKS_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks
APPLY="$THEMES_DIR/apply-theme.py"
FLIP="$HOOKS_DIR/lib/flip-grok-theme.py"

[[ -x $APPLY ]] || exit 0

pick_fragment() {
  local name
  for name in "$@"; do
    if [[ -f $THEMES_DIR/$name ]]; then
      echo "$THEMES_DIR/$name"
      return 0
    fi
  done
  return 1
}

grok_theme=groknight
case "$THEME" in
omarchy-oq-light-glass)
  fragment=$(pick_fragment oneqode-light-glass.toml omarchy-oq-light-glass.toml) || exit 0
  grok_theme=grokday
  ;;
omarchy-oq-night-ride)
  fragment=$(pick_fragment oneqode-night-ride.toml omarchy-oq-night-ride.toml) || exit 0
  grok_theme=groknight
  ;;
*)
  if [[ -f ${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme/light.mode ]]; then
    fragment=$(pick_fragment oneqode-light-glass.toml omarchy-oq-light-glass.toml) || exit 0
    grok_theme=grokday
  else
    fragment=$(pick_fragment terminal.toml) || exit 0
    grok_theme=groknight
  fi
  ;;
esac

python3 "$APPLY" "$fragment" --grok-theme "$grok_theme" || {
  echo "herdr-theme hook: apply failed" >&2
  exit 0
}

if herdr status server >/dev/null 2>&1; then
  herdr server reload-config >/dev/null 2>&1 || true
  if [[ -f $FLIP ]]; then
    # Detached: idle panes flip now, working panes flip once they settle.
    systemctl --user stop oneqode-grok-theme-flip.service >/dev/null 2>&1 || true
    systemctl --user reset-failed oneqode-grok-theme-flip.service >/dev/null 2>&1 || true
    systemd-run --user --collect --quiet \
      --unit=oneqode-grok-theme-flip \
      --setenv=GROK_THEME="$grok_theme" \
      python3 "$FLIP" >/dev/null 2>&1 || \
      GROK_THEME=$grok_theme nohup python3 "$FLIP" >/dev/null 2>&1 &
  fi
fi
