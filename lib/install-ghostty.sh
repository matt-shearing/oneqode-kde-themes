#!/usr/bin/env bash
# Install Ghostty themes

# Ghostty 1.1+ pairs light/dark themes and follows the desktop appearance.
# The old approach (`config-file = themes/oneqode-current` + flipping that
# symlink) never reloads the gtk-single-instance daemon, so daytime stayed
# on Night Ride until Ghostty was fully restarted.
GHOSTTY_THEME_PAIR="theme = light:oneqode-light-glass,dark:oneqode-night-ride"

ensure_ghostty_theme_pairing() {
    local ghostty_config="${1:-$CONFIG_DIR/ghostty/config}"
    mkdir -p "$(dirname "$ghostty_config")"

    if [[ ! -f "$ghostty_config" ]]; then
        printf '%s\n' \
            "# Ghostty config" \
            "# OneQode theme (follows system light/dark)" \
            "$GHOSTTY_THEME_PAIR" \
            > "$ghostty_config"
        return 0
    fi

    # The old include loads AFTER `theme =` and pins a single palette, which
    # blocks Ghostty's native light/dark switching. Always drop it.
    if grep -q 'oneqode-current' "$ghostty_config"; then
        sed -i \
            -e '/# OneQode theme/d' \
            -e '/oneqode-current/d' \
            "$ghostty_config"
    fi

    if grep -qE '^[[:space:]]*theme[[:space:]]*=[[:space:]]*(light:oneqode-light-glass,[[:space:]]*dark:oneqode-night-ride|dark:oneqode-night-ride,[[:space:]]*light:oneqode-light-glass)[[:space:]]*$' "$ghostty_config"; then
        return 0
    fi

    if grep -qE '^[[:space:]]*theme[[:space:]]*=.*oneqode' "$ghostty_config"; then
        sed -i -E 's|^[[:space:]]*theme[[:space:]]*=.*oneqode.*|'"$GHOSTTY_THEME_PAIR"'|' "$ghostty_config"
        return 0
    fi

    if grep -qE '^[[:space:]]*theme[[:space:]]*=' "$ghostty_config"; then
        # User has their own theme — don't clobber it.
        return 0
    fi

    printf '\n# OneQode theme (follows system light/dark)\n%s\n' "$GHOSTTY_THEME_PAIR" >> "$ghostty_config"
}

# Official GTK action. SIGUSR1 used to crash Ghostty on some systems, and
# new windows inherit the already-loaded config in gtk-single-instance mode.
reload_ghostty() {
    busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty \
        org.gtk.Actions Activate sava{sv} reload-config 0 0 >/dev/null 2>&1 \
        || gdbus call --session --dest com.mitchellh.ghostty \
            --object-path /com/mitchellh/ghostty \
            --method org.gtk.Actions.Activate reload-config [] {} >/dev/null 2>&1 \
        || true
}

install_ghostty() {
    info "Installing Ghostty themes..."

    local ghostty_themes="$CONFIG_DIR/ghostty/themes"
    mkdir -p "$ghostty_themes"

    cp "$ASSETS_DIR/ghostty/"* "$ghostty_themes/"

    # Keep the current-theme symlink for anyone still listing oneqode-current.
    ln -sf "oneqode-night-ride" "$ghostty_themes/oneqode-current"

    ensure_ghostty_theme_pairing "$CONFIG_DIR/ghostty/config"
    reload_ghostty

    success "Ghostty themes installed"
    info "Theme follows the desktop light/dark appearance"
}

uninstall_ghostty() {
    info "Removing Ghostty themes..."

    rm -f "$CONFIG_DIR/ghostty/themes/oneqode-light-glass"
    rm -f "$CONFIG_DIR/ghostty/themes/oneqode-night-ride"
    rm -f "$CONFIG_DIR/ghostty/themes/oneqode-current"

    if [[ -f "$CONFIG_DIR/ghostty/config" ]]; then
        sed -i \
            -e '/oneqode-current/d' \
            -e '/# OneQode theme/d' \
            -e '/^[[:space:]]*theme[[:space:]]*=.*oneqode/d' \
            "$CONFIG_DIR/ghostty/config"
    fi

    success "Ghostty themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_ghostty
fi
