# OneQode KDE Theme Suite

A polished KDE Plasma 6 theme suite for EndeavourOS/Arch Linux on Wayland, featuring:

- **OneQode Light Glass** - A light, glass-inspired theme with ice cyan accents for comfortable daytime work
- **OneQode Night Ride** - A dark, synthwave-inspired theme with neon accents for nighttime coding
- **Automatic day/night switching** - Solar-based or fixed-time scheduling via systemd timer

## Quick Install

```bash
git clone https://github.com/matt-shearing/oneqode-kde-themes.git
cd oneqode-kde-themes
./oneqode
```

This launches an interactive TUI where you can:
- Install all components or select specific ones
- Switch themes manually
- Configure settings
- View installation status

### Alternative: Command-line install

```bash
./oneqode install    # Install everything
./install.sh         # Same as above (legacy)
```

**Important:** Log out and back in after installation for all changes to take effect.

### Optional: Install `gum` for a prettier TUI

```bash
yay -S gum
```

Without gum, the TUI falls back to basic bash menus.

## What's Included

Each theme sets:

| Component | Notes |
|-----------|-------|
| Color scheme | Custom OneQode colors |
| Wallpaper | 4K backgrounds |
| Window decoration | Klassy (Breeze fallback) |
| Application style | Klassy (Breeze fallback) |
| Plasma style | Breeze Light / Breeze Dark |
| Icons | Papirus / Papirus-Dark |
| Fonts | Inter + JetBrains Mono Nerd |
| Cursors | Bibata Modern Ice |
| Splash screen | Minimal branded KSplash |
| Login screen (SDDM) | Breeze + OneQode background |
| GTK3/4 | Accent colors, scrollbars, libadwaita integration (auto-updates via KDE color sync) |
| Konsole | Matching terminal colors with transparency |
| Yakuake | Themed via Konsole profiles (auto-applied via DBus) |
| Ghostty | Matching terminal colors with transparency |
| Herdr | Agent-workspace TUI chrome (Light Glass / Night Ride, switched with the desktop) |
| Firefox | Browser chrome + internal pages via userChrome/userContent CSS (auto light/dark) |
| Zed | Matching editor theme (follows system) |
| Obsidian | Vault themes for both variants |
| Typora | Matching markdown editor themes |
| Mattermost | Custom sidebar/UI color schemes (manual import) |
| Opera | Follows system theme; color reference provided for Stylus CSS |

The themes provide a cohesive experience from login to desktop, including terminals, browsers, and editors.

### Experimental: office suites

Two office editors have OneQode theming under `assets/`, kept **standalone** —
they are not yet wired into the `oneqode` TUI or the day/night switcher:

- **ONLYOFFICE Desktop Editors** (`assets/onlyoffice/`) — `patch-builtin.py`
  re-tints ONLYOFFICE's built-in dark theme to Night Ride (and brands the light
  theme with Light Glass teal). Run `sudo python3 assets/onlyoffice/patch-builtin.py`
  (re-run after app updates; `--revert` restores originals). Note: the desktop
  app runs under XWayland and mis-scales its UI on KDE Wayland — a known upstream
  bug with no clean fix yet.
- **WPS Office** (`assets/wps/`, `lib/install-wps.sh`) — drives WPS's built-in
  light/dark skins for a persistent dark chrome.

## Verification

Run the verification script to check your installation:

```bash
./verify.sh
```

This checks:
- All required files exist
- JSON and systemd unit syntax is valid
- Theme apply tools are available
- Switcher script runs correctly
- Shell scripts pass shellcheck (if installed)

## Configuration

### Theme Switcher

> **Important:** Disable KDE's built-in "Switch to Dark Mode at Night" toggle in System Settings → Colors & Themes → Global Theme. The OneQode switcher handles day/night transitions itself — including color scheme, wallpaper, Klassy presets, terminal themes, and SDDM background. Running both will cause conflicts where each system fights to apply different settings.

Edit the switcher configuration:

```bash
nano ~/.config/oneqode/oneqode-theme-switcher.conf
```

Configuration options:

