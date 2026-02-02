#!/usr/bin/env bash
# Common functions for OneQode theme suite

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Paths
export ONEQODE_DIR="${ONEQODE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export ASSETS_DIR="$ONEQODE_DIR/assets"
export LOCAL_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
export CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
export LOCAL_BIN="$HOME/.local/bin"
export LOCAL_STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
export SYSTEMD_USER="$CONFIG_DIR/systemd/user"

# Logging
info() { echo -e "${BLUE}::${NC} $*"; }
success() { echo -e "${GREEN}::${NC} $*"; }
warn() { echo -e "${YELLOW}::${NC} $*"; }
error() { echo -e "${RED}::${NC} $*" >&2; }

# Check if a command exists
has_cmd() { command -v "$1" &>/dev/null; }

# Check if running as root
is_root() { [[ $EUID -eq 0 ]]; }

# Ensure not running as root
check_not_root() {
    if is_root; then
        error "Do not run as root. The script will use sudo when needed."
        exit 1
    fi
}

# Source a lib script
source_lib() {
    local script="$ONEQODE_DIR/lib/$1"
    if [[ -f "$script" ]]; then
        # shellcheck source=/dev/null
        source "$script"
    else
        error "Library not found: $1"
        return 1
    fi
}

# Check if component is installed
is_installed() {
    local component="$1"
    case "$component" in
        colors)
            [[ -f "$LOCAL_SHARE/color-schemes/OneQodeLightGlass.colors" ]]
            ;;
        lookandfeel)
            [[ -d "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.lightglass" ]]
            ;;
        wallpapers)
            [[ -f "$LOCAL_SHARE/wallpapers/OneQode/OneQode-Light-Glass.jpg" ]]
            ;;
        cursors)
            [[ -d "$LOCAL_SHARE/icons/Bibata-Modern-Ice" ]]
            ;;
        konsole)
            [[ -f "$LOCAL_SHARE/konsole/OneQodeLightGlass.colorscheme" ]]
            ;;
        ghostty)
            [[ -f "$CONFIG_DIR/ghostty/themes/oneqode-light-glass" ]]
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

# Get install status icon
status_icon() {
    if is_installed "$1"; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "${RED}○${NC}"
    fi
}
