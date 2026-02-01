#!/usr/bin/env bash
# OneQode KDE Theme Suite - Uninstaller
# ======================================
# Removes all installed components and attempts to restore previous state

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root."
        exit 1
    fi
}

# Disable and remove timer and watcher
remove_timer() {
    info "Disabling theme switcher timer and watcher..."

    if systemctl --user is-enabled oneqode-theme-switcher.timer &>/dev/null; then
        systemctl --user disable --now oneqode-theme-switcher.timer 2>/dev/null || true
    fi

    if systemctl --user is-active oneqode-theme-switcher.service &>/dev/null; then
        systemctl --user stop oneqode-theme-switcher.service 2>/dev/null || true
    fi

    if systemctl --user is-enabled oneqode-theme-watcher.service &>/dev/null; then
        systemctl --user disable --now oneqode-theme-watcher.service 2>/dev/null || true
    fi

    # Remove unit files
    rm -f "$SYSTEMD_USER/oneqode-theme-switcher.service"
    rm -f "$SYSTEMD_USER/oneqode-theme-switcher.timer"
    rm -f "$SYSTEMD_USER/oneqode-theme-watcher.service"

    systemctl --user daemon-reload

    success "Timer and watcher disabled and removed"
}

# Remove switcher
remove_switcher() {
    info "Removing theme switcher..."

    rm -f "$LOCAL_BIN/oneqode-theme-switch"
    rm -f "$LOCAL_BIN/oneqode-theme-watcher"

    success "Theme switcher removed"
}

# Remove color schemes
remove_color_schemes() {
    info "Removing color schemes..."

    rm -f "$LOCAL_SHARE/color-schemes/OneQodeLightGlass.colors"
    rm -f "$LOCAL_SHARE/color-schemes/OneQodeNightRide.colors"

    success "Color schemes removed"
}

# Remove look-and-feel packages
remove_look_and_feel() {
    info "Removing look-and-feel packages..."

    rm -rf "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.lightglass"
    rm -rf "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.nightride"

    success "Look-and-feel packages removed"
}

# Remove wallpapers
remove_wallpapers() {
    info "Removing wallpapers..."

    rm -rf "$LOCAL_SHARE/wallpapers/OneQode"

    success "Wallpapers removed"
}

# Remove state files
remove_state() {
    info "Removing state files..."

    rm -rf "$LOCAL_STATE/oneqode"

    success "State files removed"
}

# Remove config (optional, ask user)
remove_config() {
    local config_file="$CONFIG_DIR/oneqode/oneqode-theme-switcher.conf"

    if [[ -f "$config_file" ]]; then
        echo ""
        read -p "Remove configuration file? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$CONFIG_DIR/oneqode"
            success "Configuration removed"
        else
            info "Configuration preserved at $config_file"
        fi
    fi
}

# Restore KWin config
restore_kwin() {
    info "Restoring KWin configuration..."

    local kwinrc="$CONFIG_DIR/kwinrc"

    # Find latest backup
    local latest_backup
    latest_backup=$(ls -t "${kwinrc}.bak."* 2>/dev/null | head -n1 || true)

    if [[ -n "$latest_backup" && -f "$latest_backup" ]]; then
        echo ""
        read -p "Restore kwinrc from backup ($latest_backup)? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$latest_backup" "$kwinrc"
            success "Restored kwinrc from backup"

            # Reconfigure KWin
            if command -v qdbus6 &>/dev/null; then
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
            elif command -v qdbus &>/dev/null; then
                qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
            fi
            return 0
        fi
    fi

    # If no restore, just remove the keys we added
    if command -v kwriteconfig6 &>/dev/null; then
        info "Disabling blur/translucency effects..."
        kwriteconfig6 --file "$kwinrc" --group Plugins --key blurEnabled false
        kwriteconfig6 --file "$kwinrc" --group Plugins --key translucencyEnabled false
        kwriteconfig6 --file "$kwinrc" --group Plugins --key contrastEnabled false

        # Reconfigure KWin
        if command -v qdbus6 &>/dev/null; then
            qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
        elif command -v qdbus &>/dev/null; then
            qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
        fi

        success "KWin effects disabled"
    else
        warn "Cannot restore KWin config automatically (kwriteconfig6 not found)"
    fi
}

# Apply default theme
apply_default_theme() {
    info "Applying default Breeze theme..."

    local tool=""
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        tool="plasma-apply-lookandfeel"
    elif command -v lookandfeeltool &>/dev/null; then
        tool="lookandfeeltool"
    fi

    if [[ -n "$tool" ]]; then
        if "$tool" -a org.kde.breeze.desktop 2>/dev/null; then
            success "Breeze theme applied"
        else
            warn "Could not apply Breeze theme automatically"
        fi
    else
        warn "No theme apply tool found. Apply theme manually via System Settings."
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  OneQode KDE Theme Suite Uninstalled  ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Removed components:"
    echo "  - Color schemes"
    echo "  - Look-and-feel packages"
    echo "  - Wallpapers"
    echo "  - Theme switcher and timer"
    echo "  - State files"
    echo ""
    echo "Note: Installed packages (python-astral, klassy, etc.) were NOT removed."
    echo "Remove them manually with: sudo pacman -Rs <package>"
    echo ""
    echo "For a complete reset, log out and back in."
    echo ""
}

# Main
main() {
    echo ""
    echo -e "${BLUE}OneQode KDE Theme Suite Uninstaller${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo ""

    check_not_root

    echo "This will remove all OneQode theme components."
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    remove_timer
    remove_switcher
    remove_color_schemes
    remove_look_and_feel
    remove_wallpapers
    remove_state
    remove_config
    restore_kwin
    apply_default_theme

    print_summary
}

main "$@"
