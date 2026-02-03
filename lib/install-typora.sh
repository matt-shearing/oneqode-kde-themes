#!/usr/bin/env bash
# Install Typora themes

install_typora() {
    info "Installing Typora themes..."

    local typora_dir="$CONFIG_DIR/Typora/themes"
    local assets_dir="$ONEQODE_DIR/assets/typora"

    # Check if Typora themes directory exists
    if [[ ! -d "$typora_dir" ]]; then
        warn "Typora themes directory not found at $typora_dir"
        warn "Install Typora first, then re-run this installer"
        return 1
    fi

    # Install themes
    cp "$assets_dir/oneqode-night-ride.css" "$typora_dir/"
    cp "$assets_dir/oneqode-light-glass.css" "$typora_dir/"

    success "Typora themes installed"
    info "Open Typora > Themes to select OneQode Night Ride or Light Glass"
}

uninstall_typora() {
    info "Removing Typora themes..."

    local typora_dir="$CONFIG_DIR/Typora/themes"

    rm -f "$typora_dir/oneqode-night-ride.css"
    rm -f "$typora_dir/oneqode-light-glass.css"

    success "Typora themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_typora
fi
