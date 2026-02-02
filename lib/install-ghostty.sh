#!/usr/bin/env bash
# Install Ghostty themes

install_ghostty() {
    info "Installing Ghostty themes..."

    local ghostty_themes="$CONFIG_DIR/ghostty/themes"
    mkdir -p "$ghostty_themes"

    cp "$ASSETS_DIR/ghostty/"* "$ghostty_themes/"

    # Create initial current theme symlink
    ln -sf "oneqode-night-ride" "$ghostty_themes/oneqode-current"

    # Add include to ghostty config if not present
    local ghostty_config="$CONFIG_DIR/ghostty/config"
    local theme_include="config-file = themes/oneqode-current"

    if [[ -f "$ghostty_config" ]]; then
        if ! grep -q "oneqode-current" "$ghostty_config"; then
            echo "" >> "$ghostty_config"
            echo "# OneQode theme (switched automatically)" >> "$ghostty_config"
            echo "$theme_include" >> "$ghostty_config"
        fi
    else
        mkdir -p "$CONFIG_DIR/ghostty"
        echo "# Ghostty config" > "$ghostty_config"
        echo "$theme_include" >> "$ghostty_config"
    fi

    success "Ghostty themes installed"
    info "Theme will switch automatically with desktop theme"
}

uninstall_ghostty() {
    info "Removing Ghostty themes..."

    rm -f "$CONFIG_DIR/ghostty/themes/oneqode-light-glass"
    rm -f "$CONFIG_DIR/ghostty/themes/oneqode-night-ride"
    rm -f "$CONFIG_DIR/ghostty/themes/oneqode-current"

    # Remove config line
    if [[ -f "$CONFIG_DIR/ghostty/config" ]]; then
        sed -i '/oneqode-current/d' "$CONFIG_DIR/ghostty/config"
        sed -i '/# OneQode theme/d' "$CONFIG_DIR/ghostty/config"
    fi

    success "Ghostty themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_ghostty
fi
