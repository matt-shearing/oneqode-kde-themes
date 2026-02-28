#!/usr/bin/env bash
# Install Fastfetch config with OneQode logo

install_fastfetch() {
    info "Installing Fastfetch config..."

    local assets_dir="$ONEQODE_DIR/assets/fastfetch"

    # Check if fastfetch is installed
    if ! command -v fastfetch &>/dev/null; then
        warn "Fastfetch is not installed"
        warn "Install it first: pacman -S fastfetch (or yay -S fastfetch)"
        return 1
    fi

    # Install logo asset
    local logo_dir="$LOCAL_SHARE/fastfetch/assets"
    mkdir -p "$logo_dir"
    cp "$assets_dir/oneqode-knot-alpha.png" "$logo_dir/"

    # Install config (back up existing if not ours)
    local config_dir="$CONFIG_DIR/fastfetch"
    mkdir -p "$config_dir"

    if [[ -f "$config_dir/config.jsonc" ]] && ! grep -q 'oneqode-knot-alpha' "$config_dir/config.jsonc" 2>/dev/null; then
        cp "$config_dir/config.jsonc" "$config_dir/config.jsonc.bak"
        debug "Backed up existing fastfetch config"
    fi

    cp "$assets_dir/config.jsonc" "$config_dir/"

    success "Fastfetch config installed with OneQode logo"
    info "Run 'fastfetch' to see it in action"
}

uninstall_fastfetch() {
    info "Removing Fastfetch config..."

    rm -f "$LOCAL_SHARE/fastfetch/assets/oneqode-knot-alpha.png"

    # Restore backup if it exists
    if [[ -f "$CONFIG_DIR/fastfetch/config.jsonc.bak" ]]; then
        mv "$CONFIG_DIR/fastfetch/config.jsonc.bak" "$CONFIG_DIR/fastfetch/config.jsonc"
        debug "Restored backup fastfetch config"
    else
        rm -f "$CONFIG_DIR/fastfetch/config.jsonc"
    fi

    success "Fastfetch config removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_fastfetch
fi
