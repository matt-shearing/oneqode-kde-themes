#!/usr/bin/env bash
# Post-boot: apply the time-of-day OneQode theme if we are still on the
# OQ pair or the stock Tokyo Night default.
exec "${XDG_BIN_HOME:-$HOME/.local/bin}/omarchy-oq-auto-theme"
