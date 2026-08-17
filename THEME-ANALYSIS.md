# OneQode Linux Theme - Comprehensive Analysis

## 1. Project Structure & Overview

**OneQode Linux Theme** is Light Glass / Night Ride for KDE Plasma 6 and Omarchy on Wayland. The same day/night pair, with automatic sunrise/sunset switching and shared app palettes (Herdr, Grok Build, Ghostty, Firefox, editors).

### Two Main Theme Variants

1. **OneQode Light Glass** - A light, glass-inspired daytime theme
2. **OneQode Night Ride** - A dark, synthwave-inspired nighttime theme

### Repository Structure

```
oneqode-kde-themes/
├── assets/           # All theme assets
│   ├── color-schemes/
│   ├── look-and-feel/
│   ├── wallpapers/
│   ├── icons/
│   ├── klassy/       # Window decoration presets
│   ├── konsole/      # Terminal themes
│   ├── ghostty/      # Terminal themes
│   ├── zed/          # Editor themes
│   ├── firefox/      # Browser themes
│   ├── obsidian/     # Note-taking app themes
│   ├── mattermost/   # Chat app themes
│   ├── opera/        # Browser theming guide
│   └── typora/       # Markdown editor themes
├── switcher/         # Auto-switching systemd service
├── sddm/             # Login screen configs
├── lib/              # Modular installer scripts
├── oneqode           # Main TUI entry point
├── install.sh        # Installation script
├── uninstall.sh      # Uninstaller
└── verify.sh         # Verification script
```

---

## 2. Color Palettes

### OneQode Light Glass (Ice Cyan Theme)

#### Primary Accent Colors

| Role | Hex | RGB |
|------|-----|-----|
| Primary Accent (Ice Cyan) | `#00b4c8` | 0, 180, 200 |
| Accent Hover | `#3cc8d7` | 60, 200, 215 |
| Focus Color | `#00b4c8` | 0, 180, 200 |

#### Background Colors

| Role | Hex | RGB |
|------|-----|-----|
| Main Background | `#f2f6fa` | 242, 246, 250 |
| View Background (Pure White) | `#ffffff` | 255, 255, 255 |
| Alternate Background | `#f5f8fa` | 245, 248, 250 |
| Button Background | `#f5f8fa` | 245, 248, 250 |
| Header Background | `#f0f4f8` | 240, 244, 248 |
| Splash Screen Background | `#f5f5f5` → `#e8e8e8` | gradient |

#### Text Colors

| Role | Hex | RGB |
|------|-----|-----|
| Foreground (Dark Text) | `#232d37` | 35, 45, 55 |
| Inactive Text | `#828c96` | 130, 140, 150 |
| Link Color | `#008ca0` | 0, 140, 160 |

#### Window Manager Colors

| Role | Hex | RGB |
|------|-----|-----|
| Active Title Bar Background | `#f0f4f8` | 240, 244, 248 |
| Inactive Title Bar Background | `#ebf0f5` | 235, 240, 245 |

#### Selection Colors

| Role | Hex | RGB |
|------|-----|-----|
| Selection Background | `#00b4c8` | 0, 180, 200 |
| Selection Foreground | `#ffffff` | 255, 255, 255 |

#### Klassy Button Colors

| Role | Hex | RGB |
|------|-----|-----|
| Close Button Hover | `#cc3c3c` | 204, 60, 60 |
| Maximize Button Hover | `#00aabe` | 0, 170, 190 |
| Minimize Button Hover | `#826edc` | 130, 110, 220 |
| Window Outline | `#00b4c8` | accent on hover |
| Title Bar Opacity | 85% active, 70% inactive | |

#### Terminal Colors

| Role | Hex | RGB |
|------|-----|-----|
| Background | `#fafcff` | 250, 252, 255 |
| Foreground | `#232d37` | 35, 45, 55 |
| Cursor | `#00b4c8` | 0, 180, 200 |
| Transparency | 0.95 (95% opacity) | |

---

### OneQode Night Ride (Synthwave/Neon Theme)

#### Primary Accent Colors

| Role | Hex | RGB |
|------|-----|-----|
| Primary Accent (Neon Magenta) | `#ff0080` | 255, 0, 128 |
| Accent Hover | `#ff50a0` | 255, 80, 160 |
| Secondary Accent (Neon Cyan) | `#00c8ff` | 0, 200, 255 |
| Tertiary Accent (Neon Green) | `#50ffb4` | 80, 255, 180 |

