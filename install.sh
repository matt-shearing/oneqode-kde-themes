#!/usr/bin/env bash
# OneQode KDE Theme Suite - Installer
# ====================================
# Idempotent installer for Plasma 6 / Wayland on EndeavourOS/Arch
#
# This script:
# - Installs required packages via pacman and yay
# - Installs theme assets to ~/.local/share/
# - Enables KWin blur/translucency effects
# - Installs and enables the theme switcher timer
# - Applies the Light Glass theme immediately

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"
SWITCHER_DIR="$SCRIPT_DIR/switcher"

# User directories
LOCAL_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
SYSTEMD_USER="$CONFIG_DIR/systemd/user"

# Logging
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if running as root (we don't want that)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. It will use sudo when needed."
        exit 1
    fi
}

# Check for required commands
check_requirements() {
    local missing=()

    for cmd in pacman sudo systemctl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required commands: ${missing[*]}"
        exit 1
    fi

    # Check for yay (AUR helper)
    if ! command -v yay &>/dev/null; then
        warn "yay not found. Klassy installation will be skipped."
        warn "Install yay manually: https://github.com/Jguer/yay"
    fi
}

# Install pacman packages
install_pacman_deps() {
    info "Installing pacman dependencies..."

    local packages=(
        git
        rsync
        jq
        curl
        plasma-workspace
        python
        python-astral
        papirus-icon-theme
        inter-font
        ttf-jetbrains-mono-nerd
        inotify-tools
    )

    # Optional packages (nice to have)
    local optional=(
        tree
        shellcheck
    )

    # Check which packages need installing
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    # Add optional packages if not installed
    for pkg in "${optional[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing: ${to_install[*]}"
        sudo pacman -S --noconfirm --needed "${to_install[@]}"
        success "Pacman packages installed"
    else
        success "All pacman packages already installed"
    fi
}

# Install Klassy via yay
install_klassy() {
    if ! command -v yay &>/dev/null; then
        warn "yay not available, skipping Klassy installation"
        warn "Themes will fall back to Breeze decoration"
        return 0
    fi

    # Check if klassy is already installed
    if pacman -Qi klassy &>/dev/null || pacman -Qi klassy-bin &>/dev/null; then
        success "Klassy already installed"
        return 0
    fi

    info "Installing Klassy window decoration..."

    # Try klassy-bin first (precompiled, faster)
    if yay -Si klassy-bin &>/dev/null; then
        info "Installing klassy-bin (precompiled)..."
        if yay -S --noconfirm --needed klassy-bin; then
            success "klassy-bin installed"
            return 0
        fi
        warn "klassy-bin installation failed, trying klassy..."
    fi

    # Fall back to klassy (compiled from source)
    if yay -Si klassy &>/dev/null; then
        info "Installing klassy (from source, this may take a while)..."
        if yay -S --noconfirm --needed klassy; then
            success "klassy installed"
            return 0
        fi
    fi

    warn "Could not install Klassy. Themes will use Breeze decoration."
    warn "Manual installation: yay -S klassy-bin OR yay -S klassy"
}

# Install Bibata cursor theme
install_cursors() {
    info "Installing Bibata cursor theme..."

    local cursor_dir="$LOCAL_SHARE/icons"
    local cursor_name="Bibata-Modern-Ice"
    local cursor_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Ice.tar.xz"

    # Check if already installed
    if [[ -d "$cursor_dir/$cursor_name" ]]; then
        success "Bibata cursor already installed"
        return 0
    fi

    mkdir -p "$cursor_dir"

    # Download and extract
    local tmp_file
    tmp_file=$(mktemp)

    if curl -fsSL "$cursor_url" -o "$tmp_file"; then
        tar -xf "$tmp_file" -C "$cursor_dir"
        rm -f "$tmp_file"
        success "Bibata cursor installed"
    else
        rm -f "$tmp_file"
        warn "Could not download Bibata cursor"
        warn "Manual install: download from https://github.com/ful1e5/Bibata_Cursor/releases"
        return 1
    fi
}

