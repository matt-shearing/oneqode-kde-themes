#!/usr/bin/env bash
# Install OneQode Light Glass / Night Ride as Omarchy desktop themes,
# the solar auto-switcher, Framework keyboard control, and the bar applet.

OMARCHY_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
OMARCHY_THEMES="$OMARCHY_CONFIG/themes"
OMARCHY_HOOKS="$OMARCHY_CONFIG/hooks"
OMARCHY_PLUGINS="$OMARCHY_CONFIG/plugins"

install_omarchy() {
    info "Installing Omarchy desktop themes..."

    if ! command -v omarchy >/dev/null || [[ ! -d $OMARCHY_CONFIG ]]; then
        warn "Omarchy not found — skipping desktop theme"
        return 0
    fi

    local src dest variant
    for variant in omarchy-oq-light-glass omarchy-oq-night-ride; do
        src="$ASSETS_DIR/omarchy/themes/$variant"
        dest="$OMARCHY_THEMES/$variant"
        mkdir -p "$dest/backgrounds"
        cp "$src/colors.toml" "$src/icons.theme" "$dest/"
        if [[ -f $src/light.mode ]]; then
            cp "$src/light.mode" "$dest/"
        fi
        if [[ -f $src/keyboard.rgb ]]; then
            cp "$src/keyboard.rgb" "$dest/"
        fi
        if [[ $variant == *light-glass* ]]; then
            cp "$ASSETS_DIR/wallpapers/OneQode-Light-Glass.jpg" "$dest/backgrounds/"
        else
            cp "$ASSETS_DIR/wallpapers/OneQode-Night-Ride.jpg" "$dest/backgrounds/"
        fi
    done

    install -Dm755 "$ONEQODE_DIR/switcher/omarchy-oq-auto-theme" \
        "$LOCAL_BIN/omarchy-oq-auto-theme"
    install -Dm755 "$ASSETS_DIR/omarchy/keyboard/oneqode-control" \
        "$LOCAL_BIN/oneqode-control"

    mkdir -p "$SYSTEMD_USER_DIR"
    cp "$ASSETS_DIR/omarchy/omarchy-oq-auto-theme.service" "$SYSTEMD_USER_DIR/"
    cp "$ASSETS_DIR/omarchy/omarchy-oq-auto-theme.timer" "$SYSTEMD_USER_DIR/"
    systemctl --user daemon-reload
    systemctl --user enable --now omarchy-oq-auto-theme.timer >/dev/null

    mkdir -p "$OMARCHY_HOOKS/theme-set.d" "$OMARCHY_HOOKS/post-boot.d"
    install -Dm755 "$ASSETS_DIR/omarchy/hooks/theme-set-herdr.sh" \
        "$OMARCHY_HOOKS/theme-set.d/herdr-theme.sh"
    install -Dm755 "$ASSETS_DIR/omarchy/hooks/post-boot-auto-theme.sh" \
        "$OMARCHY_HOOKS/post-boot.d/oq-auto-theme.sh"
    install -Dm755 "$ASSETS_DIR/omarchy/hooks/framework-keyboard-heat.sh" \
        "$OMARCHY_HOOKS/theme-set.d/framework-keyboard-heat.sh"

    mkdir -p "$CONFIG_DIR/oneqode"
    if [[ ! -f $CONFIG_DIR/oneqode/oneqode-theme-switcher.conf ]]; then
        cp "$ONEQODE_DIR/switcher/oneqode-theme-switcher.conf" \
            "$CONFIG_DIR/oneqode/oneqode-theme-switcher.conf"
    fi
    if [[ ! -f $CONFIG_DIR/oneqode/keyboard.conf ]]; then
        cp "$ASSETS_DIR/omarchy/keyboard/keyboard.conf" \
            "$CONFIG_DIR/oneqode/keyboard.conf"
    fi

    mkdir -p "$OMARCHY_PLUGINS/oneqode.control"
    cp -a "$ASSETS_DIR/omarchy/plugin/oneqode.control/." "$OMARCHY_PLUGINS/oneqode.control/"
    omarchy plugin validate "$OMARCHY_PLUGINS/oneqode.control" >/dev/null 2>&1 || \
        warn "oneqode.control plugin validate reported issues"
    omarchy bar put oneqode.control --section right --before omarchy.tray >/dev/null 2>&1 || \
        omarchy bar put oneqode.control --section right >/dev/null 2>&1 || true

    oneqode-control apply >/dev/null 2>&1 || true

    success "Omarchy themes, keyboard control, and bar applet installed"
    info "Solar switcher: omarchy-oq-auto-theme --status"
    info "Keyboard:       oneqode-control status"
}

uninstall_omarchy() {
    info "Removing Omarchy OneQode themes..."

    systemctl --user disable --now omarchy-oq-auto-theme.timer >/dev/null 2>&1 || true
    rm -f "$SYSTEMD_USER_DIR/omarchy-oq-auto-theme.service" \
          "$SYSTEMD_USER_DIR/omarchy-oq-auto-theme.timer"
    systemctl --user daemon-reload >/dev/null 2>&1 || true

    rm -f "$LOCAL_BIN/omarchy-oq-auto-theme" \
          "$LOCAL_BIN/oneqode-control"
    rm -f "$OMARCHY_HOOKS/theme-set.d/herdr-theme.sh" \
          "$OMARCHY_HOOKS/theme-set.d/framework-keyboard-heat.sh" \
          "$OMARCHY_HOOKS/post-boot.d/oq-auto-theme.sh"
    rm -rf "$OMARCHY_THEMES/omarchy-oq-light-glass" \
           "$OMARCHY_THEMES/omarchy-oq-night-ride" \
           "$OMARCHY_PLUGINS/oneqode.control"

    success "Omarchy OneQode themes removed"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_omarchy
fi
