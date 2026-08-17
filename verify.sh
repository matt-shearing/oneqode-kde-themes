#!/usr/bin/env bash
# OneQode Linux Theme - Verification Script
# ==============================================
# Validates installation, checks unit files, and runs diagnostics

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
LOCAL_BIN="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
SYSTEMD_USER="$CONFIG_DIR/systemd/user"

# Counters
PASS=0
FAIL=0
WARN=0

# Test functions
pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((PASS++)) || true
}

fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((FAIL++)) || true
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    ((WARN++)) || true
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

section() {
    echo ""
    echo -e "${BLUE}=== $* ===${NC}"
}

# Check if file exists
check_file() {
    local path="$1"
    local desc="${2:-$path}"
    if [[ -f "$path" ]]; then
        pass "$desc exists"
        return 0
    else
        fail "$desc missing"
        return 1
    fi
}

# Check if directory exists
check_dir() {
    local path="$1"
    local desc="${2:-$path}"
    if [[ -d "$path" ]]; then
        pass "$desc exists"
        return 0
    else
        fail "$desc missing"
        return 1
    fi
}

# Check if file is executable
check_executable() {
    local path="$1"
    local desc="${2:-$path}"
    if [[ -x "$path" ]]; then
        pass "$desc is executable"
        return 0
    else
        fail "$desc is not executable"
        return 1
    fi
}

# Check command exists (always succeeds, warns if missing)
check_command() {
    local cmd="$1"
    local desc="${2:-$cmd}"
    if command -v "$cmd" &>/dev/null; then
        pass "$desc available"
    else
        warn "$desc not found"
    fi
    return 0
}

# Verify repo structure
verify_repo_structure() {
    section "Repository Structure"

    check_file "$SCRIPT_DIR/install.sh" "install.sh"
    check_file "$SCRIPT_DIR/uninstall.sh" "uninstall.sh"
    check_file "$SCRIPT_DIR/verify.sh" "verify.sh"
    check_file "$SCRIPT_DIR/README.md" "README.md"
    check_file "$SCRIPT_DIR/SPEC.md" "SPEC.md"

    check_file "$SCRIPT_DIR/assets/color-schemes/OneQodeLightGlass.colors" "Light Glass color scheme"
    check_file "$SCRIPT_DIR/assets/color-schemes/OneQodeNightRide.colors" "Night Ride color scheme"

    check_dir "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass" "Light Glass look-and-feel"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass/metadata.json" "Light Glass metadata.json"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass/manifest.json" "Light Glass manifest.json"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass/contents/defaults" "Light Glass defaults"

    check_dir "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride" "Night Ride look-and-feel"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride/metadata.json" "Night Ride metadata.json"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride/manifest.json" "Night Ride manifest.json"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride/contents/defaults" "Night Ride defaults"

    check_file "$SCRIPT_DIR/assets/wallpapers/OneQode-Light-Glass.jpg" "Light Glass wallpaper"
    check_file "$SCRIPT_DIR/assets/wallpapers/OneQode-Night-Ride.jpg" "Night Ride wallpaper"

    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass/contents/splash/Splash.qml" "Light Glass splash"
    check_file "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride/contents/splash/Splash.qml" "Night Ride splash"

    check_file "$SCRIPT_DIR/sddm/10-oneqode.conf" "SDDM config"
    check_file "$SCRIPT_DIR/sddm/theme.conf.user.light" "SDDM light background"
    check_file "$SCRIPT_DIR/sddm/theme.conf.user.dark" "SDDM dark background"

    check_file "$SCRIPT_DIR/assets/konsole/OneQodeLightGlass.colorscheme" "Konsole Light Glass"
    check_file "$SCRIPT_DIR/assets/konsole/OneQodeNightRide.colorscheme" "Konsole Night Ride"
    check_file "$SCRIPT_DIR/assets/ghostty/oneqode-light-glass" "Ghostty Light Glass"
    check_file "$SCRIPT_DIR/assets/ghostty/oneqode-night-ride" "Ghostty Night Ride"
    check_file "$SCRIPT_DIR/assets/herdr/oneqode-light-glass.toml" "Herdr Light Glass"
    check_file "$SCRIPT_DIR/assets/herdr/oneqode-night-ride.toml" "Herdr Night Ride"
    check_file "$SCRIPT_DIR/assets/herdr/apply-theme.py" "Herdr apply-theme.py"
    check_file "$SCRIPT_DIR/lib/install-herdr.sh" "Herdr installer"

    # Ghostty must use native light/dark pairing + D-Bus reload, not a
    # flipping config-file include. The gtk-single-instance daemon never
    # picks up a symlink retarget on its own.
    if grep -q 'theme = light:oneqode-light-glass,dark:oneqode-night-ride' \
            "$SCRIPT_DIR/lib/install-ghostty.sh" \
            "$SCRIPT_DIR/switcher/oneqode-theme-switch"; then
        pass "Ghostty installer/switcher use native light/dark pairing"
    else
        fail "Ghostty installer/switcher missing native light/dark theme pairing"
    fi
    if grep -qE '^[[:space:]]*(theme_include=|[^#[:space:]].*config-file = themes/oneqode-current)' \
            "$SCRIPT_DIR/lib/install-ghostty.sh"; then
        fail "Ghostty installer still writes the old oneqode-current include"
    else
        pass "Ghostty installer no longer writes oneqode-current include"
    fi
    if grep -q 'org.gtk.Actions Activate' "$SCRIPT_DIR/switcher/oneqode-theme-switch"; then
        pass "Ghostty switcher reloads via D-Bus reload-config"
    else
        fail "Ghostty switcher missing D-Bus reload-config"
    fi
    if grep -q 'update_herdr_theme' "$SCRIPT_DIR/switcher/oneqode-theme-switch" \
            && grep -q 'herdr server reload-config' "$SCRIPT_DIR/switcher/oneqode-theme-switch"; then
        pass "Herdr switcher writes palette and reloads the server"
    else
        fail "Herdr switcher missing update_herdr_theme / server reload-config"
    fi

    check_file "$SCRIPT_DIR/switcher/oneqode-theme-switch" "Switcher script"
    check_file "$SCRIPT_DIR/switcher/oneqode-theme-watcher" "Watcher script"
    check_file "$SCRIPT_DIR/switcher/oneqode-theme-switcher.service" "Systemd service"
    check_file "$SCRIPT_DIR/switcher/oneqode-theme-switcher.timer" "Systemd timer"
    check_file "$SCRIPT_DIR/switcher/oneqode-theme-watcher.service" "Watcher service"
    check_file "$SCRIPT_DIR/switcher/oneqode-theme-switcher.conf" "Switcher config template"
}

