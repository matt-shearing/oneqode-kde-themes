#!/usr/bin/env bash
# Common functions and variables for OneQode theme installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Directories
ONEQODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$ONEQODE_DIR/assets"
LOCAL_SHARE="$HOME/.local/share"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_STATE="$HOME/.local/state"
CONFIG_DIR="$HOME/.config"
SYSTEMD_USER_DIR="$CONFIG_DIR/systemd/user"
SYSTEMD_USER="$SYSTEMD_USER_DIR"

# Helper functions
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }
debug() { [[ "${ONEQODE_DEBUG:-}" == "1" ]] && printf "${CYAN}[DEBUG]${NC} %s\n" "$1" || true; }

# Check if a command exists
has_cmd() { command -v "$1" &>/dev/null; }

# Reload a running Ghostty via its GTK action. SIGUSR1 used to crash it, and
# gtk-single-instance windows inherit the already-loaded config otherwise.
reload_ghostty() {
    busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty \
        org.gtk.Actions Activate sava{sv} reload-config 0 0 >/dev/null 2>&1 \
        || gdbus call --session --dest com.mitchellh.ghostty \
            --object-path /com/mitchellh/ghostty \
            --method org.gtk.Actions.Activate reload-config [] {} >/dev/null 2>&1 \
        || true
}

# Ensure not running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. It installs to user directories."
        exit 1
    fi
}

# Which desktop this machine is running. "omarchy" wins over leftover
# Plasma tools so a migrated box does not get the KDE switcher.
detect_desktop() {
    local desktop
    desktop=$(printf '%s:%s' "${XDG_CURRENT_DESKTOP:-}" "${XDG_SESSION_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')
    if [[ $desktop == *hyprland* || $desktop == *omarchy* ]] || { has_cmd omarchy && [[ -d $CONFIG_DIR/omarchy ]]; }; then
        echo omarchy
        return
    fi
    if [[ $desktop == *kde* || $desktop == *plasma* ]] || has_cmd plasma-apply-lookandfeel; then
        echo kde
        return
    fi
    echo unknown
}

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
            [[ -f "$LOCAL_SHARE/konsole/OneQodeNightRide.colorscheme" ]]
            ;;
        ghostty)
            [[ -f "$CONFIG_DIR/ghostty/themes/oneqode-night-ride" ]]
            ;;
        herdr)
            [[ -f "$CONFIG_DIR/herdr/themes/oneqode-night-ride.toml" ]] || \
            [[ -f "$LOCAL_SHARE/oneqode/herdr/oneqode-night-ride.toml" ]]
            ;;
        omarchy)
            [[ -d "$CONFIG_DIR/omarchy/themes/omarchy-oq-night-ride" ]] && \
            [[ -x "$LOCAL_BIN/omarchy-oq-auto-theme" ]]
            ;;
        keychron)
            [[ -x "$LOCAL_BIN/oneqode-keychron" ]]
            ;;
        fastfetch)
            [[ -f "$CONFIG_DIR/fastfetch/config-night-ride.jsonc" ]]
            ;;
        mattermost)
            [[ -f "$LOCAL_SHARE/oneqode/mattermost/oneqode-night-ride.json" ]]
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
            { [[ -f "$CONFIG_DIR/gtk-4.0/gtk.css" ]] && \
              grep -q 'OneQode GTK' "$CONFIG_DIR/gtk-4.0/gtk.css" 2>/dev/null; } || \
            { [[ -f "$CONFIG_DIR/gtk-3.0/gtk.css" ]] && \
              grep -q 'OneQode GTK' "$CONFIG_DIR/gtk-3.0/gtk.css" 2>/dev/null; }
            ;;
        switcher)
            [[ -x "$LOCAL_BIN/oneqode-theme-switch" ]]
            ;;
        omarchy)
            [[ -x "$LOCAL_BIN/oneqode-control" ]] && \
            [[ -d "$CONFIG_DIR/omarchy/plugins/oneqode.control" ]]
            ;;
        sddm)
            [[ -f "/etc/sddm.conf.d/10-oneqode.conf" ]]
            ;;
        *)
            return 1
            ;;
    esac
}
