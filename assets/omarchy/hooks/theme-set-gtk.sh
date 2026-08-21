#!/usr/bin/env bash
# After `omarchy theme set`, retint GTK3/4 (Nautilus, file chooser, Evince)
# to Light Glass or Night Ride. Other Omarchy themes drop the OQ gtk.css
# so stock Adwaita shows through.

set -euo pipefail

THEME=${1:-}
THEME_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/current/theme
SHARE_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/oneqode/gtk
GTK3_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0
GTK4_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0
REPO_GTK=$HOME/dev/oneqode-kde-themes/assets/gtk

variant=""
accent=blue
gtk3_src=""
gtk4_src=""

case "$THEME" in
omarchy-oq-light-glass)
    variant=light
    accent=teal
    gtk3_src=gtk3-light-glass.css
    gtk4_src=gtk4-light-glass.css
    ;;
omarchy-oq-night-ride)
    variant=dark
    accent=pink
    gtk3_src=gtk3-night-ride.css
    gtk4_src=gtk4-night-ride.css
    ;;
*)
    variant=""
    ;;
esac

remove_ours() {
    local file=$1
    [[ -f $file ]] || return 0
    grep -q 'OneQode GTK' "$file" 2>/dev/null || return 0
    if [[ -f $file.bak ]]; then
        mv "$file.bak" "$file"
    else
        rm -f "$file"
    fi
}

backup_foreign() {
    local file=$1
    [[ -f $file ]] || return 0
    grep -q 'OneQode GTK' "$file" 2>/dev/null && return 0
    cp "$file" "$file.bak"
}

if [[ -z $variant ]]; then
    remove_ours "$GTK3_DIR/gtk.css"
    remove_ours "$GTK4_DIR/gtk.css"
    if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
        gsettings set org.gnome.desktop.interface accent-color blue >/dev/null 2>&1 || true
    fi
    exit 0
fi

src_dir=""
if [[ -f $THEME_DIR/gtk-4.css && -f $THEME_DIR/gtk-3.css ]]; then
    src_dir=$THEME_DIR
    gtk3_src=gtk-3.css
    gtk4_src=gtk-4.css
else
    for dir in "$SHARE_DIR" "$REPO_GTK"; do
        if [[ -f $dir/$gtk4_src && -f $dir/$gtk3_src ]]; then
            src_dir=$dir
            break
        fi
    done
fi

if [[ -z $src_dir ]]; then
    echo "gtk-theme hook: CSS not found for $THEME" >&2
    exit 0
fi

mkdir -p "$GTK3_DIR" "$GTK4_DIR"
backup_foreign "$GTK3_DIR/gtk.css"
backup_foreign "$GTK4_DIR/gtk.css"
cp "$src_dir/$gtk3_src" "$GTK3_DIR/gtk.css"
cp "$src_dir/$gtk4_src" "$GTK4_DIR/gtk.css"

if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    gsettings set org.gnome.desktop.interface accent-color "$accent" >/dev/null 2>&1 || true
fi

if pgrep -u "$UID" -x nautilus >/dev/null 2>&1; then
    nautilus -q >/dev/null 2>&1 || true
fi
systemctl --user try-restart xdg-desktop-portal-gtk.service >/dev/null 2>&1 || true
