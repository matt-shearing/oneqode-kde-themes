#!/usr/bin/env bash
# OneQode KDE Theme Suite - Uninstaller (Legacy Shim)
# ===================================================
# This script now calls the new TUI-based uninstaller.
# For the full experience, run: ./oneqode
#
# Usage:
#   ./uninstall.sh      - Uninstall all components
#   ./oneqode           - Launch interactive TUI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the new oneqode script with uninstall command
exec "$SCRIPT_DIR/oneqode" uninstall
