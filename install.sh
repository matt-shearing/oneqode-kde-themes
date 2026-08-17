#!/usr/bin/env bash
# OneQode Linux Theme - Installer (Legacy Shim)
# =================================================
# This script now calls the new TUI-based installer.
# For the full experience, run: ./oneqode
#
# Usage:
#   ./install.sh        - Install all components (non-interactive)
#   ./oneqode           - Launch interactive TUI
#   ./oneqode install   - Same as ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the new oneqode script with install command
exec "$SCRIPT_DIR/oneqode" install
