#!/usr/bin/env bash
# After `omarchy theme set`, push Light Glass or Night Ride to Mattermost
# via its API. The chat theme lives on the server, so every client follows.
# Failures are non-fatal: logged-out sessions are skipped, and a network
# blip is retried on the next solar-timer tick.

set -euo pipefail

THEME=${1:-}
HOOKS_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks
SHARE_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/oneqode/mattermost
REPO_DIR=$HOME/dev/oneqode-kde-themes/assets/mattermost
SYSTEM_DIR=/usr/share/oneqode-kde-themes/mattermost
LIGHT_MODE=${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme/light.mode

[[ -d ${XDG_CONFIG_HOME:-$HOME/.config}/Mattermost ]] || exit 0

case "$THEME" in
omarchy-oq-light-glass)
  variant=light
  ;;
omarchy-oq-night-ride)
  variant=night
  ;;
*)
  if [[ -f $LIGHT_MODE ]]; then
    variant=light
  else
    variant=night
  fi
  ;;
esac

apply=""
assets=""
for dir in "$SHARE_DIR" "$REPO_DIR" "$SYSTEM_DIR" "$HOOKS_DIR/lib"; do
  if [[ -z $assets && -f $dir/oneqode-night-ride.json ]]; then
    assets=$dir
  fi
  if [[ -z $apply ]]; then
    if [[ -f $dir/apply-theme.py ]]; then
      apply=$dir/apply-theme.py
    elif [[ -f $dir/apply-mattermost-theme.py ]]; then
      apply=$dir/apply-mattermost-theme.py
    fi
  fi
done

if [[ -z $apply || -z $assets ]]; then
  echo "mattermost-theme hook: apply script or JSON not found" >&2
  exit 0
fi

python3 "$apply" "$variant" "$assets" || {
  echo "mattermost-theme hook: apply failed" >&2
  exit 0
}