```ini
# Switching mode: "solar" or "fixed"
MODE=solar

# Location for solar mode
LATITUDE=-33.8688
LONGITUDE=151.2093
TIMEZONE=Australia/Sydney

# Fixed-time fallback (HH:MM, 24-hour)
DAY_START=07:30
NIGHT_START=18:30

# Offset after sunrise/sunset (minutes)
SUNRISE_OFFSET=0
SUNSET_OFFSET=0
```

Find your coordinates:
- [latlong.net](https://www.latlong.net/)
- [Google Maps](https://maps.google.com) - right-click any location

### Firefox

The installer sets up `userChrome.css` (browser UI) and `userContent.css` (internal pages like new tab, settings, addons) with auto light/dark switching via `prefers-color-scheme`.

After installing, you must enable custom stylesheets in Firefox:

1. Open `about:config`
2. Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`
3. Restart Firefox

Static variants (force light or dark) are also available in `~/.mozilla/firefox/<profile>/chrome/`.

### GTK3/4

GTK overrides set accent colors, selection highlights, scrollbar styling, and libadwaita integration for GTK apps running under KDE. Colors are referenced from KDE's color sync (`colors.css`), so they **auto-update when you switch themes** — no restart needed for GTK3 apps. GTK4/libadwaita apps may need a restart.

Chromium-based browsers in "Use GTK+" appearance mode also pick up the accent colors.

### Zed Editor

Zed themes are configured to follow the system theme automatically:

```json
"theme": {
  "mode": "system",
  "light": "OneQode Light Glass",
  "dark": "OneQode Night Ride"
}
```

When KDE switches between light/dark modes, Zed will follow automatically. You can also select themes manually via the Zed Command Palette → "theme selector: toggle".

### Herdr

Herdr has no user-named theme files — only built-in names plus a `[theme.custom]` override table. OneQode ships two palettes (`assets/herdr/oneqode-light-glass.toml` and `oneqode-night-ride.toml`) and writes the active one into `~/.config/herdr/config.toml`. The day/night switcher swaps the block and runs `herdr server reload-config`.

Don't set `theme.name = "terminal"` if you want the OneQode chrome. That mode maps the host terminal ANSI palette onto Herdr's UI and looks wrong once Ghostty goes Light Glass.

### Obsidian

Themes are installed to all detected vaults. Select "OneQode Light Glass" or "OneQode Night Ride" in Obsidian → Settings → Appearance → Themes.

### Typora

Themes are installed to `~/.config/Typora/themes/`. Select them via Typora → Themes menu.

### Mattermost

Mattermost themes require manual import: Settings → Display → Theme → Custom Theme, then paste the contents of the JSON files from `assets/mattermost/`.

### Terminal Transparency

Configure Ghostty transparency via the TUI:

```bash
./oneqode
# Select "Configure" → "Terminal Transparency"
```

Or edit directly:

```bash
# Light Glass (default: 0.95)
nano ~/.config/ghostty/themes/oneqode-light-glass

# Night Ride (default: 0.88)
nano ~/.config/ghostty/themes/oneqode-night-ride
```

Values range from 0.0 (fully transparent) to 1.0 (opaque). After editing, reload Ghostty from the TUI or with:

```bash
busctl --user call com.mitchellh.ghostty /com/mitchellh/ghostty \
    org.gtk.Actions Activate sava{sv} reload-config 0 0
```

Ghostty is configured with a light/dark theme pair (`theme = light:oneqode-light-glass,dark:oneqode-night-ride`) so it follows the desktop appearance. Don't include `themes/oneqode-current` — that pins a single palette and the gtk-single-instance daemon will not swap at sunrise.

### Manual Theme Switching

```bash
# Via TUI
./oneqode

# Via CLI
./oneqode switch day      # Light Glass
./oneqode switch night    # Night Ride
./oneqode switch          # Auto (solar-based)
./oneqode status          # Check status

# Or directly via the switcher script
oneqode-theme-switch --force-day
oneqode-theme-switch --force-night
oneqode-theme-switch --status
```

### Timer Management

```bash
# Check timer status
systemctl --user status oneqode-theme-switcher.timer

# Manually trigger a switch
systemctl --user start oneqode-theme-switcher.service

# View logs
journalctl --user -u oneqode-theme-switcher.service

# Disable automatic switching
systemctl --user disable --now oneqode-theme-switcher.timer
```

### Theme Watcher

The theme watcher is a background service that monitors for GUI theme changes (via System Settings → Global Theme) and ensures Klassy window decorations are applied. This works around a KDE limitation where `plasma-apply-lookandfeel` doesn't reliably apply all theme settings.

```bash
# Check watcher status
systemctl --user status oneqode-theme-watcher.service

# View watcher logs
cat ~/.local/state/oneqode/theme-watcher.log

# Restart watcher if needed
systemctl --user restart oneqode-theme-watcher.service
```

## Troubleshooting

### Theme flickering or partially applied

If the theme seems to switch back and forth, or you get a mix of light/dark elements:

1. Make sure KDE's built-in dark mode scheduling is **disabled**:
   - System Settings → Colors & Themes → Global Theme → uncheck "Switch to Dark Mode at Night"

2. The OneQode switcher manages the full theme stack (colors, wallpaper, Klassy, terminals, SDDM). KDE's toggle only switches the color scheme preference, so running both causes race conditions where settings get partially overwritten.

### Theme not applying

1. Check if the apply tool exists:
   ```bash
   which plasma-apply-lookandfeel || which lookandfeeltool
   ```

2. Try applying manually:
   ```bash
   plasma-apply-lookandfeel -a org.oneqode.lightglass
   ```

3. Check if the theme is installed:
   ```bash
   ls ~/.local/share/plasma/look-and-feel/
   ```

4. Log out and back in, then try again.

### Blur not showing

1. Verify KWin effects are enabled:
   ```bash
   grep -E "(blur|translucency|contrast)Enabled" ~/.config/kwinrc
   ```

2. Manually enable via System Settings:
   - System Settings → Window Management → Desktop Effects
   - Enable "Blur" and "Translucency"

3. Reconfigure KWin:
   ```bash
   qdbus6 org.kde.KWin /KWin reconfigure
   ```

### High CPU usage from plasmashell

If plasmashell is consuming 30%+ CPU after applying the light theme:

1. This was caused by the light theme setting `name=breeze` as the Plasma desktop theme,
   but Plasma 6 renamed it to `breeze-light`. The missing theme causes an infinite
   re-render loop in the QML scene graph.

2. Fix: update the theme and restart plasmashell:
   ```bash
   kwriteconfig6 --file plasmarc --group Theme --key name breeze-light
   kquitapp6 plasmashell && kstart plasmashell
   ```

3. If you installed before this fix, pull the latest version and reinstall:
   ```bash
   git pull && ./oneqode install
   ```

### Klassy not available

If Klassy installation failed:

```bash
# Try installing klassy-bin (precompiled)
yay -S klassy-bin

# Or compile from source
yay -S klassy
```

If Klassy is unavailable, themes will use Breeze window decorations.

### Klassy not applied after theme switch

If Klassy is installed but not being applied:

1. The theme switcher should automatically ensure Klassy is set, but if not:
   ```bash
   # Manually set Klassy decorations
   kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.klassy
   kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Klassy
   dbus-send --type=signal --dest=org.kde.KWin /KWin org.kde.KWin.reloadConfig
   ```

2. Or set via System Settings:
   - System Settings → Colors & Themes → Window Decorations → Klassy
   - System Settings → Colors & Themes → Application Style → Klassy

Your Klassy customizations (button layout, transparency, etc.) are stored separately in `~/.config/klassy/klassyrc` and should be preserved across theme switches.

### Timer not firing

1. Check timer status:
   ```bash
   systemctl --user status oneqode-theme-switcher.timer
   ```

2. Check for errors:
   ```bash
   journalctl --user -u oneqode-theme-switcher --since "1 hour ago"
   ```

3. Re-enable timer:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now oneqode-theme-switcher.timer
   ```

### Solar mode not working

1. Verify python-astral is installed:
   ```bash
   python3 -c "import astral; print('OK')"
   ```

2. Check your timezone:
   ```bash
   timedatectl status
   ```

3. Test with fixed mode:
   ```bash
   # In ~/.config/oneqode/oneqode-theme-switcher.conf
   MODE=fixed
   ```

## Uninstall

```bash
./uninstall.sh
```

This will:
- Disable and remove the systemd timer
- Remove all theme assets from `~/.local/share/`
- Remove the switcher script
- Optionally remove configuration and restore kwinrc backup
- Apply the default Breeze theme

**Note:** Installed packages (python-astral, klassy, etc.) are not removed automatically.

## Update

To update to the latest version:

```bash
cd oneqode-kde-themes
git pull
./install.sh
```

The installer is idempotent and preserves your configuration. The TUI,
switcher, and watcher are symlinked into `~/.local/bin`, so a `git pull`
is enough for script changes; re-run install when new components land
(Ghostty pairing, Herdr palettes, etc.).

## File Locations

**Installed files:**

| Component | Location |
|-----------|----------|
| Color schemes | `~/.local/share/color-schemes/` |
| Look-and-feel | `~/.local/share/plasma/look-and-feel/` |
| Wallpapers | `~/.local/share/wallpapers/OneQode/` |
| Konsole themes | `~/.local/share/konsole/` |
| Ghostty themes | `~/.config/ghostty/themes/` |
| Herdr themes | `~/.config/herdr/themes/` + `~/.config/herdr/config.toml` |
| Firefox CSS | `~/.mozilla/firefox/<profile>/chrome/` |
| GTK3 overrides | `~/.config/gtk-3.0/gtk.css` |
| GTK4 overrides | `~/.config/gtk-4.0/gtk.css` |
| Zed themes | `~/.config/zed/themes/` |
| Obsidian themes | `<vault>/.obsidian/themes/` |
| Typora themes | `~/.config/Typora/themes/` |
| Cursors | `~/.local/share/icons/Bibata-Modern-Ice/` |
| Switcher script | `~/.local/bin/oneqode-theme-switch` |
| Watcher script | `~/.local/bin/oneqode-theme-watcher` |
| Configuration | `~/.config/oneqode/oneqode-theme-switcher.conf` |
| State file | `~/.local/state/oneqode/theme-state` |
| Systemd units | `~/.config/systemd/user/` |

**Repository structure:**

```
oneqode-kde-themes/
├── oneqode              # Main TUI entry point
├── install.sh           # Legacy installer (calls oneqode)
├── uninstall.sh         # Legacy uninstaller (calls oneqode)
├── verify.sh            # Verification script
├── lib/                 # Modular install scripts
│   ├── common.sh
│   ├── install-colors.sh
│   ├── install-lookandfeel.sh
│   ├── install-wallpapers.sh
│   ├── install-cursors.sh
│   ├── install-konsole.sh
│   ├── install-ghostty.sh
│   ├── install-herdr.sh
│   ├── install-firefox.sh
│   ├── install-gtk.sh
│   ├── install-zed.sh
│   ├── install-obsidian.sh
│   ├── install-typora.sh
│   ├── install-switcher.sh
│   ├── install-sddm.sh
│   └── install-deps.sh
├── assets/              # Theme assets
│   ├── color-schemes/   # KDE color schemes
│   ├── firefox/         # userChrome/userContent CSS + XPI extensions
│   ├── ghostty/         # Terminal themes
│   ├── herdr/           # Agent-workspace TUI palettes
│   ├── gtk/             # GTK3/4 CSS overrides
│   ├── klassy/          # Window decoration presets
│   ├── konsole/         # Terminal color schemes
│   ├── look-and-feel/   # KDE look-and-feel packages
│   ├── mattermost/      # Chat client themes (manual import)
│   ├── obsidian/        # Vault themes
│   ├── opera/           # Theming guide + color reference
│   ├── typora/          # Markdown editor themes
│   ├── wallpapers/      # 4K backgrounds
│   └── zed/             # Editor theme
├── switcher/            # Theme switcher scripts
└── sddm/               # SDDM configuration
```

## License

MIT License - See LICENSE file for details.

## Credits

- [Klassy](https://github.com/paulmcauley/klassy) - Window decoration
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) - Icon theme
- [python-astral](https://github.com/sffjunkie/astral) - Solar calculations
- [Inter](https://rsms.me/inter/) - UI font
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) - Monospace font
