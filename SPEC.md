# OneQode KDE Theme Suite (Plasma 6 / Wayland) — Spec

## 0) Goal
Create a reproducible, GitHub-friendly KDE Plasma 6 theme suite for EndeavourOS (Arch) on Wayland, focused on:

- **OneQode Light Glass** (day / work-friendly light theme with tasteful translucency)
- **OneQode Night Ride** (night / synth-adjacent dark theme)
- **Automatic day/night switching** (solar or fixed-time fallback)
- **One-touch install** and **safe rollback** with zero Plasma session breakage
- **KDE6 / Plasma6-optimized packaging** with modern metadata
- Preference: **Klassy** for a premium, consistent look

This repo must be usable on a fresh machine by cloning and running a single installer.

---

## 1) Target Environment & Assumptions
- OS: **EndeavourOS / Arch Linux**
- Desktop: **KDE Plasma 6**, **Wayland**
- Installer assumes the user has:
  - `pacman`
  - `sudo`
  - `systemctl --user`
  - `yay` (AUR helper)
- Scripts MUST tolerate variations in available commands across Plasma versions by detecting tools at runtime.

---

## 2) Must-Have Outcomes

### 2.1 Deliverables
The repo MUST contain:

- `install.sh` (idempotent, user-scoped, safe)
- `uninstall.sh` (complete cleanup, disable timers, rollback where possible)
- `verify.sh` (runs checks, validates unit files, performs dry-run theme applies)
- `README.md` (install + verify + troubleshooting + rollback + update strategy)
- Theme assets:
  - Two KDE **Look-and-Feel** packages:
    - `org.oneqode.lightglass` (“OneQode Light Glass”)
    - `org.oneqode.nightride` (“OneQode Night Ride”)
  - Two KDE color schemes:
    - `OneQodeLightGlass.colors`
    - `OneQodeNightRide.colors`
  - Wallpapers (optional but strongly recommended):
    - `OneQode-Light-Glass.*`
    - `OneQode-Night-Ride.*`
- Switcher:
  - `switcher/oneqode-theme-switch` (script)
  - `switcher/oneqode-theme-switcher.service` (systemd user unit)
  - `switcher/oneqode-theme-switcher.timer` (systemd user timer)
  - `switcher/oneqode-theme-switcher.conf` (config file installed to `~/.config/oneqode/`)

### 2.2 Repo layout (exact)
```text
oneqode-kde-themes/
  install.sh
  uninstall.sh
  verify.sh
  README.md
  SPEC.md

  assets/
    color-schemes/
      OneQodeLightGlass.colors
      OneQodeNightRide.colors

    look-and-feel/
      org.oneqode.lightglass/
        metadata.json
        manifest.json
        contents/
          defaults
      org.oneqode.nightride/
        metadata.json
        manifest.json
        contents/
          defaults

    wallpapers/
      OneQode-Light-Glass.jpg
      OneQode-Night-Ride.jpg

  switcher/
    oneqode-theme-switch
    oneqode-theme-switcher.service
    oneqode-theme-switcher.timer
    oneqode-theme-switcher.conf
```

---

## 3) Non-Negotiables (do NOT break user session)

### 3.1 Forbidden actions
Installer MUST NOT:

- Modify `~/.config/plasma-org.kde.plasma.desktop-appletsrc`
- Modify or overwrite arbitrary Plasma config files unless:
  - it is narrowly scoped (e.g., `kwinrc` blur keys)
  - it is backed up with a timestamp
  - it can be reversed
- Hardcode KWin decoration plugin IDs that vary by machine/build
- Require logout/login to avoid errors; if logout/login improves appearance, document it but do not require it for “no errors”.

### 3.2 User-scoped installation only
All theme assets MUST be installed under:

- `~/.local/share/`
- `~/.config/`
- `~/.local/bin/`
- `~/.local/state/`

No system-wide installs, no root writes except `pacman` deps.

---

## 4) Dependencies & Installation Requirements

### 4.1 Package dependencies (pacman)
Installer MUST install (if missing):

