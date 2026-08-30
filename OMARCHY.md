# OneQode on Omarchy

Omarchy (Hyprland + Quickshell) counterpart to the KDE tray and theme switcher.

## What gets installed

| Piece | Path |
|---|---|
| Themes | `~/.config/omarchy/themes/omarchy-oq-{night-ride,light-glass}/` |
| Control CLI | `~/.local/bin/oneqode-control` |
| Auto day/night | `~/.local/bin/omarchy-oq-auto-theme` + user systemd timer |
| Theme-set hook | `~/.config/omarchy/hooks/theme-set.d/{framework-keyboard-heat,gtk-theme,herdr-theme,mattermost-theme}.sh` |
| Bar applet | `~/.config/omarchy/plugins/oneqode.control/` |
| Keyboard config | `~/.config/oneqode/keyboard.conf` |

## Control CLI

```
oneqode-control status [--json]
oneqode-control theme night|day|toggle
oneqode-control auto on|off|toggle
oneqode-control location
oneqode-control location search QUERY
oneqode-control location set NAME LAT LON TIMEZONE
oneqode-control location preset brisbane|hong-kong|sydney
oneqode-control keyboard effect heatmap|solid|off
oneqode-control keyboard brightness 40|70|100
oneqode-control apply
```

`heatmap` is the Framework 16 typing heatmap (effect 45): idle is the theme
accent, zones walk Night Ride pink→magenta→cyan or Light Glass ice→blue.
`solid` is the accent only. Settings survive theme switches because the
theme-set hook calls `oneqode-control apply`.

## Firmware

Custom QMK keymap: `assets/omarchy/keyboard/firmware/oqheat/`
Prebuilt UF2: `assets/omarchy/keyboard/firmware/framework_ansi_oqheat.uf2`

Flash with `qmk_hid via --bootloader`, then copy the UF2 onto `RPI-RP2`.
Or run `oq-keyboard-flash` if that helper is on the machine.

## Bar applet

`oneqode.control` is the Omarchy-native tray. Click the bar mark for theme
buttons, auto day/night, solar city, heatmap/solid/off, and brightness. Right-click
toggles Light Glass and Night Ride.

Auto day/night uses latitude, longitude, and an IANA timezone from
`~/.config/oneqode/oneqode-theme-switcher.conf`. It does not follow the OS
timezone. Set the city from the panel (search or a Brisbane / Hong Kong / Sydney
preset) or with `oneqode-control location`.
