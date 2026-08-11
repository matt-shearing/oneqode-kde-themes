#!/usr/bin/env bash
# Install Konsole color schemes

install_konsole() {
    info "Installing Konsole color schemes..."

    mkdir -p "$LOCAL_SHARE/konsole"
    cp "$ASSETS_DIR/konsole/"*.colorscheme "$LOCAL_SHARE/konsole/"

    # Configure default profile cursor: blinking block, uses colorscheme cursor color
    local default_profile
    default_profile=$(kreadconfig6 --file konsolerc --group "Desktop Entry" --key "DefaultProfile" 2>/dev/null || echo "")

    if [[ -n "$default_profile" && -f "$LOCAL_SHARE/konsole/$default_profile" ]]; then
        kwriteconfig6 --file "$LOCAL_SHARE/konsole/$default_profile" --group "Cursor Options" --key "CursorShape" "0"
        kwriteconfig6 --file "$LOCAL_SHARE/konsole/$default_profile" --group "Cursor Options" --key "BlinkingCursorEnabled" "true"
        kwriteconfig6 --file "$LOCAL_SHARE/konsole/$default_profile" --group "Cursor Options" --key "UseCustomCursorColor" "true"
        kwriteconfig6 --file "$LOCAL_SHARE/konsole/$default_profile" --group "Cursor Options" --key "CustomCursorColor" "255,0,128"
        kwriteconfig6 --file "$LOCAL_SHARE/konsole/$default_profile" --group "Cursor Options" --key "CustomCursorTextColor" "25,28,42"
    fi

    # Enable DBus remote operations (needed for live theme switching)
    kwriteconfig6 --file konsolerc --group "KonsoleWindow" --key "AllowRemoteOperations" "true" 2>/dev/null || true

    # KDE Gear 25.12 moved setProfile behind a second, separate opt-in that
    # defaults to false; without it live re-theming of running Konsole/Yakuake
    # sessions fails with DBus AccessDenied. Read at startup, so already-open
    # windows keep the old value until they are restarted.
    kwriteconfig6 --file konsolerc --group "KonsoleWindow" --key "EnableSecuritySensitiveDBusAPI" "true" 2>/dev/null || true

    success "Konsole color schemes installed (with blinking cursor)"
}

uninstall_konsole() {
    info "Removing Konsole color schemes..."

    rm -f "$LOCAL_SHARE/konsole/OneQodeLightGlass.colorscheme"
    rm -f "$LOCAL_SHARE/konsole/OneQodeNightRide.colorscheme"

    success "Konsole color schemes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_konsole
fi
