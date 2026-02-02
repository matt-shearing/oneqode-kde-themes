#!/usr/bin/env bash
# Configure SDDM login screen (requires root)

install_sddm() {
    info "Configuring SDDM login screen..."

    local sddm_conf_dir="/etc/sddm.conf.d"
    local sddm_theme_dir="/usr/share/sddm/themes/breeze"
    local wallpaper_dir="/usr/share/wallpapers/OneQode"

    # Check if we need sudo
    if [[ ! -w "/etc" ]]; then
        warn "SDDM configuration requires root privileges"
        echo ""
        read -rp "Run with sudo? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            warn "Skipping SDDM configuration"
            show_sddm_manual_instructions
            return 0
        fi

        # Run with sudo
        sudo mkdir -p "$wallpaper_dir"
        sudo cp "$ASSETS_DIR/wallpapers/"*.jpg "$wallpaper_dir/"
        sudo mkdir -p "$sddm_conf_dir"
        sudo cp "$ONEQODE_DIR/sddm/10-oneqode.conf" "$sddm_conf_dir/"

        if [[ -d "$sddm_theme_dir" ]]; then
            sudo cp "$ONEQODE_DIR/sddm/theme.conf.user.light" "$sddm_theme_dir/theme.conf.user"
        fi
    else
        # Already have write access (running as root somehow)
        mkdir -p "$wallpaper_dir"
        cp "$ASSETS_DIR/wallpapers/"*.jpg "$wallpaper_dir/"
        mkdir -p "$sddm_conf_dir"
        cp "$ONEQODE_DIR/sddm/10-oneqode.conf" "$sddm_conf_dir/"

        if [[ -d "$sddm_theme_dir" ]]; then
            cp "$ONEQODE_DIR/sddm/theme.conf.user.light" "$sddm_theme_dir/theme.conf.user"
        fi
    fi

    success "SDDM configured with OneQode background"
}

show_sddm_manual_instructions() {
    echo ""
    echo "To configure SDDM manually, run:"
    echo ""
    echo "  sudo mkdir -p /usr/share/wallpapers/OneQode"
    echo "  sudo cp $ASSETS_DIR/wallpapers/*.jpg /usr/share/wallpapers/OneQode/"
    echo "  sudo mkdir -p /etc/sddm.conf.d"
    echo "  sudo cp $ONEQODE_DIR/sddm/10-oneqode.conf /etc/sddm.conf.d/"
    echo "  sudo cp $ONEQODE_DIR/sddm/theme.conf.user.light /usr/share/sddm/themes/breeze/theme.conf.user"
    echo ""
}

uninstall_sddm() {
    info "Removing SDDM configuration..."

    if [[ ! -w "/etc" ]]; then
        warn "Requires root privileges"
        read -rp "Run with sudo? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            warn "Skipping SDDM removal"
            return 0
        fi

        sudo rm -f "/etc/sddm.conf.d/10-oneqode.conf"
        sudo rm -f "/usr/share/sddm/themes/breeze/theme.conf.user"
        sudo rm -rf "/usr/share/wallpapers/OneQode"
    else
        rm -f "/etc/sddm.conf.d/10-oneqode.conf"
        rm -f "/usr/share/sddm/themes/breeze/theme.conf.user"
        rm -rf "/usr/share/wallpapers/OneQode"
    fi

    success "SDDM configuration removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_sddm
fi
