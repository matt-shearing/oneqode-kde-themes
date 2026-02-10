# Changelog

## Unreleased

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

- Firefox theme extensions (`.xpi`) and `userChrome-auto.css` for automatic
  Firefox theming.
- Obsidian install state tracking via `~/.local/state/oneqode/obsidian-installed`
  for faster status checks.