#### Background Colors

| Role | Hex | RGB |
|------|-----|-----|
| Main Background | `#202434` | 32, 36, 52 |
| View Background | `#191c2a` | 25, 28, 42 |
| Alternate Background | `#1e2332` | 30, 35, 50 |
| Button Background | `#2d3241` | 45, 50, 65 |
| Header Background | `#232837` | 35, 40, 55 |
| Splash Screen Background | `#1a1a2e` → `#16213e` → `#0f0f1a` | gradient |

#### Text Colors

| Role | Hex | RGB |
|------|-----|-----|
| Foreground (Light Text) | `#e6ebf5` | 230, 235, 245 |
| Inactive Text | `#8c91a5` | 140, 145, 165 |
| Link Color | `#00c8ff` | 0, 200, 255 |

#### Window Manager Colors

| Role | Hex | RGB |
|------|-----|-----|
| Active Title Bar Background | `#232837` | 35, 40, 55 |
| Inactive Title Bar Background | `#1e2332` | 30, 35, 50 |

#### Selection Colors

| Role | Hex | RGB |
|------|-----|-----|
| Selection Background | `#ff0080` | 255, 0, 128 |
| Selection Foreground | `#ffffff` | 255, 255, 255 |

#### Klassy Button Colors

| Role | Hex | RGB |
|------|-----|-----|
| Close Button (Neon Pink) | `#ff1a4d` | 255, 26, 77 |
| Maximize Button (Neon Green) | `#33ff99` | 51, 255, 153 |
| Minimize Button (Neon Cyan) | `#00e5ff` | 0, 229, 255 |
| Window Outline | `#ff0080` | neon pink custom |
| Title Bar Opacity | 88% active, 65% inactive | |
| Button Style | AccentTrafficLights | always-visible colored dots |

#### Terminal Colors

| Role | Hex | RGB |
|------|-----|-----|
| Background | `#191c2a` | 25, 28, 42 |
| Foreground | `#e6ebf5` | 230, 235, 245 |
| Cursor | `#ff0080` | 255, 0, 128 |
| Transparency | 0.88 (88% opacity) | |

---

## 3. Branding Assets

### Primary Logo: "OneQode Symbol - Celtic Blue"

- **File:** `OneQode Symbol - Celtic Blue.svg` (also PNG)
- **Design:** Celtic knot-inspired circular spiral symbol forming a stylized 'Q' shape with flowing, interconnected curves
- **Color:** `#1774e0` (Celtic Blue - RGB: 23, 116, 224)

### Icon Variants

| Variant | File | Color |
|---------|------|-------|
| Light Theme | `assets/icons/oneqode-light.svg` | `#1774e0` (blue) |
| Dark Theme | `assets/icons/oneqode-dark.svg` | `#00b4c8` (ice cyan) |

### Wallpapers

- `assets/wallpapers/OneQode-Light-Glass.jpg` — 4K (3840x2160)
- `assets/wallpapers/OneQode-Night-Ride.jpg` — 4K (3840x2160)

---

## 4. Design Language & Aesthetic

### OneQode Light Glass

**Design Philosophy:**
- **Glass/Translucency:** Emphasis on blur effects and transparency
- **Clean & Minimal:** Light, airy interface with subtle gradients
- **Professional:** Designed for comfortable daytime work
- **Color Psychology:** Ice cyan evokes coolness, clarity, and focus

**Visual Characteristics:**
- Hover-reveal window buttons (hidden normally, appear on hover)
- 85% active / 70% inactive title bar opacity
- Subtle accent colors with coral close button
- Window outline colorizes with accent on hover
- Blur enabled on transparent elements
- Rounded corners (10px radius)

**Typography:**
- UI Font: Inter (10pt)
- Monospace: JetBrains Mono Nerd Font (10pt)

**Icon Theme:** Papirus (light variant)

### OneQode Night Ride

**Design Philosophy:**
- **Synthwave/Cyberpunk:** Neon accents on dark backgrounds
- **High Contrast:** Vibrant neon colors for nighttime coding
- **Energetic:** Nighttime coding aesthetic with bold accent colors
- **Retro-Future:** 1980s synthwave meets modern UI design

