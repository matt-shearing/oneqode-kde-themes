#!/usr/bin/env bash
# Install OneQode Mattermost themes (applied via the Mattermost API on theme switch)

install_mattermost() {
    info "Installing Mattermost themes..."

    if [[ ! -d "$CONFIG_DIR/Mattermost" ]]; then
        warn "Mattermost desktop app not found — skipping (themes will install once it's set up)"
        return 0
    fi

    local mm_share="$LOCAL_SHARE/oneqode/mattermost"
    mkdir -p "$mm_share"
    cp "$ASSETS_DIR/mattermost/"*.json "$mm_share/"

    success "Mattermost themes installed"
    info "Theme switches automatically with the desktop theme (via Mattermost API)"
}

uninstall_mattermost() {
    info "Removing Mattermost themes..."
    rm -rf "$LOCAL_SHARE/oneqode/mattermost"
    success "Mattermost themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_mattermost
fi
