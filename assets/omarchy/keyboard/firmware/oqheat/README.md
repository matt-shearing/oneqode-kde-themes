# OQ heat keymap

Stock Framework firmware (effect 31) uses a fixed cyan → green → yellow → red
heatmap and turns idle keys off.

This keymap keeps the default ANSI layout and VIA support, and adds
`RGB_MATRIX_CUSTOM_OQ_HEAT` (effect 45):

- Idle is the configured accent (Night Ride pink / Light Glass ice).
- Typing builds a local heatmap: the key plus a short neighbour falloff.
- Night Ride walks pink → magenta → cyan (no gold, no splash rings).

Build:

```
export QMK_HOME=/home/contra/dev/framework-qmk
qmk compile -kb framework/ansi -km oqheat
```

Flash: slide the touchpad down until the keyboard backlight dies, hold both
Alt keys, slide the touchpad back up, then copy the UF2 onto `RPI-RP2`.
