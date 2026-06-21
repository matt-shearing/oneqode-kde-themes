#!/usr/bin/env bash
# WPS Office (Writer/Spreadsheets/Presentation) day/night integration.
#
# WPS Office for Linux (11.1.x) actively resists custom theming: it ships its
# chrome as compiled bitmap resources and runs a native integrity check that
# DISCARDS any non-factory skin on the next launch (custom skins render once
# then revert to light). So instead of shipping a custom skin, we drive WPS's
# own built-in skins, which pass the integrity check and persist:
#
#   night -> 2018white_dark  ("Clear (Dark Beta)" — full dark charcoal chrome)
#   day   -> 2018white       ("Clear"            — the stock light skin)
#
# The active skin is recorded in two places that we keep in sync:
#   ~/.local/share/Kingsoft/office6/skinsv2/default/histroy.ini   (lastSkin)
#   ~/.local/share/Kingsoft/office6/data/skincenter/localstorage.db (isActive)
#
# WPS rewrites these on exit, so a switch only "takes" while WPS is CLOSED; if
# WPS is running when the theme switches, the new skin applies on its next
# launch. (A true OneQode "navy" skin is possible but needs root to patch the
# system skin files + recolour bitmaps — see assets/wps/build-skin.py.)

WPS_SKIN_DAY="2018white"
WPS_SKIN_NIGHT="2018white_dark"
WPS_SKIN_DIR_DAY="/usr/lib/office6/skins/2018white"          # internal (no folder)
WPS_SKIN_DIR_NIGHT="/usr/lib/office6/skins/2018white_dark"

_wps_share() { echo "${XDG_DATA_HOME:-$HOME/.local/share}/Kingsoft/office6"; }
_wps_histroy() { echo "$(_wps_share)/skinsv2/default/histroy.ini"; }
_wps_skindb() { echo "$(_wps_share)/data/skincenter/localstorage.db"; }

# Is any WPS app currently running? (skin writes are futile while it is)
wps_is_running() {
    pgrep -x wps >/dev/null 2>&1 || pgrep -x et >/dev/null 2>&1 || \
        pgrep -x wpp >/dev/null 2>&1 || pgrep -x wpspdf >/dev/null 2>&1
}

# Flip the active localstorage isActive flag to the chosen built-in skin.
_wps_set_db_active() {
    local skin_id="$1" db
    db="$(_wps_skindb)"
    [[ -f "$db" ]] || return 0
    command -v sqlite3 >/dev/null 2>&1 || return 0
    command -v python3 >/dev/null 2>&1 || return 0
    WPS_TARGET="$skin_id" python3 - "$db" <<'PY' 2>/dev/null || true
import os, sys, sqlite3, json
db, target = sys.argv[1], os.environ["WPS_TARGET"]
con = sqlite3.connect(db); cur = con.cursor()
for (key,) in cur.execute("SELECT key FROM localstorage_hex_v0 WHERE key LIKE 'SKIN_%'").fetchall():
    try:
        d = json.loads(bytes.fromhex(cur.execute(
            "SELECT value FROM localstorage_hex_v0 WHERE key=?", (key,)).fetchone()[0]).decode())
    except Exception:
        continue
    active = (key == "SKIN_" + target)
    d["isActive"] = active
    d["status"] = "load" if active else "unload"
    cur.execute("UPDATE localstorage_hex_v0 SET value=? WHERE key=?",
                (json.dumps(d, ensure_ascii=False).encode().hex(), key))
con.commit(); con.close()
PY
}

# Apply the WPS skin for a light/dark theme. $1 = "true" for light, else dark.
wps_apply_skin() {
    local is_light="$1" skin_id skin_dir hist
    if [[ "$is_light" == "true" ]]; then
        skin_id="$WPS_SKIN_DAY";   skin_dir="$WPS_SKIN_DIR_DAY"
    else
        skin_id="$WPS_SKIN_NIGHT"; skin_dir="$WPS_SKIN_DIR_NIGHT"
    fi

    hist="$(_wps_histroy)"
    [[ -d "$(dirname "$hist")" ]] || return 0   # WPS not installed/initialised

    cat > "$hist" <<EOF
[skinPathPool]
$skin_id=$skin_dir

[wpsoffice]
history=$skin_id
lastSkin=$skin_id
EOF
    _wps_set_db_active "$skin_id"
}

install_wps() {
    info "Configuring WPS Office day/night skins..."
    if [[ ! -d "$(_wps_share)" ]]; then
        warn "WPS Office not found (no ~/.local/share/Kingsoft). Launch WPS once, then re-run."
        return 1
    fi
    if [[ ! -d "$WPS_SKIN_DIR_NIGHT" ]]; then
        warn "Built-in dark skin missing at $WPS_SKIN_DIR_NIGHT — is this WPS 11.1.x?"
        return 1
    fi
    command -v sqlite3 >/dev/null 2>&1 || warn "sqlite3 not found; skin selection may not persist (install sqlite)."
    success "WPS Office integration ready (driven by the theme switcher)."
    info "Note: WPS must be closed for a switch to take effect; otherwise it applies on next launch."
}

uninstall_wps() {
    info "Reverting WPS Office to the stock light skin..."
    wps_apply_skin "true"
    success "WPS Office reset to light (Clear)."
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_wps
fi
