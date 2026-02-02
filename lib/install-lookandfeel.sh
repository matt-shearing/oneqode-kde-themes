#!/usr/bin/env bash
# Install OneQode look-and-feel packages

install_lookandfeel() {
    info "Installing look-and-feel packages..."

    mkdir -p "$LOCAL_SHARE/plasma/look-and-feel"
    rsync -a "$ASSETS_DIR/look-and-feel/" "$LOCAL_SHARE/plasma/look-and-feel/"

    success "Look-and-feel packages installed"
}

uninstall_lookandfeel() {
    info "Removing look-and-feel packages..."

    rm -rf "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.lightglass"
    rm -rf "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.nightride"

    success "Look-and-feel packages removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_lookandfeel
fi
