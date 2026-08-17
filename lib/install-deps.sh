#!/usr/bin/env bash
# Install system dependencies

# Required packages
PACMAN_DEPS=(
    git
    rsync
    jq
    curl
    plasma-workspace
    python
    python-astral
    papirus-icon-theme
    inter-font
    ttf-jetbrains-mono-nerd
    inotify-tools
)

# Optional packages (nice to have)
OPTIONAL_DEPS=(
    gum  # For pretty TUI (AUR)
)

check_deps() {
    local missing=()

    for pkg in "${PACMAN_DEPS[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "${missing[*]}"
        return 1
    fi
    return 0
}

install_deps() {
    if [[ $(detect_desktop) == omarchy ]]; then
        info "Omarchy host — skipping Plasma package set"
        return 0
    fi

    info "Checking system dependencies..."

    local missing
    if missing=$(check_deps); then
        success "All dependencies installed"
        return 0
    fi

    info "Missing packages: $missing"

    read -rp "Install missing packages with pacman? [Y/n] " response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        warn "Skipping dependency installation"
        return 1
    fi

    # shellcheck disable=SC2086
    sudo pacman -S --needed --noconfirm $missing

    success "Dependencies installed"
}

install_klassy() {
    if ! has_cmd yay; then
        warn "yay not available, skipping Klassy installation"
        warn "Themes will fall back to Breeze decoration"
        return 0
    fi

    # Check if klassy is already installed
    if pacman -Qi klassy &>/dev/null || pacman -Qi klassy-bin &>/dev/null; then
        success "Klassy already installed"
        return 0
    fi

    info "Installing Klassy window decoration..."

    # Try klassy-bin first (precompiled, faster)
    if yay -Si klassy-bin &>/dev/null; then
        info "Installing klassy-bin (precompiled)..."
        if yay -S --noconfirm --needed klassy-bin; then
            success "klassy-bin installed"
            return 0
        fi
    fi

    # Fall back to klassy (compiled from source)
    if yay -Si klassy &>/dev/null; then
        info "Installing klassy (from source)..."
        if yay -S --noconfirm --needed klassy; then
            success "klassy installed"
            return 0
        fi
    fi

    warn "Could not install Klassy. Themes will use Breeze decoration."
}

install_gum() {
    if has_cmd gum; then
        return 0
    fi

    if ! has_cmd yay; then
        return 1
    fi

    info "Installing gum for better TUI..."
    yay -S --noconfirm --needed gum && success "gum installed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
    install_deps
    install_klassy
fi