- `git`, `rsync`, `jq`
- `plasma-workspace`
- `python`, `python-astral` (for sunrise/sunset switching)
- Fonts:
  - `ttf-inter`
  - `ttf-jetbrains-mono-nerd`
- Icons:
  - `papirus-icon-theme`
- Optional but nice:
  - `tree`, `shellcheck`

### 4.2 Klassy
Preference order:

1) Install `klassy-bin` via yay (preferred)
2) If unavailable, install `klassy` via yay
3) If both fail, proceed but:
   - warn clearly
   - fall back to Breeze style and document remediation steps

### 4.2.1 Klassy Decoration Configs

When Klassy is installed, the theme switcher copies the appropriate config to
`~/.config/klassy/klassyrc` on each theme transition.

Source files (raw configs for reference):
- `assets/klassy/klassyrc-light` — Light Glass decoration settings
- `assets/klassy/klassyrc-dark` — Night Ride decoration settings

Preset files (used by `klassy-settings` at runtime):
- `assets/klassy/OneQode_Light_Glass.klpw`
- `assets/klassy/OneQode_Night_Ride.klpw`

The theme switcher imports and loads presets via `klassy-settings --import-preset`
and `--load-windeco-preset`. Direct writes to `klassyrc` do NOT trigger Klassy
to reload — the `klassy-settings` tool is required.

Lookup order: `~/dev/oneqode-kde-themes/assets/klassy/` then
`/usr/share/oneqode-kde-themes/klassy/`.

Key design differences between variants:
- **Light Glass**: hover-reveal buttons (hidden normally), AccentNegativeClose
  colors, coral close / ice-cyan maximize / light-cyan minimize overrides,
  85% active / 70% inactive title bar opacity, accent color window outline.
- **Night Ride**: always-visible colored dots on active windows
  (AccentTrafficLights), neon pink close / neon green maximize / neon cyan
  minimize hover overrides, 88% active / 65% inactive opacity, custom neon
  pink window outline.

### 4.3 Apply theme command detection
Scripts MUST detect and use:

- `plasma-apply-lookandfeel` if available
- otherwise `lookandfeeltool` as fallback
- otherwise do nothing (warn, but do not fail hard)

### 4.4 Config writer detection
Use `kwriteconfig6` if available.  
If not available, do not attempt to set KWin config automatically; warn and document manual steps.

---

## 5) Glass / Transparency behavior
“Glass” MUST be enabled using stable compositor effects rather than fragile SVG theme hacking.

Installer should enable these KWin effects by writing keys to `~/.config/kwinrc` under `[Plugins]`:

- `blurEnabled=true`
- `translucencyEnabled=true`
- `contrastEnabled=true` (optional, for legibility)

After writing config, reconfigure KWin if possible:

- `qdbus org.kde.KWin /KWin reconfigure` (if `qdbus` exists)

---

## 6) Auto-switching (Day/Night)

### 6.1 Primary mode: solar
Solar mode uses `python-astral` to compute sunrise/sunset for configured lat/lon/tz.

Switcher MUST:

- compute whether current time is “day” or “night”
- only apply theme if it differs from last applied (state file)
- store last applied theme in:
  - `~/.local/state/oneqode/theme-state`

### 6.2 Fallback mode: fixed times
If astral fails, or if `MODE=fixed`, use:

- `DAY_START=07:30`
- `NIGHT_START=18:30`

### 6.3 systemd user timer
Switching must be driven by:

- a `oneshot` service calling `~/.local/bin/oneqode-theme-switch`
- a timer firing every 5 minutes (or similar)
- timer must be enabled immediately by `install.sh`

---

## 7) Theme packages (Look-and-Feel)

### 7.1 Package IDs
- Light: `org.oneqode.lightglass`
- Night: `org.oneqode.nightride`

### 7.2 metadata + manifest
Both packages MUST include `metadata.json` and `manifest.json` for Plasma 6 compatibility.

### 7.3 Defaults glue file
Each package MUST include `contents/defaults`.

Defaults must set:

