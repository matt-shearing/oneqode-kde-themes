#!/usr/bin/env bash
# Install OneQode themes for Zed editor

# Source common if not already sourced
if [[ -z "${ONEQODE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
fi

install_zed() {
    info "Installing Zed themes..."

    local zed_themes_dir="$CONFIG_DIR/zed/themes"
    local zed_settings="$CONFIG_DIR/zed/settings.json"

    # Create themes directory
    mkdir -p "$zed_themes_dir"

    # Copy theme file
    if [[ -f "$ASSETS_DIR/zed/oneqode.json" ]]; then
        cp "$ASSETS_DIR/zed/oneqode.json" "$zed_themes_dir/"
        success "  Installed: oneqode.json"
    else
        warn "  Theme file not found at $ASSETS_DIR/zed/oneqode.json"
        return 1
    fi

    # Update Zed settings to use system mode with our themes
    if [[ -f "$zed_settings" ]]; then
        # Zed uses JSONC (JSON with comments), so we use sed instead of jq
        if grep -q '"theme"' "$zed_settings"; then
            # Replace existing theme block using sed
            # This handles the JSONC format with comments and trailing commas
            sed -i '/"theme":/,/^  }/c\  "theme": {\n    "mode": "system",\n    "light": "OneQode Light Glass",\n    "dark": "OneQode Night Ride"\n  }' "$zed_settings" 2>/dev/null || true
            success "  Updated Zed settings to use system theme mode"
        else
            info "  Note: Add theme settings manually to $zed_settings"
        fi
    else
        info "  Zed settings not found - theme available for manual selection"
    fi

    success "Zed themes installed"
}

uninstall_zed() {
    info "Uninstalling Zed themes..."

    local zed_themes_dir="$CONFIG_DIR/zed/themes"

    if [[ -f "$zed_themes_dir/oneqode.json" ]]; then
        rm -f "$zed_themes_dir/oneqode.json"
        success "  Removed: oneqode.json"
    fi

    success "Zed themes uninstalled"
}

# Run directly if executed as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_zed
fi
