#!/usr/bin/env bash
# Install OneQode fastfetch config (OQ ASCII logo, theme-aware)

install_fastfetch() {
    info "Installing fastfetch config..."

    local ff_dir="$CONFIG_DIR/fastfetch"
    mkdir -p "$ff_dir"

    # Back up a pre-existing (non-OneQode) config the first time we touch it
    if [[ -f "$ff_dir/config.jsonc" && ! -L "$ff_dir/config.jsonc" \
          && ! -f "$ff_dir/config.jsonc.pre-oneqode" ]]; then
        cp "$ff_dir/config.jsonc" "$ff_dir/config.jsonc.pre-oneqode"
    fi

    cp "$ASSETS_DIR/fastfetch/oneqode.txt" "$ff_dir/oneqode.txt"
    cp "$ASSETS_DIR/fastfetch/config-night-ride.jsonc" "$ff_dir/config-night-ride.jsonc"
    cp "$ASSETS_DIR/fastfetch/config-light-glass.jsonc" "$ff_dir/config-light-glass.jsonc"

    # fastfetch reads config.jsonc — symlink it to the active variant (default: night ride)
    ln -sf "config-night-ride.jsonc" "$ff_dir/config.jsonc"

    success "fastfetch config installed (OQ logo, theme-aware)"
    info "Logo + colors switch with the desktop theme"
}

uninstall_fastfetch() {
    info "Removing fastfetch config..."

    local ff_dir="$CONFIG_DIR/fastfetch"
    rm -f "$ff_dir/oneqode.txt" \
          "$ff_dir/config-night-ride.jsonc" \
          "$ff_dir/config-light-glass.jsonc"

    if [[ -L "$ff_dir/config.jsonc" ]]; then
        rm -f "$ff_dir/config.jsonc"
        # Restore a backed-up config if we had one
        [[ -f "$ff_dir/config.jsonc.pre-oneqode" ]] && \
            mv "$ff_dir/config.jsonc.pre-oneqode" "$ff_dir/config.jsonc"
    fi

    success "fastfetch config removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_fastfetch
fi
