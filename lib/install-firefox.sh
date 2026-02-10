#!/usr/bin/env bash
# Install Firefox themes (userChrome.css)

install_firefox() {
    info "Installing Firefox themes..."

    local assets_dir="$ONEQODE_DIR/assets/firefox"
    local firefox_dir="$HOME/.mozilla/firefox"

    # Check if Firefox is installed
    if [[ ! -d "$firefox_dir" ]]; then
        warn "Firefox profile directory not found"
        warn "Install Firefox first, then re-run this installer"
        return 1
    fi

    # Find default profile
    local profile_dir=""
    for dir in "$firefox_dir"/*.default-release "$firefox_dir"/*.default; do
        if [[ -d "$dir" ]]; then
            profile_dir="$dir"
            break
        fi
    done

    if [[ -z "$profile_dir" ]]; then
        warn "No Firefox profile found"
        return 1
    fi

    local chrome_dir="$profile_dir/chrome"
    mkdir -p "$chrome_dir"

    # Copy all theme files
    cp "$assets_dir/userChrome-night-ride.css" "$chrome_dir/"
    cp "$assets_dir/userChrome-light-glass.css" "$chrome_dir/"
    cp "$assets_dir/userChrome-auto.css" "$chrome_dir/"

    # Install auto-switching CSS as the active theme
    cp "$assets_dir/userChrome-auto.css" "$chrome_dir/userChrome.css"

    # Create README with instructions
    cat > "$chrome_dir/README-OneQode.txt" << 'EOF'
OneQode Firefox Themes
======================

The auto-switching theme is installed as userChrome.css by default.
It follows KDE's light/dark mode via prefers-color-scheme media queries.

Three theme files are available:
- userChrome-auto.css (auto-switches with system theme - RECOMMENDED)
- userChrome-night-ride.css (dark synthwave, always)
- userChrome-light-glass.css (light teal, always)

To use a static theme instead, copy it over userChrome.css and restart Firefox.
EOF

    success "Firefox auto-switching theme installed to: $chrome_dir"
    echo ""
    info "IMPORTANT: You must enable custom stylesheets in Firefox:"
    echo "  1. Open about:config"
    echo "  2. Set toolkit.legacyUserProfileCustomizations.stylesheets to true"
    echo "  3. Restart Firefox"
    echo "  (userChrome.css is already installed with auto light/dark switching)"
}

uninstall_firefox() {
    info "Removing Firefox themes..."

    local firefox_dir="$HOME/.mozilla/firefox"

    for profile_dir in "$firefox_dir"/*.default-release "$firefox_dir"/*.default; do
        if [[ -d "$profile_dir/chrome" ]]; then
            rm -f "$profile_dir/chrome/userChrome-night-ride.css"
            rm -f "$profile_dir/chrome/userChrome-light-glass.css"
            rm -f "$profile_dir/chrome/README-OneQode.txt"
        fi
    done

    success "Firefox themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_firefox
fi
