#!/usr/bin/env bash
# Install OneQode color schemes

install_colors() {
    info "Installing color schemes..."

    mkdir -p "$LOCAL_SHARE/color-schemes"
    rsync -a "$ASSETS_DIR/color-schemes/" "$LOCAL_SHARE/color-schemes/"

    success "Color schemes installed"
}

uninstall_colors() {
    info "Removing color schemes..."

    rm -f "$LOCAL_SHARE/color-schemes/OneQodeLightGlass.colors"
    rm -f "$LOCAL_SHARE/color-schemes/OneQodeNightRide.colors"

    success "Color schemes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_colors
fi
