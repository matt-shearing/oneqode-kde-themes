# OneQode KDE Theme Suite

A polished KDE Plasma 6 theme suite for EndeavourOS/Arch Linux on Wayland, featuring:

- **OneQode Light Glass** - A light, glass-inspired theme with ice cyan accents for comfortable daytime work
- **OneQode Night Ride** - A dark, synthwave-inspired theme with neon accents for nighttime coding
- **Automatic day/night switching** - Solar-based or fixed-time scheduling via systemd timer

## Quick Install

```bash
git clone https://github.com/matt-shearing/oneqode-kde-themes.git
cd oneqode-kde-themes
chmod +x install.sh
./install.sh
```

The installer will:
1. Install required packages via pacman (fonts, python-astral, inotify-tools, etc.)
2. Install Klassy window decoration via yay (with Breeze fallback)
3. Install color schemes and look-and-feel packages to `~/.local/share/`
4. Enable KWin blur/translucency/contrast effects
5. Install and enable the automatic theme switcher (runs every 5 minutes)
6. Install and enable the theme watcher (ensures Klassy works with GUI theme selection)
7. Apply the Light Glass theme immediately

**Important:** Log out and back in after installation for all changes to take effect.

## What's Included

Each theme sets:

| Component | Included | Notes |
|-----------|----------|-------|
| Color scheme | Yes | Custom OneQode colors |
| Wallpaper | Yes | 4K backgrounds |
| Window decoration | Yes | Klassy (Breeze fallback) |
| Application style | Yes | Klassy (Breeze fallback) |
| Plasma style | Yes | Breeze / Breeze Dark |
| Icons | Yes | Papirus / Papirus-Dark |
| Fonts | Yes | Inter + JetBrains Mono Nerd |
| Cursors | No | Uses your existing cursor theme |
| Splash screen | No | Uses your existing splash |
| Login screen (SDDM) | No | Uses your existing SDDM theme |

The themes focus on color consistency and blur effects rather than replacing every system component.

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

### Manual Theme Switching

```bash
# Force light theme
oneqode-theme-switch --force-day

# Force dark theme
oneqode-theme-switch --force-night

# Check current status
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

The installer is idempotent and preserves your configuration.

## File Locations

| Component | Location |
|-----------|----------|
| Color schemes | `~/.local/share/color-schemes/` |
| Look-and-feel | `~/.local/share/plasma/look-and-feel/` |
| Wallpapers | `~/.local/share/wallpapers/OneQode/` |
| Switcher script | `~/.local/bin/oneqode-theme-switch` |
| Watcher script | `~/.local/bin/oneqode-theme-watcher` |
| Configuration | `~/.config/oneqode/oneqode-theme-switcher.conf` |
| State file | `~/.local/state/oneqode/theme-state` |
| Switcher logs | `~/.local/state/oneqode/theme-switch.log` |
| Watcher logs | `~/.local/state/oneqode/theme-watcher.log` |
| Systemd units | `~/.config/systemd/user/` |

## Publishing to GitHub

1. Create a new repository on GitHub

2. Initialize and push:
   ```bash
   cd oneqode-kde-themes
   git init
   git add .
   git commit -m "Initial release: OneQode KDE Theme Suite v1.0.0"
   git branch -M main
   git remote add origin git@github.com:matt-shearing/oneqode-kde-themes.git
   git push -u origin main
   ```

3. Create a release:
   ```bash
   git tag -a v1.0.0 -m "Version 1.0.0"
   git push origin v1.0.0
   ```

4. On GitHub, go to Releases and create a new release from the tag.

## License

MIT License - See LICENSE file for details.

## Credits

- [Klassy](https://github.com/paulmcauley/klassy) - Window decoration
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) - Icon theme
- [python-astral](https://github.com/sffjunkie/astral) - Solar calculations
- [Inter](https://rsms.me/inter/) - UI font
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) - Monospace font
