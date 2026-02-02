#!/usr/bin/env bash
# Install OneQode wallpapers

install_wallpapers() {
    info "Installing wallpapers..."

    mkdir -p "$LOCAL_SHARE/wallpapers/OneQode"
    rsync -a "$ASSETS_DIR/wallpapers/" "$LOCAL_SHARE/wallpapers/OneQode/"

    success "Wallpapers installed"
}

uninstall_wallpapers() {
    info "Removing wallpapers..."

    rm -rf "$LOCAL_SHARE/wallpapers/OneQode"

    success "Wallpapers removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_wallpapers
fi
