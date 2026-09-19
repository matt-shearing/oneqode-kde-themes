#!/usr/bin/env bash
# Night Ride (and Light Glass) want the Omarchy top bar see-through so the
# wallpaper shows through the icons. Transparency lives in shell.json, not
# in the theme palette, so turn it on when this pair is applied.
#
# Other themes are left alone. Double-click empty bar centre, or
# Style → Menu Bar → Transparency, still toggles it until the next OQ switch.
set -euo pipefail

case "${1:-}" in
omarchy-oq-night-ride|omarchy-oq-light-glass)
  ;;
*)
  exit 0
  ;;
esac

OMARCHY="${OMARCHY_PATH:-/usr/share/omarchy}/bin/omarchy"
[[ -x $OMARCHY ]] || exit 0
"$OMARCHY" bar transparent true
