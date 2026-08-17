# OneQode KDE Themes — Feature Plan

> Reference document for planned enhancements. Updated Feb 2026.

---

## Current State Summary

### Fully Implemented
| Component | Assets | Installer | Switcher | Notes |
|-----------|--------|-----------|----------|-------|
| KDE Color Schemes | `assets/color-schemes/` (2) | `install-colors.sh` | `plasma-apply-colorscheme -a` | Accent-derived colors propagated correctly |
| Look & Feel | `assets/look-and-feel/` (2) | `install-lookandfeel.sh` | `plasma-apply-lookandfeel` | Splash, defaults, metadata |
| Klassy Decoration | `assets/klassy/` (2 presets + 2 configs) | via switcher | `klassy-settings --import/--load` | Presets + fast-path check |
| Wallpapers | `assets/wallpapers/` (2 4K JPGs) | `install-wallpapers.sh` | via look-and-feel | — |
| Konsole | `assets/konsole/` (2 colorschemes) | `install-konsole.sh` | `update_konsole_theme()` + DBus | Full 16-color + opacity 0.92 + cursor |
| Ghostty | `assets/ghostty/` (2 themes) | `install-ghostty.sh` | native `theme = light:…,dark:…` + D-Bus `reload-config` | Follows system appearance; no USR1 |
| Herdr | `assets/herdr/` (2 TOML palettes) | `install-herdr.sh` | `update_herdr_theme()` + `herdr server reload-config` | `[theme.custom]` override; Herdr has no user-named themes |
| Firefox (chrome) | `assets/firefox/` (3 CSS + XPIs) | `install-firefox.sh` | `update_firefox_theme()` | Auto-switching via `prefers-color-scheme` |
| Firefox (content) | `assets/firefox/` (3 userContent CSS) | `install-firefox.sh` | `update_firefox_theme()` | about:newtab, preferences, addons, error pages |
| GTK3/4 Overrides | `assets/gtk/` (gtk3.css + gtk4.css) | `install-gtk.sh` | Auto (KDE color sync) | Accent, scrollbar, libadwaita, Chromium .chromium class |
| SDDM | `sddm/10-oneqode.conf` | `install-sddm.sh` (sudo) | `update_sddm_background()` | Breeze theme + OneQode wallpaper |
| Cursors | Downloaded at install | `install-cursors.sh` | via look-and-feel defaults | Bibata-Modern-Ice v2.0.6 |
| Zed Editor | `assets/zed/oneqode.json` | `install-zed.sh` | System mode (auto) | — |
| Typora | `assets/typora/` (2 CSS) | `install-typora.sh` | No switcher (manual) | — |
| Obsidian | `assets/obsidian/` (2 themes) | `install-obsidian.sh` | No switcher integration | — |
| Mattermost | `assets/mattermost/` (2 JSON) | `install-mattermost.sh` | `update_mattermost_theme()` | Pushed to server via API (token from app cookie); switches all teams live |
| Fastfetch | `assets/fastfetch/` (2 jsonc + logo) | `install-fastfetch.sh` | `update_fastfetch_theme()` | OQ ASCII logo, theme-accent colors; symlink to active variant |
| Theme Switcher | `switcher/` (script + tray + systemd) | `install-switcher.sh` | — | Solar or fixed-time auto-switch |

### Not Yet Implemented
| Component | Priority | Notes |
|-----------|----------|-------|
| Kvantum theme | Medium | Deeper Qt widget styling beyond Klassy |
| Vivaldi custom CSS | Medium | Only Chromium browser with full CSS injection support |
| Chrome/Brave theme extensions | Low | Static manifest-only themes, no auto-switch |

---

## Phase 1 — Firefox userContent.css (internal pages)

**Goal**: Theme Firefox's internal pages (`about:newtab`, `about:preferences`, `about:addons`, `about:privatebrowsing`, etc.) to match the Light Glass / Night Ride aesthetic.

**Approach**: Single auto-switching file using `@media (prefers-color-scheme)`, same pattern as `userChrome-auto.css`.

**Key targets**:
- `about:newtab` / `about:home` — new tab page background, search bar, top sites, highlights
- `about:preferences` — settings page backgrounds, inputs, toggles, category sidebar
- `about:addons` — extension manager cards, headers, sidebar
- `about:privatebrowsing` — private window landing page
- `about:devtools-toolbox` — developer tools (if feasible)
- Generic `about:*` page chrome (error pages, `about:blank`, etc.)

**Files to create**:
- `assets/firefox/userContent-auto.css` — auto-switching version (primary)
- `assets/firefox/userContent-light-glass.css` — static light variant
- `assets/firefox/userContent-night-ride.css` — static dark variant

**Install changes**:
- Update `lib/install-firefox.sh` to copy `userContent-auto.css` as `userContent.css`
- Update `update_firefox_theme()` in the switcher to also deploy `userContent.css`

