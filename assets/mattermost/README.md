# OneQode Mattermost Themes

Custom themes for Mattermost desktop and web client.

## Automatic switching (recommended)

When installed via `oneqode` (or `lib/install-mattermost.sh`), the theme switches
automatically with the desktop day/night theme. On KDE that is the look-and-feel
switcher; on Omarchy it is the `theme-set` hook. Both push the active variant to
the Mattermost server via its API, so all your clients (and all teams) update
live — no manual paste needed.

How it works: `apply-theme.py` reads the desktop app's session token (`MMAUTHTOKEN`)
from `~/.config/Mattermost/Cookies` at runtime and `PUT`s the theme to
`/api/v4/users/me/preferences` for every team plus the all-teams default. The token
is read fresh each time, so rotation is handled automatically; if you're logged out
the update is skipped silently. On Omarchy the solar timer retries that push if
the desktop theme is already correct, so a sunrise switch that raced wifi still
catches up.

Requires the Mattermost desktop app to be set up (logged in) before installing.

## Manual installation (fallback)

1. Open Mattermost (desktop app or web)
2. Click the **Settings** icon (gear) in the top right
3. Navigate to **Display** → **Theme**
4. Select **Custom Theme**
5. At the bottom, find "Copy and paste to share theme colors"
6. Paste the contents of one of the theme files:
   - `oneqode-night-ride.json` (dark synthwave)
   - `oneqode-light-glass.json` (light teal)
7. Click **Save**

## Theme Preview

### Night Ride (Dark)
- Dark blue-gray backgrounds (#191c2a, #12141f)
- Magenta accents for active items and buttons (#ff0080)
- Cyan links (#00c8ff)
- Neon green online indicator (#50ffb4)

### Light Glass (Light)
- Light blue-white backgrounds (#fafcff, #f0f4f8)
- Teal accents for active items and buttons (#00b4c8)
- Darker teal links (#0095a8)
- Solarized-style status indicators

## Sharing

You can share these themes with your team by copying the JSON contents.

## Desktop App Dark Mode

The Mattermost desktop app also has a dark mode setting:
1. Click the menu icon (≡)
2. Go to **File** → **View**
3. Toggle **Dark Mode**

Note: This is separate from the custom theme and affects window chrome.
