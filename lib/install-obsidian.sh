#!/usr/bin/env bash
# Install Obsidian themes

install_obsidian() {
    info "Installing Obsidian themes..."

    local assets_dir="$ONEQODE_DIR/assets/obsidian"

    # Find Obsidian vaults with .obsidian folders (limit depth to avoid slow scans)
    local vaults=()
    # Check common locations first
    for dir in "$HOME/Documents" "$HOME/Obsidian" "$HOME"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' vault; do
                vaults+=("$vault")
            done < <(find "$dir" -maxdepth 4 -path "*/.obsidian/themes" -type d -print0 2>/dev/null)
        fi
    done
    # Remove duplicates
    local unique_vaults=()
    for v in "${vaults[@]}"; do
        local found=false
        for u in "${unique_vaults[@]}"; do
            [[ "$v" == "$u" ]] && found=true && break
        done
        $found || unique_vaults+=("$v")
    done
    vaults=("${unique_vaults[@]}")

    if [[ ${#vaults[@]} -eq 0 ]]; then
        warn "No Obsidian vaults found"
        warn "Create a vault in Obsidian first, then re-run this installer"
        return 1
    fi

    # Install to each vault
    for themes_dir in "${vaults[@]}"; do
        info "Installing to: $themes_dir"
        cp -r "$assets_dir/OneQode Night Ride" "$themes_dir/"
        cp -r "$assets_dir/OneQode Light Glass" "$themes_dir/"
    done

    success "Obsidian themes installed to ${#vaults[@]} vault(s)"
    info "Open Obsidian > Settings > Appearance > Themes to select OneQode themes"
}

uninstall_obsidian() {
    info "Removing Obsidian themes..."

    # Find vaults in common locations (limit depth to avoid slow scans)
    for dir in "$HOME/Documents" "$HOME/Obsidian" "$HOME"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' themes_dir; do
                rm -rf "$themes_dir/OneQode Night Ride"
                rm -rf "$themes_dir/OneQode Light Glass"
            done < <(find "$dir" -maxdepth 4 -path "*/.obsidian/themes" -type d -print0 2>/dev/null)
        fi
    done

    success "Obsidian themes removed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_obsidian
fi