---

## Phase 2 — GTK3/4 CSS Overrides

**Goal**: Make GTK apps running under KDE visually consistent with the active OneQode theme.

**Approach**: Ship targeted `gtk.css` overrides that set accent colors, selection colors, and scrollbar styling. The switcher swaps the active override on theme change.

**Key targets**:
- Accent/highlight color (selection, focused inputs, toggles, sliders)
- Scrollbar thumb/track colors
- Headerbar background (GTK CSD apps)
- Sidebar backgrounds
- Link colors

**Files to create**:
- `assets/gtk/gtk3-light-glass.css` — GTK3 overrides for light theme
- `assets/gtk/gtk3-night-ride.css` — GTK3 overrides for dark theme
- `assets/gtk/gtk4-light-glass.css` — GTK4 overrides for light theme
- `assets/gtk/gtk4-night-ride.css` — GTK4 overrides for dark theme

**Install path**:
- GTK3: `~/.config/gtk-3.0/gtk.css`
- GTK4: `~/.config/gtk-4.0/gtk.css`

**Switcher changes**:
- Add `update_gtk_theme()` function that copies the correct variant
- KDE already sets the base GTK theme via `kde-gtk-config` / `xdg-desktop-portal-kde` — our overrides layer on top

**Chromium bonus**: Chromium reads GTK3 colors when set to "Use GTK+" appearance mode. Shipping a `.chromium` style class in the GTK3 CSS gives us partial Chromium theming for free:
```css
.entry.chromium {
  background-color: #191c2a;
  color: #e6ebf5;
}
```

---

## Phase 3 — Kvantum Theme

**Goal**: Custom SVG-based Qt widget theme providing polished buttons, sliders, checkboxes, scrollbars, and tooltips beyond what Klassy's widget style offers.

**Approach**: Create a Kvantum theme with Light Glass and Night Ride variants. Kvantum themes consist of an SVG file (widget graphics) and a `.kvconfig` file (metrics and behavior).

**Files to create**:
- `assets/kvantum/OneQodeLightGlass/OneQodeLightGlass.svg`
- `assets/kvantum/OneQodeLightGlass/OneQodeLightGlass.kvconfig`
- `assets/kvantum/OneQodeNightRide/OneQodeNightRide.svg`
- `assets/kvantum/OneQodeNightRide/OneQodeNightRide.kvconfig`
- `lib/install-kvantum.sh`

**Install path**: `~/.config/Kvantum/`

**Switcher changes**:
- Add `update_kvantum_theme()` — uses `kvantummanager --set <theme>` CLI
- Update look-and-feel defaults: `widgetStyle=kvantum` (replaces `klassy`)

**Dependencies**: `kvantum` package must be installed.

**Design approach**:
- Base on an existing clean Kvantum theme (e.g., KvLibadwaita or KvGnomeDark) and re-color to match OneQode palettes
- Semi-transparent tooltips, subtle accent borders on focused inputs
- Rounded corners matching Klassy window decoration radius

---

## Phase 4 — Vivaldi Custom CSS

**Goal**: Full browser chrome theming for Vivaldi, equivalent to what we have for Firefox.

**Approach**: Vivaldi's entire UI is HTML/CSS, and it supports a custom CSS directory via `vivaldi://experiments`. Ship CSS files that use `@media (prefers-color-scheme)` for auto-switching.

**Key targets**:
- Tab bar (`#tabs-container`, `.tab-strip`, `.tab.active`)
- Address bar (`.UrlBar`, `.UrlBar-AddressField`)
- Sidebar/panels (`#panels-container`, `.panel-group`)
- Bookmark bar (`.bookmark-bar`)
- Speed dial / start page (`.startpage-navigation`)
- Menus and popups
- Scrollbars

**Files to create**:
- `assets/vivaldi/custom.css` — auto-switching CSS (primary)
- `lib/install-vivaldi.sh` — copies to `~/.config/vivaldi/custom-css/`