**Visual Characteristics:**
- Always-visible neon traffic light dots on active windows
- 88% active / 65% inactive title bar opacity
- Neon pink/magenta primary accent (#ff0080)
- Neon cyan secondary accent (#00c8ff)
- Neon green tertiary accent (#50ffb4)
- Window outline in custom neon pink
- Gradient effects in progress bars (magenta to cyan)
- Rounded corners (10px radius)
- Higher shadow strength (220 vs 180 in light theme)

**Typography:**
- UI Font: Inter (10pt)
- Monospace: JetBrains Mono Nerd Font (10pt)

**Icon Theme:** Papirus-Dark

---

## 5. Splash Screen Configurations

Both themes include custom KSplash screens implemented in QML.

### Light Glass Splash

- **Background:** `#f5f5f5` with gradient overlay (white to `#e8e8e8`)
- **Logo Text:** "OneQode" in Inter font, 48px, light weight, `#333333`
- **Tagline:** "Light Glass" in `#00d4ff` (cyan), 16px
- **Progress Bar:** 2px height, `#e0e0e0` track, `#00d4ff` fill
- **Animation:** 500ms fade-in with InOutQuad easing

### Night Ride Splash

- **Background:** `#1a1a2e` with gradient (`#1a1a2e` → `#16213e` → `#0f0f1a`)
- **Logo Text:** "OneQode" in Inter font, 48px, light weight, white
- **Tagline:** "Night Ride" in `#ff00ff` (magenta), 16px
- **Progress Bar:** 2px height, `#2a2a4a` track, gradient fill (magenta to cyan)
- **Animation:** 500ms fade-in with InOutQuad easing

---

## 6. SDDM Login Screen

- Uses Breeze SDDM theme with custom backgrounds
- Cursor theme: Bibata-Modern-Ice
- Light: `/usr/share/wallpapers/OneQode/OneQode-Light-Glass.jpg`
- Dark: `/usr/share/wallpapers/OneQode/OneQode-Night-Ride.jpg`

---

## 7. Application Themes

The project includes themes for:

| Application | Type |
|-------------|------|
| Konsole | Terminal theme with transparency |
| Ghostty | Terminal theme with transparency |
| Zed | Editor theme (follows system) |
| Firefox | Browser extensions (.xpi) + userChrome.css |
| Obsidian | Note-taking theme (manifest.json + theme.css) |
| Mattermost | Chat app (JSON color configs) |
| Typora | Markdown editor (CSS themes) |
| Opera | Browser theming guide (CSS variables) |

---

## 8. Window Decorations (Klassy)

### Light Glass

- Hover-reveal buttons (hidden when not hovering)
- AccentNegativeClose color scheme
- Custom button overrides (coral/ice-cyan/violet)
- Accent color window outline
- StyleKisweet button icon style

### Night Ride

- Always-visible AccentTrafficLights (colored dots)
- Neon custom colors on hover
- Custom neon pink window outline
- Higher opacity for better visibility in dark
- Traffic light metaphor (red/green/cyan)

---

## 9. Automatic Switching System

- **Solar Mode:** Uses python-astral for sunrise/sunset calculations
- **Fixed Mode:** Configurable times (default: 07:30 day, 18:30 night)
- **Systemd Timer:** Runs every 5 minutes
- **State Tracking:** Prevents redundant theme applications
- **Theme Watcher:** Background service ensures Klassy decorations apply correctly

---

## 10. Brand Identity

### Visual Style Summary

**Core Brand Values:**
1. **Duality:** Two complementary themes (day/night, light/dark)
2. **Cohesion:** Consistent theming across 10+ applications
3. **Professionalism:** Work-focused design with attention to detail
4. **Celtic Heritage:** The logo uses Celtic knot symbolism
5. **Modern Technology:** Plasma 6, Wayland, modern tech stack

**Design Signatures:**
- Celtic-inspired circular logo
- Ice cyan for light themes (cool, professional)
- Neon magenta/pink for dark themes (energetic, creative)
- Glass/blur effects for depth
- Rounded corners throughout
- Premium Klassy window decorations

### Contact & Attribution

- **Email:** contact@oneqode.com
- **Theme Email:** themes@oneqode.com
- **GitHub:** github.com/matt-shearing/oneqode-kde-themes
- **License:** MIT License (2025 OneQode)
