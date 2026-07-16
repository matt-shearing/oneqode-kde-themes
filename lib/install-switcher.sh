#!/usr/bin/env bash
# Install theme switcher and systemd timer

install_switcher() {
    info "Installing theme switcher..."

    local switcher_dir="$ONEQODE_DIR/switcher"
    local icons_dir="$ONEQODE_DIR/assets/icons"

    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LOCAL_STATE/oneqode"
    mkdir -p "$CONFIG_DIR/oneqode"
    mkdir -p "$SYSTEMD_USER"
    mkdir -p "$LOCAL_SHARE/oneqode/icons"
    mkdir -p "$CONFIG_DIR/autostart"

    # Install scripts (symlink oneqode so it can find its lib folder)
    ln -sf "$ONEQODE_DIR/oneqode" "$LOCAL_BIN/oneqode"
    install -m 755 "$switcher_dir/oneqode-theme-switch" "$LOCAL_BIN/"
    install -m 755 "$switcher_dir/oneqode-theme-watcher" "$LOCAL_BIN/"

    # Install config if not exists
    if [[ ! -f "$CONFIG_DIR/oneqode/oneqode-theme-switcher.conf" ]]; then
        cp "$switcher_dir/oneqode-theme-switcher.conf" "$CONFIG_DIR/oneqode/"
    fi

    # Install systemd units
    cp "$switcher_dir/oneqode-theme-switcher.service" "$SYSTEMD_USER/"
    cp "$switcher_dir/oneqode-theme-switcher.timer" "$SYSTEMD_USER/"
    cp "$switcher_dir/oneqode-theme-watcher.service" "$SYSTEMD_USER/"

    # Install tray applet
    install -m 755 "$switcher_dir/oneqode-tray.py" "$LOCAL_SHARE/oneqode/"
    cp "$icons_dir/oneqode-light.svg" "$LOCAL_SHARE/oneqode/icons/"
    cp "$icons_dir/oneqode-dark.svg" "$LOCAL_SHARE/oneqode/icons/"
    cp "$switcher_dir/oneqode-tray.desktop" "$CONFIG_DIR/autostart/"

    success "Theme switcher installed"
}

enable_switcher() {
    info "Enabling theme switcher timer..."

    systemctl --user daemon-reload
    systemctl --user enable --now oneqode-theme-switcher.timer
    systemctl --user enable --now oneqode-theme-watcher.service

    # Force a clean re-arm. `enable --now` on an already-enabled timer will not
    # re-compute its next trigger if it was left in a stale/elapsed state
    # (Trigger: n/a) by a prior daemon-reload — a restart guarantees a fresh one.
    systemctl --user restart oneqode-theme-switcher.timer

    success "Timer and watcher enabled"
}

disable_switcher() {
    info "Disabling theme switcher timer..."

    systemctl --user disable --now oneqode-theme-switcher.timer 2>/dev/null || true
    systemctl --user disable --now oneqode-theme-watcher.service 2>/dev/null || true

    success "Timer and watcher disabled"
}

uninstall_switcher() {
    info "Removing theme switcher..."

    disable_switcher

    # Kill tray applet if running
    pkill -f "oneqode-tray.py" 2>/dev/null || true

    rm -f "$LOCAL_BIN/oneqode"
    rm -f "$LOCAL_BIN/oneqode-theme-switch"
    rm -f "$LOCAL_BIN/oneqode-theme-watcher"
    rm -f "$SYSTEMD_USER/oneqode-theme-switcher.service"
    rm -f "$SYSTEMD_USER/oneqode-theme-switcher.timer"
    rm -f "$SYSTEMD_USER/oneqode-theme-watcher.service"
    rm -rf "$LOCAL_STATE/oneqode"
    rm -rf "$LOCAL_SHARE/oneqode"
    rm -f "$CONFIG_DIR/autostart/oneqode-tray.desktop"

    systemctl --user daemon-reload

    success "Theme switcher removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_switcher
    enable_switcher
fi
