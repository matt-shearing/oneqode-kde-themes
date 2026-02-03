# OneQode Opera Theming Guide

Opera browser theming is handled differently than Firefox. Here are your options:

## Option 1: Use Opera's Built-in Dark Mode (Recommended)

1. Open Opera Settings (Alt+P)
2. Go to "Basic" section
3. Under "Appearance", enable "Dark mode"
4. Under "Themes", select a dark theme

This will give you a dark interface that works well with the OneQode Night Ride system theme.

## Option 2: System Theme Integration

Opera can follow your system theme:

1. Open Opera Settings (Alt+P)
2. Go to "Basic" > "Appearance"
3. Select "System" for the theme
4. Opera will now follow your KDE/system dark/light mode

This pairs perfectly with the OneQode theme switcher!

## Option 3: Custom CSS with Stylus Extension

For full control over Opera's appearance:

1. Install the "Stylus" extension from Opera addons
2. Create a new style for Opera's UI (opera://* URLs)
3. Use the CSS color values below

### Night Ride Colors
```css
--bg-primary: #191c2a;
--bg-secondary: #12141f;
--bg-tertiary: #282d3c;
--text-primary: #e6ebf5;
--text-secondary: #a0a8b8;
--accent-magenta: #ff0080;
--accent-cyan: #00c8ff;
--border: #282d3c;
```

### Light Glass Colors
```css
--bg-primary: #fafcff;
--bg-secondary: #f0f4f8;
--bg-tertiary: #e8f0f5;
--text-primary: #232d37;
--text-secondary: #5a6570;
--accent-teal: #00b4c8;
--border: #d8e0e8;
```

## Option 4: Sidebar and Speed Dial Customization

1. Right-click on the Speed Dial background
2. Select "Change background"
3. Use a solid color matching OneQode themes:
   - Night Ride: #191c2a
   - Light Glass: #fafcff

For sidebar customization, Opera automatically follows the system theme when set to "System" mode.
