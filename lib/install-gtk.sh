#!/usr/bin/env bash
# Install GTK3/4 CSS overrides for accent colors, selection, scrollbars,
# and libadwaita integration.
#
# Colors auto-update via KDE's color sync (kde-gtk-config writes colors.css).
# No switcher integration needed.

install_gtk() {
    info "Installing GTK3/4 CSS overrides..."

    local assets_dir="$ONEQODE_DIR/assets/gtk"

    # GTK3 overrides
    local gtk3_dir="$HOME/.config/gtk-3.0"
    if [[ -d "$gtk3_dir" ]]; then
        # Back up existing gtk.css if it's not ours
        if [[ -f "$gtk3_dir/gtk.css" ]] && ! grep -q 'OneQode GTK3' "$gtk3_dir/gtk.css" 2>/dev/null; then
            cp "$gtk3_dir/gtk.css" "$gtk3_dir/gtk.css.bak"
            debug "Backed up existing gtk-3.0/gtk.css"
        fi
        cp "$assets_dir/gtk3.css" "$gtk3_dir/gtk.css"
        success "GTK3 overrides installed to: $gtk3_dir/gtk.css"
    else
        warn "GTK3 config directory not found ($gtk3_dir)"
        warn "Run a GTK3 app first to create it, then re-run this installer"
    fi

    # GTK4 overrides
    local gtk4_dir="$HOME/.config/gtk-4.0"
    if [[ -d "$gtk4_dir" ]]; then
        if [[ -f "$gtk4_dir/gtk.css" ]] && ! grep -q 'OneQode GTK4' "$gtk4_dir/gtk.css" 2>/dev/null; then
            cp "$gtk4_dir/gtk.css" "$gtk4_dir/gtk.css.bak"
            debug "Backed up existing gtk-4.0/gtk.css"
        fi
        cp "$assets_dir/gtk4.css" "$gtk4_dir/gtk.css"
        success "GTK4 overrides installed to: $gtk4_dir/gtk.css"
    else
        warn "GTK4 config directory not found ($gtk4_dir)"
        warn "Run a GTK4 app first to create it, then re-run this installer"
    fi

    echo ""
    info "GTK overrides reference _breeze color variables from KDE's color sync."
    info "Colors auto-update when you switch themes — no restart needed for GTK3 apps."
    info "GTK4 apps may need a restart to pick up color changes."
}

uninstall_gtk() {
    info "Removing GTK3/4 CSS overrides..."

    for gtk_dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
        if [[ -f "$gtk_dir/gtk.css.bak" ]]; then
            mv "$gtk_dir/gtk.css.bak" "$gtk_dir/gtk.css"
            debug "Restored backup: $gtk_dir/gtk.css"
        elif [[ -f "$gtk_dir/gtk.css" ]]; then
            # Restore to KDE's default (just the import)
            echo "@import 'colors.css';" > "$gtk_dir/gtk.css"
            debug "Reset to default: $gtk_dir/gtk.css"
        fi
    done

    success "GTK overrides removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_gtk
fi
