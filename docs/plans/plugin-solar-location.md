# Plan: set solar location from the OneQode plugin

**Status:** approved 2026-08-30 (city search + presets, Omarchy plugin only). Implemented.

The OneQode bar applet must let you pick the city that drives auto day/night. Auto switching uses latitude, longitude, and an IANA timezone from `~/.config/oneqode/oneqode-theme-switcher.conf`. It does not read the OS timezone. Setting `timedatectl` to Hong Kong left the switcher on Brisbane, which is why Night Ride came on at 15:33 HKT (Brisbane sunset).

This plan adds a location control to `oneqode.control` and a matching `oneqode-control location` CLI. It does **not** make the switcher follow the system timezone.

## Why not the OS timezone

Sunrise and sunset are a function of coordinates. `Asia/Hong_Kong` on the clock only changes how civil time is labelled. With Brisbane's lat/lon and Hong Kong's zone, sunset still happens at the Brisbane instant, shown as 15:33 HKT.

A city pick writes all three values: `LATITUDE`, `LONGITUDE`, `TIMEZONE`.

## What you see

Under **Auto day / night**, the panel already shows sunrise and sunset. Add a location row:

- Idle: **Hong Kong** · `Asia/Hong_Kong` (tap to edit)
- Editing: a search field, up to five city suggestions, and three preset chips: **Brisbane**, **Hong Kong**, **Sydney**

The auto toggle's description stays `Sunrise HH:MM · sunset HH:MM`. Drop the hardcoded fallback string `Brisbane solar schedule`.

Match the weather panel: click the label to edit, Esc cancels, Enter commits the highlighted suggestion. While a `TextField` or suggestion list owns keys, set `PanelKeyCatcher.blocked` so the panel cursor model does not steal them.

## How it writes

The plugin does not edit the conf. It calls `oneqode-control`. Quickshell's PATH starts at `$OMARCHY_PATH/bin`, so those calls must use `$HOME/.local/bin/oneqode-control` with PATH as fallback (same pattern as `omarchy-dev` gotchas).

```
oneqode-control location                  # print current
oneqode-control location --json           # name, lat, lon, timezone, sunrise, sunset, period
oneqode-control location search QUERY     # Open-Meteo geocoding JSON
oneqode-control location set NAME LAT LON TZ
oneqode-control location preset brisbane|hong-kong|sydney
```

`status --json` gains a `location` object so one refresh paints the row:

```json
"location": {
  "name": "Hong Kong",
  "timezone": "Asia/Hong_Kong",
  "latitude": 22.3193,
  "longitude": 114.1694
}
```

### Conf writes

Update only these keys in `~/.config/oneqode/oneqode-theme-switcher.conf`:

- `LATITUDE`, `LONGITUDE`, `TIMEZONE`
- `LOCATION_NAME` (display label; new)

Never write `LIGHT_THEME` or `DARK_THEME`. Those KDE look-and-feel IDs overwrite Omarchy slugs when `omarchy-oq-auto-theme` sources the file wholesale. Create the file if it is missing. Leave `MODE`, offsets, and fallback times alone.

### After a successful set

1. Recompute solar period for the new coordinates.
2. If auto is on, apply the matching theme immediately.
3. Run `omarchy-oq-auto-nightlight` so the Kelvin ramp follows the new sun, not the next 5-minute tick.

If auto is off, update the displayed times only. Leave the current theme.

## Presets

Offline, no geocoding:

| Chip | Lat | Lon | Timezone |
|---|---|---|---|
| Brisbane | -27.4698 | 153.0251 | Australia/Brisbane |
| Hong Kong | 22.3193 | 114.1694 | Asia/Hong_Kong |
| Sydney | -33.8688 | 151.2093 | Australia/Sydney |

## City search

`oneqode-control location search` calls the same Open-Meteo geocoding API Omarchy weather already uses:

`https://geocoding-api.open-meteo.com/v1/search?name=QUERY&count=5&language=en&format=json`

Each hit already includes `name`, `latitude`, `longitude`, `timezone`, `country`. The plugin lists `Name, admin1, country`. Picking one runs `location set` with those four fields. Offline search fails cleanly and leaves presets usable.

## Script hardening (same change)

`omarchy-oq-auto-theme` and `omarchy-oq-auto-nightlight` still source the conf, then **re-assert** `LIGHT_THEME=omarchy-oq-light-glass` and `NIGHT_THEME=omarchy-oq-night-ride` after the source. Read `LATITUDE` / `LONGITUDE` / `TIMEZONE` / `LOCATION_NAME` only. That closes the KDE-key clobber that already bit once.

Keep Brisbane as the in-script default when the conf is missing. Do not start following `timedatectl`.

## Out of scope

- Following the OS timezone automatically
- A 400-zone IANA dropdown
- GeoClue / GPS
- Raw lat/lon fields in the panel
- A location picker on the KDE tray (the conf is shared, so a set from Omarchy is enough for KDE)
- Changing sojourner's current Hong Kong conf as part of this work

## Files

| Path | Change |
|---|---|
| `assets/omarchy/keyboard/oneqode-control` | `location` subcommand, `status --json` location object |
| `assets/omarchy/plugin/oneqode.control/Panel.qml` | Location row, search, presets |
| `assets/omarchy/plugin/oneqode.control/Model.js` | Parse location JSON and search hits |
| `switcher/omarchy-oq-auto-theme` | Re-assert theme slugs after sourcing conf |
| `~/bin/omarchy-oq-auto-nightlight` (installed copy sourced from the tree that owns it) | Same slug hardening if it sources the conf |
| `OMARCHY.md`, plugin `README.md` | Document `location` |
| Live copies | `~/.local/bin/oneqode-control` and `~/.config/omarchy/plugins/oneqode.control/` after verify |

Installer already copies the plugin and CLI. No new systemd unit.

## Verify

1. `oneqode-control location --json` shows the current conf (Hong Kong on sojourner).
2. Search `hong`, pick Hong Kong: times stay ~06:05 / 18:43 in August.
3. Preset Brisbane: times jump to Brisbane sun; if auto is on and it is afternoon HKT, theme may go to Night Ride.
4. Preset Hong Kong with auto on: back to Light Glass in the afternoon.
5. Auto off: preset change updates the label and times, not the theme.
6. Night light Kelvin follows the new sun on the same `location set`.
7. Conf has no `LIGHT_THEME` / `DARK_THEME` lines.
8. Panel: Esc cancels edit; click outside commits nothing; Light Glass and Night Ride still switch; heatmap still applies.
9. `qmllint` on `Panel.qml`. Exercise Light Glass and Night Ride. Desktop and the panel at its fitted height.

## Implementation order

1. CLI `location` get / set / preset / search, plus `status --json`.
2. Harden the two solar scripts against conf clobber.
3. Panel UI on top of that CLI.
4. Copy CLI and plugin to the live paths, then verify.

## Open questions

Approve as written, or change any of these:

1. **Presets:** Brisbane, Hong Kong, Sydney. Add more now?
2. **Search:** Open-Meteo in this slice, or presets only first?
3. **KDE tray:** skip this round (recommended), or add a picker there too?