# Verify JSON syntax
verify_json_files() {
    section "JSON Syntax"

    local json_files=(
        "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass/metadata.json"
        "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.lightglass/manifest.json"
        "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride/metadata.json"
        "$SCRIPT_DIR/assets/look-and-feel/org.oneqode.nightride/manifest.json"
    )

    if ! command -v jq &>/dev/null; then
        warn "jq not installed, skipping JSON validation"
        return
    fi

    for file in "${json_files[@]}"; do
        if [[ -f "$file" ]]; then
            if jq empty "$file" 2>/dev/null; then
                pass "$(basename "$file") is valid JSON"
            else
                fail "$(basename "$file") has invalid JSON"
            fi
        fi
    done
}

# Verify systemd units
verify_systemd_units() {
    section "Systemd Units"

    local service="$SCRIPT_DIR/switcher/oneqode-theme-switcher.service"
    local timer="$SCRIPT_DIR/switcher/oneqode-theme-switcher.timer"

    if command -v systemd-analyze &>/dev/null; then
        # Verify service
        if [[ -f "$service" ]]; then
            if systemd-analyze --user verify "$service" 2>&1 | grep -q "error"; then
                fail "Service unit has errors"
            else
                pass "Service unit syntax OK"
            fi
        fi

        # Verify timer
        if [[ -f "$timer" ]]; then
            if systemd-analyze --user verify "$timer" 2>&1 | grep -q "error"; then
                fail "Timer unit has errors"
            else
                pass "Timer unit syntax OK"
            fi
        fi
    else
        warn "systemd-analyze not available, skipping unit verification"
    fi
}

# Verify shell scripts with shellcheck
verify_shellcheck() {
    section "Shell Scripts (shellcheck)"

    local scripts=(
        "$SCRIPT_DIR/install.sh"
        "$SCRIPT_DIR/uninstall.sh"
        "$SCRIPT_DIR/verify.sh"
        "$SCRIPT_DIR/switcher/oneqode-theme-switch"
        "$SCRIPT_DIR/switcher/oneqode-theme-watcher"
    )

    if ! command -v shellcheck &>/dev/null; then
        warn "shellcheck not installed, skipping shell script validation"
        info "Install with: sudo pacman -S shellcheck"
        return
    fi

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            local output
            if output=$(shellcheck -S warning "$script" 2>&1); then
                pass "$(basename "$script") passes shellcheck"
            else
                warn "$(basename "$script") has shellcheck warnings:"
                echo "$output" | head -20
            fi
        fi
    done
}

