#!/usr/bin/env bash
# Common functions and variables for OneQode theme installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Directories
ONEQODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_SHARE="$HOME/.local/share"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_STATE="$HOME/.local/state"
CONFIG_DIR="$HOME/.config"
SYSTEMD_USER_DIR="$CONFIG_DIR/systemd/user"

# Helper functions
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# Detect theme apply command
detect_apply_tool() {
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        echo "plasma-apply-lookandfeel"
    elif command -v lookandfeeltool &>/dev/null; then
        echo "lookandfeeltool"
    else
        echo ""
    fi
}

# Detect config writer
detect_kwriteconfig() {
    if command -v kwriteconfig6 &>/dev/null; then
        echo "kwriteconfig6"
    elif command -v kwriteconfig5 &>/dev/null; then
        echo "kwriteconfig5"
    else
        echo ""
    fi
}

# Check if a component is installed
is_installed() {
    local component="$1"
    case "$component" in
        colors)
            [[ -f "$LOCAL_SHARE/color-schemes/OneQodeLightGlass.colors" ]] && \
            [[ -f "$LOCAL_SHARE/color-schemes/OneQodeNightRide.colors" ]]
            ;;
        lookandfeel)
            [[ -d "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.lightglass" ]] && \
            [[ -d "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.nightride" ]]
            ;;
        wallpapers)
            [[ -d "$LOCAL_SHARE/wallpapers/OneQode" ]]
            ;;
        cursors)
            [[ -d "$LOCAL_SHARE/icons/Bibata-Modern-Ice" ]]
            ;;
        konsole)
            [[ -f "$LOCAL_SHARE/konsole/OneQode-Night-Ride.colorscheme" ]]
            ;;
        ghostty)
            [[ -f "$CONFIG_DIR/ghostty/themes/oneqode-night-ride" ]]
            ;;
        zed)
            [[ -f "$CONFIG_DIR/zed/themes/oneqode.json" ]]
            ;;
        typora)
            [[ -f "$CONFIG_DIR/Typora/themes/oneqode-night-ride.css" ]]
            ;;
        obsidian)
            # Check common vault locations (avoid full $HOME scan)
            # State file tracks successful installation
            [[ -f "$LOCAL_STATE/oneqode/obsidian-installed" ]] || \
            [[ -d "$HOME/Documents/Master Vault/.obsidian/themes/OneQode Night Ride" ]] || \
            [[ -d "$HOME/Documents/Obsidian/.obsidian/themes/OneQode Night Ride" ]] || \
            [[ -d "$HOME/Obsidian/.obsidian/themes/OneQode Night Ride" ]]
            ;;
        firefox)
            # Check Firefox profile directories directly
            for dir in "$HOME/.mozilla/firefox"/*.default-release "$HOME/.mozilla/firefox"/*.default; do
                [[ -f "$dir/chrome/userChrome-night-ride.css" ]] && return 0
            done
            return 1
            ;;
        gtk)
            [[ -f "$CONFIG_DIR/gtk-3.0/gtk.css" ]] && \
            grep -q 'OneQode GTK3' "$CONFIG_DIR/gtk-3.0/gtk.css" 2>/dev/null
            ;;
        switcher)
            [[ -x "$LOCAL_BIN/oneqode-theme-switch" ]]
            ;;
        sddm)
            [[ -f "/etc/sddm.conf.d/10-oneqode.conf" ]]
            ;;
        *)
            return 1
            ;;
    esac
}