# Configure SDDM (requires root)
configure_sddm() {
    info "Configuring SDDM login screen..."

    local sddm_conf_dir="/etc/sddm.conf.d"
    local sddm_theme_dir="/usr/share/sddm/themes/breeze"
    local wallpaper_dir="/usr/share/wallpapers/OneQode"

    # Check if we can write to system directories
    if [[ ! -w "/etc" ]]; then
        warn "SDDM configuration requires root privileges"
        warn "Run the following commands manually to enable SDDM theming:"
        echo ""
        echo "  sudo mkdir -p $wallpaper_dir"
        echo "  sudo cp $ASSETS_DIR/wallpapers/*.jpg $wallpaper_dir/"
        echo "  sudo mkdir -p $sddm_conf_dir"
        echo "  sudo cp $SCRIPT_DIR/sddm/10-oneqode.conf $sddm_conf_dir/"
        echo "  sudo cp $SCRIPT_DIR/sddm/theme.conf.user.light $sddm_theme_dir/theme.conf.user"
        echo ""
        return 0
    fi

    # Install wallpapers to system location (for SDDM access)
    mkdir -p "$wallpaper_dir"
    cp "$ASSETS_DIR/wallpapers/"*.jpg "$wallpaper_dir/"

    # Install SDDM config
    mkdir -p "$sddm_conf_dir"
    cp "$SCRIPT_DIR/sddm/10-oneqode.conf" "$sddm_conf_dir/"

    # Set initial theme background (Light Glass for day)
    if [[ -d "$sddm_theme_dir" ]]; then
        cp "$SCRIPT_DIR/sddm/theme.conf.user.light" "$sddm_theme_dir/theme.conf.user"
        success "SDDM configured with OneQode background"
    else
        warn "Breeze SDDM theme not found at $sddm_theme_dir"
        warn "SDDM background not configured"
    fi
}

# Create required directories
create_directories() {
    info "Creating directories..."

    mkdir -p "$LOCAL_SHARE/color-schemes"
    mkdir -p "$LOCAL_SHARE/plasma/look-and-feel"
    mkdir -p "$LOCAL_SHARE/wallpapers/OneQode"
    mkdir -p "$LOCAL_SHARE/icons"
    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LOCAL_STATE/oneqode"
    mkdir -p "$CONFIG_DIR/oneqode"
    mkdir -p "$SYSTEMD_USER"

    success "Directories created"
}

# Install color schemes
install_color_schemes() {
    info "Installing color schemes..."

    rsync -a "$ASSETS_DIR/color-schemes/" "$LOCAL_SHARE/color-schemes/"

    success "Color schemes installed"
}

# Install look-and-feel packages
install_look_and_feel() {
    info "Installing look-and-feel packages..."

    rsync -a "$ASSETS_DIR/look-and-feel/" "$LOCAL_SHARE/plasma/look-and-feel/"

    success "Look-and-feel packages installed"
}

# Install wallpapers
install_wallpapers() {
    info "Installing wallpapers..."

    rsync -a "$ASSETS_DIR/wallpapers/" "$LOCAL_SHARE/wallpapers/OneQode/"

    success "Wallpapers installed"
}

# Install switcher script
install_switcher() {
    info "Installing theme switcher..."

    # Install the switcher script
    install -m 755 "$SWITCHER_DIR/oneqode-theme-switch" "$LOCAL_BIN/"

    # Install the theme watcher script (ensures Klassy on GUI theme changes)
    install -m 755 "$SWITCHER_DIR/oneqode-theme-watcher" "$LOCAL_BIN/"

    # Install config if not exists (preserve user config)
    if [[ ! -f "$CONFIG_DIR/oneqode/oneqode-theme-switcher.conf" ]]; then
        install -m 644 "$SWITCHER_DIR/oneqode-theme-switcher.conf" "$CONFIG_DIR/oneqode/"
        success "Switcher config installed (new)"
    else
        info "Switcher config exists, preserving user settings"
    fi

    # Install systemd units
    install -m 644 "$SWITCHER_DIR/oneqode-theme-switcher.service" "$SYSTEMD_USER/"
    install -m 644 "$SWITCHER_DIR/oneqode-theme-switcher.timer" "$SYSTEMD_USER/"
    install -m 644 "$SWITCHER_DIR/oneqode-theme-watcher.service" "$SYSTEMD_USER/"

    success "Theme switcher installed"
}

