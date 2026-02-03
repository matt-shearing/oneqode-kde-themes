#!/usr/bin/env bash
# Install Obsidian themes

install_obsidian() {
    info "Installing Obsidian themes..."

    local assets_dir="$ONEQODE_DIR/assets/obsidian"

    # Find Obsidian vaults with .obsidian folders
    local vaults=()
    while IFS= read -r -d '' vault; do
        vaults+=("$vault")
    done < <(find "$HOME" -path "*/.obsidian/themes" -type d -print0 2>/dev/null)

    if [[ ${#vaults[@]} -eq 0 ]]; then
        warn "No Obsidian vaults found"
        warn "Create a vault in Obsidian first, then re-run this installer"
        return 1
    fi

    # Install to each vault
    for themes_dir in "${vaults[@]}"; do
        info "Installing to: $themes_dir"
        cp -r "$assets_dir/OneQode-Night-Ride" "$themes_dir/"
        cp -r "$assets_dir/OneQode-Light-Glass" "$themes_dir/"
    done

    success "Obsidian themes installed to ${#vaults[@]} vault(s)"
    info "Open Obsidian > Settings > Appearance > Themes to select OneQode themes"
}

uninstall_obsidian() {
    info "Removing Obsidian themes..."

    # Find all vaults and remove themes
    while IFS= read -r -d '' themes_dir; do
        rm -rf "$themes_dir/OneQode-Night-Ride"
        rm -rf "$themes_dir/OneQode-Light-Glass"
    done < <(find "$HOME" -path "*/.obsidian/themes" -type d -print0 2>/dev/null)

    success "Obsidian themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_obsidian
fi
