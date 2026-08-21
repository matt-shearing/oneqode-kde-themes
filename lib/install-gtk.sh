#!/usr/bin/env bash
# Install GTK3/4 CSS for OneQode Light Glass / Night Ride.
#
# Palettes are hardcoded (no KDE Breeze variables) so this works on both
# Plasma and Omarchy. The KDE switcher and the Omarchy theme-set hook
# swap the active variant.

apply_gtk_theme() {
    local variant="${1:-}"
    local assets_dir="${2:-${ASSETS_DIR:-$ONEQODE_DIR/assets}/gtk}"
    local share_dir="${XDG_DATA_HOME:-$HOME/.local/share}/oneqode/gtk"
    local gtk3_dir="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
    local gtk4_dir="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
    local gtk3_src gtk4_src accent_name

    case "$variant" in
        light|light-glass|day|org.oneqode.lightglass|omarchy-oq-light-glass)
            gtk3_src="gtk3-light-glass.css"
            gtk4_src="gtk4-light-glass.css"
            accent_name=teal
            ;;
        dark|night|night-ride|org.oneqode.nightride|omarchy-oq-night-ride)
            gtk3_src="gtk3-night-ride.css"
            gtk4_src="gtk4-night-ride.css"
            accent_name=pink
            ;;
        clear|none|off)
            _remove_oq_gtk "$gtk3_dir" "$gtk4_dir"
            _set_gnome_accent blue
            return 0
            ;;
        *)
            error "Unknown GTK variant: $variant"
            return 1
            ;;
    esac

    # Prefer the files this installer published, then the repo checkout.
    local src_dir=""
    for dir in "$share_dir" "$assets_dir"; do
        if [[ -f $dir/$gtk4_src && -f $dir/$gtk3_src ]]; then
            src_dir=$dir
            break
        fi
    done
    if [[ -z $src_dir ]]; then
        error "GTK CSS not found ($gtk4_src / $gtk3_src)"
        return 1
    fi

    mkdir -p "$gtk3_dir" "$gtk4_dir"

    _backup_foreign_gtk "$gtk3_dir/gtk.css"
    _backup_foreign_gtk "$gtk4_dir/gtk.css"

    cp "$src_dir/$gtk3_src" "$gtk3_dir/gtk.css"
    cp "$src_dir/$gtk4_src" "$gtk4_dir/gtk.css"

    _set_gnome_accent "$accent_name"
    _reload_gtk_apps
}

_backup_foreign_gtk() {
    local file=$1
    [[ -f $file ]] || return 0
    grep -q 'OneQode GTK' "$file" 2>/dev/null && return 0
    cp "$file" "$file.bak"
}

_remove_oq_gtk() {
    local gtk3_dir=$1 gtk4_dir=$2 file
    for file in "$gtk3_dir/gtk.css" "$gtk4_dir/gtk.css"; do
        [[ -f $file ]] || continue
        grep -q 'OneQode GTK' "$file" 2>/dev/null || continue
        if [[ -f $file.bak ]]; then
            mv "$file.bak" "$file"
        else
            rm -f "$file"
        fi
    done
}

_set_gnome_accent() {
    local name=$1
    [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || return 0
    gsettings set org.gnome.desktop.interface accent-color "$name" >/dev/null 2>&1 || true
}

_reload_gtk_apps() {
    # libadwaita does not live-reload gtk.css. Quit Files so the next
    # Super+Shift+F opens the new palette. Don't relaunch it.
    if pgrep -u "$UID" -x nautilus >/dev/null 2>&1; then
        nautilus -q >/dev/null 2>&1 || true
    fi
    systemctl --user try-restart xdg-desktop-portal-gtk.service >/dev/null 2>&1 || true
}

gtk_variant_from_desktop() {
    local name scheme theme_file
    theme_file="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme.name"
    if [[ -f $theme_file ]]; then
        name=$(tr -d '[:space:]' <"$theme_file")
        case "$name" in
            *light-glass*|*lightglass*) echo light; return ;;
            *night-ride*|*nightride*) echo dark; return ;;
        esac
        if [[ -f ${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme/light.mode ]]; then
            echo light
        else
            echo dark
        fi
        return
    fi
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
    if [[ $scheme == *prefer-light* ]]; then
        echo light
    else
        echo dark
    fi
}

install_gtk() {
    info "Installing GTK3/4 OneQode palettes..."

    local assets_dir="$ONEQODE_DIR/assets/gtk"
    local share_dir="${XDG_DATA_HOME:-$HOME/.local/share}/oneqode/gtk"

    mkdir -p "$share_dir"
    cp "$assets_dir"/gtk3-light-glass.css \
       "$assets_dir"/gtk3-night-ride.css \
       "$assets_dir"/gtk4-light-glass.css \
       "$assets_dir"/gtk4-night-ride.css \
       "$share_dir/"

    local variant
    variant=$(gtk_variant_from_desktop)
    apply_gtk_theme "$variant" "$assets_dir"

    success "GTK3/4 overrides installed ($variant)"
    info "GTK4 / libadwaita apps (Nautilus) pick this up on the next launch."
}

uninstall_gtk() {
    info "Removing GTK3/4 CSS overrides..."
    apply_gtk_theme clear
    rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/oneqode/gtk"
    success "GTK overrides removed"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_gtk
fi