**Install script needs to**:
1. Create `~/.config/vivaldi/custom-css/`
2. Copy CSS file(s)
3. Update Vivaldi's `Preferences` JSON to enable the feature and point to the folder
4. Print instructions about enabling `vivaldi://experiments` flag (can't be set programmatically)

**No switcher integration needed** — `prefers-color-scheme` follows system theme automatically.

---

## Phase 5 — Chromium/Brave Theme Extensions (Lower Priority)

**Goal**: Ship static Chrome theme extensions for browsers that don't support CSS injection.

**Approach**: Manifest V3 theme extensions (no code, just `manifest.json` + optional images). Two variants per browser.

**Limitation**: No auto-switching — user must manually swap or use "System" appearance mode (which only affects dark/light preference, not custom colors).

**Files to create**:
- `assets/chromium/oneqode-light-glass/manifest.json`
- `assets/chromium/oneqode-night-ride/manifest.json`
- `lib/install-chromium.sh` — unpacked extension installation

**Applicable to**: Chrome, Chromium, Brave, Edge, Opera (all use the same manifest format).

**Theme manifest color keys**:
- `frame` — window frame (area behind tabs)
- `toolbar` — toolbar + active tab background
- `tab_text` / `tab_background_text` — tab text colors
- `ntp_background` / `ntp_text` — new tab page
- `omnibox_background` / `omnibox_text` — address bar
- `bookmark_text` — bookmark bar

---

## Phase 6 — Fastfetch Config (Cosmetic) ✅ Done

**Goal**: Themed terminal greeting matching the active theme.

**Approach**: Ship two config files with OneQode colors/logo. Switcher symlinks the active one.

**Files created**:
- `assets/fastfetch/config-light-glass.jsonc`
- `assets/fastfetch/config-night-ride.jsonc`
- `assets/fastfetch/oneqode.txt` (OQ symbol rendered to ASCII)
- `lib/install-fastfetch.sh`

**Install path**: `~/.config/fastfetch/config.jsonc` (symlink → active variant)

**Switcher changes**: `update_fastfetch_theme()` repoints the symlink to the active config.

---

## Phase 7 — Mattermost Auto-Switch ✅ Done

**Goal**: Mattermost follows the desktop day/night theme (was manual import only).

**Approach**: Mattermost stores theme as a server-side user preference, so the switcher
pushes the active variant via the API instead of editing local files. The desktop app's
session token (`MMAUTHTOKEN`) is read from `~/.config/Mattermost/Cookies` at runtime
(handles token rotation); the theme is `PUT` to `/api/v4/users/me/preferences` for every
team plus the all-teams default, so all clients update live.

**Files created**:
- `lib/install-mattermost.sh` (deploys theme JSONs to `~/.local/share/oneqode/mattermost/`)

**Switcher changes**: `update_mattermost_theme()` — called from `apply_theme`; non-fatal on
any failure (logged out, app not installed, cookie format change).

---

## Implementation Order

1. **Firefox userContent.css** — direct extension of current work, high visibility
2. **GTK3/4 overrides** — fixes visible inconsistency in daily use
3. **Kvantum theme** — deeper polish, builds on GTK work
4. **Vivaldi CSS** — for users on Vivaldi, reuses Firefox CSS patterns
5. **Chromium extensions** — low effort, wide compatibility
6. **Fastfetch** — cosmetic finishing touch

---

## Browser Theming Capability Matrix

| Browser | CSS Injection? | Auto Light/Dark? | Mechanism | Shippable as files? |
|---------|---------------|-------------------|-----------|---------------------|
| Firefox | Yes (userChrome/userContent) | Yes (`prefers-color-scheme`) | Profile `chrome/` dir | Yes |
| Vivaldi | Yes (custom CSS dir) | Yes (`prefers-color-scheme`) | `~/.config/vivaldi/custom-css/` | Yes |
| Chrome/Chromium | No | No (themes are static) | Manifest V3 theme extension | Yes (unpacked) |
| Brave | No | No (themes are static) | Manifest V3 theme extension | Yes (unpacked) |
| Opera | No | No | Chrome Web Store theme | Limited |
| Opera GX | Limited (GX Mods) | Yes (required) | GX.store distribution only | No |

---

## Color Reference

### Light Glass
```
Background primary:   #fafcff / rgb(250,252,255)
Background secondary: #f0f4f8 / rgb(240,244,248)
Background tertiary:  #e8f0f5 / rgb(232,240,245)
Text primary:         #232d37 / rgb(35,45,55)
Text secondary:       #5a6570 / rgb(90,101,112)
Text muted:           #8090a0 / rgb(128,144,160)
Accent primary:       #00b4c8 / rgb(0,180,200)
Accent secondary:     #0095a8 / rgb(0,149,168)
Border:               #d8e0e8 / rgb(216,224,232)
Selection:            rgba(0, 180, 200, 0.25)
Shadow:               rgba(0, 0, 0, 0.1)
```

### Night Ride
```
Background primary:   #191c2a / rgb(25,28,42)
Background secondary: #12141f / rgb(18,20,31)
Background tertiary:  #282d3c / rgb(40,45,60)
Text primary:         #e6ebf5 / rgb(230,235,245)
Text secondary:       #a0a8b8 / rgb(160,168,184)
Text muted:           #6a7080 / rgb(106,112,128)
Accent primary:       #ff0080 / rgb(255,0,128)
Accent secondary:     #00c8ff / rgb(0,200,255)
Accent green:         #50ffb4 / rgb(80,255,180)
Border:               #282d3c / rgb(40,45,60)
Selection:            rgba(255, 0, 128, 0.3)
Shadow:               rgba(0, 0, 0, 0.3)
```