# Verify installed files (if installation was run)
verify_installation() {
    section "Installation Status"

    # Check if installed
    if [[ -f "$LOCAL_BIN/oneqode-theme-switch" ]]; then
        pass "Theme switcher installed"
        check_executable "$LOCAL_BIN/oneqode-theme-switch" "Switcher executable"
    else
        info "Theme switcher not installed (run install.sh first)"
    fi

    local ghostty_config="$HOME/.config/ghostty/config"
    if [[ -f "$ghostty_config" ]] && grep -q 'oneqode' "$ghostty_config"; then
        if grep -qE '^[[:space:]]*theme[[:space:]]*=[[:space:]]*(light:oneqode-light-glass,[[:space:]]*dark:oneqode-night-ride|dark:oneqode-night-ride,[[:space:]]*light:oneqode-light-glass)' "$ghostty_config"; then
            pass "Ghostty config uses native light/dark pairing"
        else
            fail "Ghostty config still uses the old oneqode-current include — daytime will not swap. Re-run: ./oneqode (Install → Ghostty) or lib/install-ghostty.sh"
        fi
        if grep -q 'oneqode-current' "$ghostty_config"; then
            fail "Ghostty config still includes themes/oneqode-current (pins a single palette)"
        fi
    fi

    local herdr_config="$HOME/.config/herdr/config.toml"
    if [[ -f "$herdr_config" ]] && grep -q 'BEGIN ONEQODE THEME' "$herdr_config"; then
        if grep -qE 'accent = "#(00b4c8|ff0080)"' "$herdr_config"; then
            pass "Herdr config has a OneQode palette"
        else
            fail "Herdr config has the OneQode marker but no OQ accent"
        fi
    fi

    if [[ -d "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.lightglass" ]]; then
        pass "Light Glass look-and-feel installed"
    else
        info "Light Glass not installed"
    fi

    if [[ -d "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.nightride" ]]; then
        pass "Night Ride look-and-feel installed"
    else
        info "Night Ride not installed"
    fi

    # Check timer status
    if systemctl --user is-enabled oneqode-theme-switcher.timer &>/dev/null; then
        pass "Theme switcher timer enabled"
    else
        info "Timer not enabled (run install.sh)"
    fi

    # Check watcher status
    if systemctl --user is-enabled oneqode-theme-watcher.service &>/dev/null; then
        pass "Theme watcher enabled (GUI fix)"
    else
        info "Theme watcher not enabled (run install.sh)"
    fi
}

# Verify theme apply tool
verify_theme_tools() {
    section "Theme Application Tools"

    local has_tool=false

    if command -v plasma-apply-lookandfeel &>/dev/null; then
        pass "plasma-apply-lookandfeel available"
        has_tool=true
    elif command -v lookandfeeltool &>/dev/null; then
        pass "lookandfeeltool available (fallback)"
        has_tool=true
    fi

    if ! $has_tool; then
        warn "No theme apply tool found"
        info "Themes can be applied manually via System Settings"
    fi

    check_command "kwriteconfig6" "kwriteconfig6 (KDE config writer)"
}

# Test switcher script (dry run)
test_switcher() {
    section "Switcher Script Test"

    local switcher="$SCRIPT_DIR/switcher/oneqode-theme-switch"

    if [[ ! -f "$switcher" ]]; then
        fail "Switcher script not found"
        return
    fi

    if [[ ! -x "$switcher" ]]; then
        chmod +x "$switcher"
        info "Made switcher executable"
    fi

    # Test --status
    if "$switcher" --status &>/dev/null; then
        pass "Switcher --status works"
    else
        warn "Switcher --status returned error (may be OK if not configured)"
    fi

    # Test --help
    if "$switcher" --help &>/dev/null; then
        pass "Switcher --help works"
    else
        fail "Switcher --help failed"
    fi
}

# Test theme application (if tools available)
test_theme_apply() {
    section "Theme Application Test"

    local tool=""
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        tool="plasma-apply-lookandfeel"
    elif command -v lookandfeeltool &>/dev/null; then
        tool="lookandfeeltool"
    fi

    if [[ -z "$tool" ]]; then
        info "No apply tool available, skipping application test"
        return
    fi

    # Only test if themes are installed
    if [[ ! -d "$LOCAL_SHARE/plasma/look-and-feel/org.oneqode.lightglass" ]]; then
        info "Themes not installed, skipping application test"
        return
    fi

    # Test applying Light Glass
    info "Testing Light Glass application..."
    if "$tool" -a org.oneqode.lightglass 2>/dev/null; then
        pass "Light Glass applied successfully"
    else
        warn "Light Glass application returned error"
    fi

    # Test applying Night Ride
    info "Testing Night Ride application..."
    if "$tool" -a org.oneqode.nightride 2>/dev/null; then
        pass "Night Ride applied successfully"
    else
        warn "Night Ride application returned error"
    fi

    # Restore Light Glass
    "$tool" -a org.oneqode.lightglass 2>/dev/null || true
}