# Enable and start timer and watcher
enable_timer() {
    info "Enabling theme switcher timer and watcher..."

    systemctl --user daemon-reload
    systemctl --user enable --now oneqode-theme-switcher.timer
    systemctl --user enable --now oneqode-theme-watcher.service

    success "Timer and watcher enabled and started"
}

# Configure KWin effects
configure_kwin() {
    info "Configuring KWin blur/translucency effects..."

    local kwinrc="$CONFIG_DIR/kwinrc"

    # Backup existing kwinrc
    if [[ -f "$kwinrc" ]]; then
        local backup="${kwinrc}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$kwinrc" "$backup"
        info "Backed up kwinrc to $backup"
    fi

    # Check for kwriteconfig6
    if ! command -v kwriteconfig6 &>/dev/null; then
        warn "kwriteconfig6 not found, cannot configure KWin automatically"
        warn "Manual steps required - see README.md"
        return 0
    fi

    # Enable blur, translucency, and contrast effects
    kwriteconfig6 --file "$kwinrc" --group Plugins --key blurEnabled true
    kwriteconfig6 --file "$kwinrc" --group Plugins --key translucencyEnabled true
    kwriteconfig6 --file "$kwinrc" --group Plugins --key contrastEnabled true

    # Try to reconfigure KWin
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v qdbus &>/dev/null; then
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    success "KWin effects configured"
}

# Detect theme apply tool
detect_apply_tool() {
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        echo "plasma-apply-lookandfeel"
    elif command -v lookandfeeltool &>/dev/null; then
        echo "lookandfeeltool"
    else
        echo ""
    fi
}

# Apply Light Glass theme immediately
apply_initial_theme() {
    info "Applying OneQode Light Glass theme..."

    local tool
    tool=$(detect_apply_tool)

    if [[ -z "$tool" ]]; then
        warn "No theme apply tool found (plasma-apply-lookandfeel or lookandfeeltool)"
        warn "Theme installed but not applied. Log out and back in, then apply manually."
        return 0
    fi

    if "$tool" -a org.oneqode.lightglass 2>/dev/null; then
        # Update state file
        echo "org.oneqode.lightglass" > "$LOCAL_STATE/oneqode/theme-state"
        success "Light Glass theme applied"
    else
        warn "Could not apply theme automatically"
        warn "Try logging out and back in, then run: $tool -a org.oneqode.lightglass"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  OneQode KDE Theme Suite Installed!   ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Installed components:"
    echo "  - Color schemes: OneQodeLightGlass, OneQodeNightRide"
    echo "  - Look-and-feel: org.oneqode.lightglass, org.oneqode.nightride"
    echo "  - Splash screens: Minimal branded KSplash for each theme"
    echo "  - Cursor theme: Bibata-Modern-Ice"
    echo "  - Wallpapers: ~/.local/share/wallpapers/OneQode/"
    echo "  - Theme switcher: ~/.local/bin/oneqode-theme-switch"
    echo "  - Theme watcher: ~/.local/bin/oneqode-theme-watcher"
    echo "  - Systemd timer: oneqode-theme-switcher.timer (every 5 min)"
    echo "  - SDDM login: Breeze theme with OneQode background"
    echo ""
    echo "Configuration:"
    echo "  - Edit ~/.config/oneqode/oneqode-theme-switcher.conf"
    echo "  - Set your latitude, longitude, and timezone for solar mode"
    echo ""
    echo "Commands:"
    echo "  - Force day theme:   oneqode-theme-switch --force-day"
    echo "  - Force night theme: oneqode-theme-switch --force-night"
    echo "  - Check status:      oneqode-theme-switch --status"
    echo "  - Timer status:      systemctl --user status oneqode-theme-switcher.timer"
    echo ""
    echo "For best results, log out and back in to fully apply the theme."
    echo ""
}

# Main
main() {
    echo ""
    echo -e "${BLUE}OneQode KDE Theme Suite Installer${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo ""

    check_not_root
    check_requirements

    install_pacman_deps
    install_klassy
    install_cursors

    create_directories
    install_color_schemes
    install_look_and_feel
    install_wallpapers
    install_switcher

    enable_timer
    configure_kwin
    configure_sddm
    apply_initial_theme

    print_summary
}

main "$@"
