# Changelog

## v1.1.0 — 2026-06-21

### Added (experimental)

- **ONLYOFFICE Desktop Editors theming** (`assets/onlyoffice/`) — a Word-like
  editor with strong track-changes/DOCX fidelity, themed to match OneQode.
  `patch-builtin.py` re-tints ONLYOFFICE's built-in dark theme CSS to Night Ride
  (navy chrome + magenta/cyan accents) and brands the light theme with Light
  Glass teal; run with `sudo python3 patch-builtin.py` (re-run after app
  updates; `--revert` restores originals). ONLYOFFICE's custom-theme JSON loader
  silently ignores accent keys, so editing the built-in theme is the only way to
  get accents — `build-theme.py` + the `*.json` are kept as the documented
  (background-only) JSON approach. **Known limitation:** the desktop app runs
  under XWayland and mis-handles fractional scaling on KDE Wayland, so its UI
  renders oversized — a documented upstream bug with no clean fix yet. Not wired
  into the `oneqode` TUI or day/night switcher.
- **WPS Office day/night skins** (`assets/wps/`, `lib/install-wps.sh`) — drives
  WPS's built-in `2018white` / `2018white_dark` skins for a persistent dark
  chrome (WPS's integrity check discards custom skins). `build-skin.py` can
  generate a re-tinted OneQode palette. Standalone; not wired into the TUI.

### Fixed

- **Critical: Light theme caused 32% CPU usage on Plasma 6** — The Light Glass
  desktop theme was set to `name=breeze`, but Plasma 6 split the Breeze desktop
  theme into `breeze-light` and `breeze-dark`. The missing theme directory caused
  plasmashell's QML scene graph to enter an infinite re-render loop, burning an
  entire CPU core. Fixed by setting `name=breeze-light` in the Light Glass
  look-and-feel defaults.
- Fixed SPEC.md referencing `breeze` instead of `breeze-light` for the light
  theme's Plasma desktop style.
- Obsidian vault detection no longer does an unbounded `find` across the entire
  home directory. Uses known vault locations and a state file for fast status
  checks, with a 60-second timeout as a safety net.
- Firefox theme detection uses direct profile directory lookup instead of `find`.

### Changed

- Added troubleshooting section for high plasmashell CPU usage caused by the
  Plasma 6 theme name change.

### Added

- **Klassy window decoration presets** (`assets/klassy/`) with per-theme button
  colors, opacity, and behavior — distributed as `.klpw` preset files:
  - Light Glass: hover-reveal buttons with coral close, ice-cyan maximize,
    violet minimize, 85%/70% title bar opacity, window outline colorizes on
    button hover.
  - Night Ride: always-visible neon traffic light dots on active windows,
    neon pink/green/cyan hover overrides, 88%/65% opacity, neon pink window
    outline, window outline colorizes on button hover.
- Theme switcher imports and loads Klassy presets via `klassy-settings` on
  day/night transitions (direct `klassyrc` writes don't trigger Klassy reload).
- Firefox theme extensions (`.xpi`) and `userChrome-auto.css` for automatic
  Firefox theming.
- Obsidian install state tracking via `~/.local/state/oneqode/obsidian-installed`
  for faster status checks.
