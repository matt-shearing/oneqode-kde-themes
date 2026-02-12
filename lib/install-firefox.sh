#!/usr/bin/env bash
# Install Firefox themes (userChrome.css + userContent.css)

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

    # Copy all browser chrome theme files
    cp "$assets_dir/userChrome-night-ride.css" "$chrome_dir/"
    cp "$assets_dir/userChrome-light-glass.css" "$chrome_dir/"
    cp "$assets_dir/userChrome-auto.css" "$chrome_dir/"

    # Copy all content (internal pages) theme files
    cp "$assets_dir/userContent-night-ride.css" "$chrome_dir/"
    cp "$assets_dir/userContent-light-glass.css" "$chrome_dir/"
    cp "$assets_dir/userContent-auto.css" "$chrome_dir/"

    # Install auto-switching CSS as the active themes
    cp "$assets_dir/userChrome-auto.css" "$chrome_dir/userChrome.css"
    cp "$assets_dir/userContent-auto.css" "$chrome_dir/userContent.css"

    # Create README with instructions
    cat > "$chrome_dir/README-OneQode.txt" << 'EOF'
OneQode Firefox Themes
======================

Auto-switching themes are installed by default:
- userChrome.css  — browser UI (toolbar, tabs, sidebar, menus)
- userContent.css — internal pages (new tab, settings, addons, error pages)

Both follow KDE's light/dark mode via prefers-color-scheme media queries.

Static variants are also available:
- userChrome-auto.css / userContent-auto.css (auto-switch - RECOMMENDED)
- userChrome-night-ride.css / userContent-night-ride.css (dark synthwave)
- userChrome-light-glass.css / userContent-light-glass.css (light teal)

To use a static theme, copy the matching pair over userChrome.css
and userContent.css, then restart Firefox.
EOF

    success "Firefox auto-switching theme installed to: $chrome_dir"
    echo ""
    info "IMPORTANT: You must enable custom stylesheets in Firefox:"
    echo "  1. Open about:config"
    echo "  2. Set toolkit.legacyUserProfileCustomizations.stylesheets to true"
    echo "  3. Restart Firefox"
    echo "  (userChrome.css + userContent.css are installed with auto light/dark switching)"
}

uninstall_firefox() {
    info "Removing Firefox themes..."

    local firefox_dir="$HOME/.mozilla/firefox"

    for profile_dir in "$firefox_dir"/*.default-release "$firefox_dir"/*.default; do
        if [[ -d "$profile_dir/chrome" ]]; then
            rm -f "$profile_dir/chrome/userChrome-night-ride.css"
            rm -f "$profile_dir/chrome/userChrome-light-glass.css"
            rm -f "$profile_dir/chrome/userContent-night-ride.css"
            rm -f "$profile_dir/chrome/userContent-light-glass.css"
            rm -f "$profile_dir/chrome/userContent-auto.css"
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
