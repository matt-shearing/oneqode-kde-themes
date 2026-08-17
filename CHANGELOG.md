# Changelog

## Unreleased

### Added

- **Docs rebranded to OneQode Linux Theme** — README, landing page
  (`docs/index.html`), spec, feature plan, verify/uninstall banners.

- **Omarchy desktop themes** — Light Glass / Night Ride as
  `omarchy-oq-light-glass` and `omarchy-oq-night-ride`, with a solar
  systemd timer (`omarchy-oq-auto-theme`) that shares
  `~/.config/oneqode/oneqode-theme-switcher.conf` with the KDE switcher.
  `./oneqode install` detects KDE vs Omarchy and installs the matching
  desktop half; Herdr, Grok Build, Ghostty, and the other app themes
  stay shared.

- **Herdr sidebar contrast + Grok Build auto-theme.** Night Ride sidebar
  titles/subtitles are explicit Light Glass / Night Ride inks (no more
  Tokyo Night muted grey on `#191c2a`). `apply-theme.py` also writes
  `[ui].theme` in `~/.grok/config.toml` (`grokday` / `groknight`).

- **Keychron RGB day/night hook** (`assets/keychron/`, `oneqode-keychron`).
  Same idea as Omarchy's `omarchy-theme-set-keyboard` (`qmk_hid via`):
  set RGB matrix effect + HSV over the Keychron Launcher HID protocol.
  Default effect is Reactive Multi-Wide (fan-out / hot zones from the
  key you hit) in Light Glass ice cyan or Night Ride magenta. Covers
  the Ultra-Link 8K 2.4 GHz dongle wrappers as well as wired FF60.
  Needs a one-time udev rule so hidraw is not root-only — that is also
  why Keychron Launcher in Opera cannot see the keyboard today.

- **Herdr Light Glass / Night Ride themes** with day/night auto-switch.
  Herdr has no user-named theme files, so the palettes live as
  `[theme]` + `[theme.custom]` fragments (`assets/herdr/`). The installer
  writes the matching variant into `~/.config/herdr/config.toml` and the
  switcher swaps it on look-and-feel change, then runs
  `herdr server reload-config`. `name = "terminal"` was picking up Ghostty's
  ANSI map and looking wrong once the terminal went Light Glass.

### Changed

- Switcher and watcher installs are now symlinks into the repo, so a
  `git pull` on another machine is enough for the next timer tick to pick
  up script changes. New components (Ghostty pairing, Herdr palettes)
  still need a re-run of `./install.sh`.

### Fixed

- **Light Glass: white/grey (and ice-cyan) text vanished in Herdr and
  Claude Code.** The light Ghostty palette used `#eee8d5` / `#ffffff` as
  ANSI white — TUIs treat those as *foreground*, so they disappeared on
  `#fafcff`. Ice cyan `#00b4c8` is only ~2.3:1 on the panel. Darkened
  palette 7/15 and the bright/accent colours, set `minimum-contrast = 4.5`
  so leftover truecolor greys get lifted, export `COLORFGBG` so
  `theme=auto` apps classify the terminal correctly, and have the
  switcher pin Claude Code to `light`/`dark` (auto-detect fails inside
  Herdr). Herdr Light Glass overlays/accent were the same washed-out
  greys and are now WCAG-AA.

- **Light Glass TUI colours rebalanced after over-darkening.** The
  contrast fix above pushed Ghostty ANSI 6/9–14 and Herdr
  accent/mauve/green/blue to near-ink, so Herdr chrome and Claude Code
  looked monochrome. Brand hues (ice cyan `#00b4c8`, teal `#2aa198`,
  solarized yellow/blue/magenta) are restored; palette 7/15 stay
  readable mid/dark ink. `minimum-contrast` is 1.5 so Herdr status
  dots (idle green / working gold / blocked coral / done blue) stay
  coloured instead of being lifted to black.

- **Ghostty stayed on Night Ride after the daytime switch.** The switcher only
  retargeted the `themes/oneqode-current` symlink, and Ghostty's
  `gtk-single-instance` daemon never reloads on a symlink flip — new windows
  inherit the already-loaded (night) palette. SIGUSR1 was also dropped earlier
  because it crashed Ghostty. Installer and switcher now write
  `theme = light:oneqode-light-glass,dark:oneqode-night-ride` so Ghostty follows
  the desktop appearance, drop the old `config-file` include (it loaded *after*
  `theme =` and pinned a single palette), and reload via the official GTK
  `reload-config` D-Bus action.

## v1.2.0 — 2026-07-16

### Fixed

- **Day/night switching could silently stop after a reboot or system update.**
  The systemd timer used `OnUnitActiveSec=5min`, which re-arms from the switcher
  service's *last activation*. If the first post-boot trigger was lost — e.g. a
  `systemctl daemon-reload` during a package upgrade consuming the pending
  trigger — the timer never re-armed and auto-switching stalled with
  `Trigger: n/a`, sometimes for days. Switched to a wall-clock `OnCalendar=*:0/5`
  schedule (kept `OnBootSec=1min` for a prompt first run); wall-clock triggers are
  computed from the clock and re-arm reliably across daemon-reloads and missed
  runs.
- **Plasma updates can drop applied theme keys, leaving a half-applied desktop.**
  Some Plasma 6.7 updates cleared `ColorScheme`, `widgetStyle`, and the `[Icons]`
  theme from `kdeglobals` while leaving the look-and-feel *selected*, so the
  desktop rendered with default colours/style/icons. `verify.sh` now checks these
  live keys (and that the switcher timer has a scheduled next run) and prints the
  one-line re-apply fix when they're missing.

### Changed

- `lib/install-switcher.sh` now restarts the timer after enabling it, so
  reinstalls and upgrades always leave it with a fresh, scheduled trigger rather
  than inheriting a stale/elapsed state.
- Bumped look-and-feel package version to **1.2.0** (metadata was still `1.0.0`
  despite the `v1.1.0` tag).

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
