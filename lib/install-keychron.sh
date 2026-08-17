#!/usr/bin/env bash
# Install OneQode Keychron RGB helper (Launcher HID + day/night hook)

install_keychron() {
    info "Installing Keychron RGB helper..."

    local share="$LOCAL_SHARE/oneqode/keychron"
    mkdir -p "$share" "$LOCAL_BIN"
    cp "$ASSETS_DIR/keychron/oneqode-keychron" "$share/"
    cp "$ASSETS_DIR/keychron/99-keychron.rules" "$share/"
    chmod +x "$share/oneqode-keychron"
    ln -sfn "$share/oneqode-keychron" "$LOCAL_BIN/oneqode-keychron"

    # Q14-only rules (08e0) do not cover the Ultra-Link 8K dongle (d028).
    if [[ ! -f /etc/udev/rules.d/99-keychron.rules ]] \
            && ! grep -qE 'idProduct}=="d028"|idVendor}=="3434".*MODE' /etc/udev/rules.d/*keychron* 2>/dev/null; then
        warn "hidraw is still root-only — Keychron Launcher and this helper cannot open the dongle."
        echo ""
        echo "  Run once (your password):"
        echo "    sudo cp $share/99-keychron.rules /etc/udev/rules.d/"
        echo "    sudo udevadm control --reload-rules"
        echo "    sudo udevadm trigger --subsystem-match=hidraw"
        echo ""
        echo "  Then unplug/replug the Ultra-Link 8K dongle (or reboot)."
    else
        success "  udev rule already present"
    fi

    success "Keychron helper installed (oneqode-keychron)"
    info "After udev: oneqode-keychron status && oneqode-keychron day"
}

uninstall_keychron() {
    info "Removing Keychron RGB helper..."
    rm -f "$LOCAL_BIN/oneqode-keychron"
    rm -rf "$LOCAL_SHARE/oneqode/keychron"
    success "Keychron helper removed (udev rule left in place — remove /etc/udev/rules.d/99-keychron.rules yourself if you want)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_keychron
fi
