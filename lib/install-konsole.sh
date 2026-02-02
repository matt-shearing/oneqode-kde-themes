#!/usr/bin/env bash
# Install Konsole color schemes

install_konsole() {
    info "Installing Konsole color schemes..."

    mkdir -p "$LOCAL_SHARE/konsole"
    cp "$ASSETS_DIR/konsole/"*.colorscheme "$LOCAL_SHARE/konsole/"

    success "Konsole color schemes installed"
    info "To use: Konsole > Settings > Edit Current Profile > Appearance"
}

uninstall_konsole() {
    info "Removing Konsole color schemes..."

    rm -f "$LOCAL_SHARE/konsole/OneQodeLightGlass.colorscheme"
    rm -f "$LOCAL_SHARE/konsole/OneQodeNightRide.colorscheme"

    success "Konsole color schemes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_konsole
fi