- ColorScheme = `OneQodeLightGlass` / `OneQodeNightRide`
- `widgetStyle=klassy` (or fallback to Breeze if Klassy missing)
- Icons:
  - Light: `Papirus`
  - Night: `Papirus-Dark`
- Plasma theme can remain Breeze/Breeze Dark to reduce fragility:
  - Light: `breeze-light`
  - Night: `breeze-dark`

Do NOT force decoration plugin IDs.

---

## 8) Color scheme requirements
Two `.colors` files MUST exist and MUST be valid KDE color schemes:

- `assets/color-schemes/OneQodeLightGlass.colors`
- `assets/color-schemes/OneQodeNightRide.colors`

They should:

- be comfortable for long work sessions
- keep accent “ice cyan” vibes in Light Glass
- keep neon-adjacent accents in Night Ride without high glare

Initial baseline palettes should be included in the repo (even if later tuned).

---

## 9) Idempotency & Safety

### 9.1 install.sh
Installer must:

- be safe to run multiple times
- never duplicate lines in config
- back up modified configs:
  - `~/.config/kwinrc` -> `~/.config/kwinrc.bak.<timestamp>`
- install assets using rsync
- enable and start timer

### 9.2 uninstall.sh
Uninstaller must:

- disable timer + remove user units
- remove installed assets under `~/.local/share/...`
- remove `~/.local/bin/oneqode-theme-switch`
- remove optional state files
- attempt to restore latest `kwinrc` backup if available (or at minimum, undo blur/translucency keys)

---

## 10) Verification Harness
A `verify.sh` MUST exist. It should:

- print a clear checklist summary
- validate:
  - file existence and permissions
  - systemd unit syntax: `systemd-analyze --user verify ...` (if available)
  - switcher runs without error
  - theme apply command exists OR prints actionable warning
- optionally run `shellcheck` if installed (warn if not)
- must not require user interaction

---

## 11) README Requirements
README must include:

- Quick install steps
- Verify steps
- How to change lat/lon/tz and switch mode
- Troubleshooting:
  - theme not applying
  - blur not showing
  - Klassy missing
  - timer not firing
- Rollback / uninstall instructions
- How to update via git pull + rerun install
- Optional: how to publish GitHub releases + tags

---

## 12) Pre-seeded implementation details (DO NOT REINVENT)
Claude MUST implement the following baseline artifacts as the starting point.

### 12.1 install.sh baseline behavior
- Install pacman deps:
  - git rsync jq plasma-workspace python python-astral papirus-icon-theme ttf-inter ttf-jetbrains-mono-nerd
- Install Klassy via yay:
  - prefer klassy-bin, fallback klassy
- Copy assets to:
  - `~/.local/share/color-schemes/`
  - `~/.local/share/plasma/look-and-feel/`
  - `~/.local/share/wallpapers/OneQode/`
- Enable blur/translucency/contrast in kwinrc
- Apply Light Glass immediately
- Install switcher scripts + systemd units and enable timer

### 12.2 switcher baseline behavior
- Config at: `~/.config/oneqode/oneqode-theme-switcher.conf`
- State file at: `~/.local/state/oneqode/theme-state`
- Solar mode uses astral sunrise/sunset plus offset minutes

### 12.3 look-and-feel defaults baseline
Light defaults:
- ColorScheme=OneQodeLightGlass
- widgetStyle=klassy
- Icons=Papirus
- Plasma theme=breeze-light

Night defaults:
- ColorScheme=OneQodeNightRide
- widgetStyle=klassy
- Icons=Papirus-Dark
- Plasma theme=breeze-dark

### 12.4 baseline `.colors` content
Claude should seed `.colors` files based on an initial palette (ice cyan accents for Light; deep navy + neon accents for Night).  
They do not need to be perfect, but must be valid KDE color scheme files and readable for real work.

---

## 13) Definition of Done
This project is done when:

- `./install.sh` runs without error on target system
- `./verify.sh` passes (or prints only non-fatal warnings with remediation)
- Light Glass and Night Ride can be applied manually and by timer
- Uninstall cleans up and does not leave the system in a broken theme state
- Repo is clean, readable, and ready to push to GitHub
