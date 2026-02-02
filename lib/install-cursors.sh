#!/usr/bin/env bash
# Install Bibata cursor theme

CURSOR_NAME="Bibata-Modern-Ice"
CURSOR_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Ice.tar.xz"

install_cursors() {
    info "Installing Bibata cursor theme..."

    local cursor_dir="$LOCAL_SHARE/icons"

    # Check if already installed
    if [[ -d "$cursor_dir/$CURSOR_NAME" ]]; then
        success "Bibata cursor already installed"
        return 0
    fi

    mkdir -p "$cursor_dir"

    # Download and extract
    local tmp_file
    tmp_file=$(mktemp)

    if curl -fsSL "$CURSOR_URL" -o "$tmp_file"; then
        tar -xf "$tmp_file" -C "$cursor_dir"
        rm -f "$tmp_file"
        success "Bibata cursor installed"
    else
        rm -f "$tmp_file"
        warn "Could not download Bibata cursor"
        warn "Manual install: https://github.com/ful1e5/Bibata_Cursor/releases"
        return 1
    fi
}

uninstall_cursors() {
    info "Removing Bibata cursor..."

    rm -rf "$LOCAL_SHARE/icons/$CURSOR_NAME"

    success "Bibata cursor removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_cursors
fi