# Check dependencies
verify_dependencies() {
    section "Dependencies"

    check_command "python3" "Python 3"
    check_command "rsync" "rsync"
    check_command "jq" "jq"

    # Check python-astral
    if python3 -c "import astral" 2>/dev/null; then
        pass "python-astral installed"
    else
        warn "python-astral not installed (required for solar mode)"
        info "Install with: sudo pacman -S python-astral"
    fi

    # Check Klassy
    if pacman -Qi klassy &>/dev/null || pacman -Qi klassy-bin &>/dev/null; then
        pass "Klassy installed"
    else
        warn "Klassy not installed (will use Breeze fallback)"
        info "Install with: yay -S klassy-bin"
    fi
}

# Verify the LIVE desktop config actually has the theme applied.
# Some Plasma 6.7 updates silently clear these keys from kdeglobals while leaving
# the look-and-feel selected, producing a half-applied (default-looking) desktop.
verify_applied_config() {
    section "Applied Desktop Config (live)"

    if ! command -v kreadconfig6 &>/dev/null; then
        warn "kreadconfig6 not available, skipping live config checks"
        return
    fi

    local lnf
    lnf="$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null)"
    if [[ "$lnf" != org.oneqode.* ]]; then
        info "Active look-and-feel is '${lnf:-none}' (not a OneQode theme); skipping applied-key checks"
        return
    fi

    local cs ws icons
    cs="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
    ws="$(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null)"
    icons="$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null)"

    [[ -n "$cs" ]]    && pass "kdeglobals ColorScheme set ($cs)"   || fail "kdeglobals ColorScheme empty — theme half-applied. Fix: plasma-apply-lookandfeel -a $lnf"
    [[ -n "$ws" ]]    && pass "kdeglobals widgetStyle set ($ws)"   || fail "kdeglobals widgetStyle empty — theme half-applied. Fix: plasma-apply-lookandfeel -a $lnf"
    [[ -n "$icons" ]] && pass "kdeglobals Icons theme set ($icons)" || fail "kdeglobals Icons theme empty — theme half-applied. Fix: plasma-apply-lookandfeel -a $lnf"

    # Day/night switching is dead if the timer has no future trigger.
    if systemctl --user is-enabled oneqode-theme-switcher.timer &>/dev/null; then
        local nr nm
        nr="$(systemctl --user show oneqode-theme-switcher.timer -p NextElapseUSecRealtime --value 2>/dev/null)"
        nm="$(systemctl --user show oneqode-theme-switcher.timer -p NextElapseUSecMonotonic --value 2>/dev/null)"
        if [[ -n "$nr" && "$nr" != "0" ]] || { [[ -n "$nm" && "$nm" != "0" && "$nm" != "infinity" ]]; }; then
            pass "Switcher timer has a scheduled next run"
        else
            fail "Switcher timer has no next trigger — day/night switching stalled. Fix: systemctl --user restart oneqode-theme-switcher.timer"
        fi
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}           Verification Summary         ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}Passed:${NC} $PASS"
    echo -e "${YELLOW}Warnings:${NC} $WARN"
    echo -e "${RED}Failed:${NC} $FAIL"
    echo ""

    if [[ $FAIL -eq 0 ]]; then
        if [[ $WARN -eq 0 ]]; then
            echo -e "${GREEN}All checks passed!${NC}"
        else
            echo -e "${YELLOW}Passed with warnings. Review warnings above.${NC}"
        fi
        return 0
    else
        echo -e "${RED}Some checks failed. Review the output above.${NC}"
        return 1
    fi
}

# Main
main() {
    echo ""
    echo -e "${BLUE}OneQode Linux Theme - Verification${NC}"
    echo -e "${BLUE}=================================${NC}"

    verify_repo_structure
    verify_json_files
    verify_systemd_units
    verify_shellcheck
    verify_dependencies
    verify_theme_tools
    verify_installation
    verify_applied_config
    test_switcher
    test_theme_apply

    print_summary
}

main "$@"
