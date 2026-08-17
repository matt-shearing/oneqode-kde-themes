#!/usr/bin/env bash
# Install OneQode Herdr themes (Light Glass + Night Ride) and wire auto-switch

herdr_theme_dirs() {
    echo "$CONFIG_DIR/herdr/themes"
    echo "$LOCAL_SHARE/oneqode/herdr"
}

find_herdr_apply() {
    local dir
    for dir in \
        "$CONFIG_DIR/herdr/themes" \
        "$LOCAL_SHARE/oneqode/herdr" \
        "$ASSETS_DIR/herdr" \
        "/usr/share/oneqode-kde-themes/herdr"
    do
        if [[ -f "$dir/apply-theme.py" ]]; then
            echo "$dir/apply-theme.py"
            return 0
        fi
    done
    return 1
}

find_herdr_fragment() {
    local name="$1"
    local dir
    for dir in \
        "$CONFIG_DIR/herdr/themes" \
        "$LOCAL_SHARE/oneqode/herdr" \
        "$ASSETS_DIR/herdr" \
        "/usr/share/oneqode-kde-themes/herdr"
    do
        if [[ -f "$dir/$name" ]]; then
            echo "$dir/$name"
            return 0
        fi
    done
    return 1
}

apply_herdr_theme_file() {
    local fragment="$1"
    local apply
    apply=$(find_herdr_apply) || return 1
    python3 "$apply" --config "$CONFIG_DIR/herdr/config.toml" "$fragment"
}

reload_herdr() {
    command -v herdr &>/dev/null || return 0
    herdr server reload-config >/dev/null 2>&1 || true
}

apply_herdr_variant() {
    local is_light="$1"
    local name
    if [[ "$is_light" == "true" ]]; then
        name="oneqode-light-glass.toml"
    else
        name="oneqode-night-ride.toml"
    fi

    local fragment
    fragment=$(find_herdr_fragment "$name") || return 1
    apply_herdr_theme_file "$fragment"
    reload_herdr
}

install_herdr() {
    info "Installing Herdr themes..."

    if ! command -v herdr &>/dev/null && [[ ! -d "$CONFIG_DIR/herdr" ]]; then
        warn "Herdr not found — skipping (themes will install once herdr is set up)"
        return 0
    fi

    local dest
    for dest in $(herdr_theme_dirs); do
        mkdir -p "$dest"
        cp "$ASSETS_DIR/herdr/"*.toml "$dest/"
        cp "$ASSETS_DIR/herdr/apply-theme.py" "$dest/"
        chmod +x "$dest/apply-theme.py"
    done

    local is_light="true"
    local lnf
    lnf=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null || true)
    if [[ "$lnf" == *"nightride"* ]]; then
        is_light="false"
    fi

    apply_herdr_variant "$is_light" || {
        warn "Failed to write Herdr theme into config.toml"
        return 0
    }

    success "Herdr themes installed"
    info "Theme switches automatically with the desktop theme"
}

uninstall_herdr() {
    info "Removing Herdr themes..."

    local apply
    if apply=$(find_herdr_apply); then
        python3 "$apply" --remove --config "$CONFIG_DIR/herdr/config.toml" 2>/dev/null || true
        reload_herdr
    fi

    rm -f "$CONFIG_DIR/herdr/themes/oneqode-light-glass.toml" \
          "$CONFIG_DIR/herdr/themes/oneqode-night-ride.toml" \
          "$CONFIG_DIR/herdr/themes/apply-theme.py"
    rm -rf "$LOCAL_SHARE/oneqode/herdr"

    success "Herdr themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_herdr
fi
