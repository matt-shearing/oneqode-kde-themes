#!/usr/bin/env python3
"""
OneQode Theme Switcher - System Tray Applet

A simple system tray icon for quick theme switching between
Light Glass (day) and Night Ride (dark) themes.
"""

import subprocess
import sys
from pathlib import Path

try:
    from PyQt6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
    from PyQt6.QtGui import QIcon, QAction
    from PyQt6.QtCore import QTimer
    PYQT_VERSION = 6
except ImportError:
    try:
        from PyQt5.QtWidgets import QApplication, QSystemTrayIcon, QMenu, QAction
        from PyQt5.QtGui import QIcon
        from PyQt5.QtCore import QTimer
        PYQT_VERSION = 5
    except ImportError:
        print("Error: PyQt6 or PyQt5 required. Install with: pip install PyQt6")
        sys.exit(1)

# Paths
LOCAL_BIN = Path.home() / ".local" / "bin"
CONFIG_DIR = Path.home() / ".config" / "oneqode"
ICON_DIR = Path.home() / ".local" / "share" / "oneqode" / "icons"
ONEQODE_DIR = Path.home() / "dev" / "oneqode-kde-themes"

SWITCH_CMD = LOCAL_BIN / "oneqode-theme-switch"


class OneQodeTray:
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.app.setQuitOnLastWindowClosed(False)
        self.app.setApplicationName("OneQode Theme Switcher")

        # Current theme state
        self.current_theme = "unknown"
        self.current_mode = "solar"

        # Load icons
        self.icon_light = QIcon(str(ICON_DIR / "oneqode-light.svg"))
        self.icon_dark = QIcon(str(ICON_DIR / "oneqode-dark.svg"))

        # Fallback if icons not found
        if self.icon_light.isNull():
            self.icon_light = QIcon.fromTheme("weather-clear")
        if self.icon_dark.isNull():
            self.icon_dark = QIcon.fromTheme("weather-clear-night")

        # Create tray icon
        self.tray = QSystemTrayIcon()
        self.tray.setIcon(self.icon_dark)
        self.tray.setToolTip("OneQode Theme Switcher")

        # Create menu
        self.menu = QMenu()
        self.build_menu()
        self.tray.setContextMenu(self.menu)

        # Any click opens menu
        self.tray.activated.connect(self.on_activated)

        # Update status periodically
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_status)
        self.timer.start(5000)  # Every 5 seconds

        # Initial status
        self.update_status()

        self.tray.show()

    def build_menu(self):
        """Build the context menu."""
        self.menu.clear()

        # Status header (disabled, just for display)
        self.status_action = QAction(f"Theme: {self.current_theme.title()}", self.menu)
        self.status_action.setEnabled(False)
        self.menu.addAction(self.status_action)

        self.mode_action = QAction(f"Mode: {self.current_mode.title()}", self.menu)
        self.mode_action.setEnabled(False)
        self.menu.addAction(self.mode_action)

        self.menu.addSeparator()

        # Theme options
        light_action = QAction("Switch to Light Glass", self.menu)
        light_action.triggered.connect(lambda: self.switch_theme("day"))
        self.menu.addAction(light_action)

        dark_action = QAction("Switch to Night Ride", self.menu)
        dark_action.triggered.connect(lambda: self.switch_theme("night"))
        self.menu.addAction(dark_action)

        self.menu.addSeparator()

        # Status info
        status_action = QAction("Show Status...", self.menu)
        status_action.triggered.connect(self.show_status)
        self.menu.addAction(status_action)

        # Open config TUI
        config_action = QAction("Open Configuration...", self.menu)
        config_action.triggered.connect(self.open_config)
        self.menu.addAction(config_action)

        self.menu.addSeparator()

        # Quit
        quit_action = QAction("Quit Tray", self.menu)
        quit_action.triggered.connect(self.app.quit)
        self.menu.addAction(quit_action)

    def on_activated(self, reason):
        """Handle tray icon activation - show menu on left click."""
        if PYQT_VERSION == 6:
            trigger = QSystemTrayIcon.ActivationReason.Trigger
        else:
            trigger = QSystemTrayIcon.Trigger

        # Only handle left-click (Trigger) - right-click is handled by setContextMenu
        if reason == trigger:
            if PYQT_VERSION == 6:
                from PyQt6.QtGui import QCursor
                self.menu.exec(QCursor.pos())
            else:
                from PyQt5.QtGui import QCursor
                self.menu.exec_(QCursor.pos())

    def switch_theme(self, mode):
        """Switch to specified theme."""
        try:
            if mode == "day":
                subprocess.run([str(SWITCH_CMD), "--force-day"], check=True)
            elif mode == "night":
                subprocess.run([str(SWITCH_CMD), "--force-night"], check=True)
            else:
                subprocess.run([str(SWITCH_CMD)], check=True)

            # Update status after a short delay
            QTimer.singleShot(500, self.update_status)

        except subprocess.CalledProcessError as e:
            print(f"Error switching theme: {e}")
        except FileNotFoundError:
            print(f"Theme switcher not found: {SWITCH_CMD}")

    def show_status(self):
        """Show detailed status in a notification."""
        try:
            result = subprocess.run(
                [str(SWITCH_CMD), "--status"],
                capture_output=True,
                text=True,
                timeout=5
            )
            status_text = result.stdout.strip()

            # Show as notification
            self.tray.showMessage(
                "OneQode Theme Status",
                status_text,
                QSystemTrayIcon.MessageIcon.Information,
                5000
            )
        except Exception as e:
            self.tray.showMessage(
                "OneQode Theme Status",
                f"Error getting status: {e}",
                QSystemTrayIcon.MessageIcon.Warning,
                3000
            )

    def open_config(self):
        """Open terminal with OneQode TUI configuration."""
        oneqode_cmd = str(LOCAL_BIN / "oneqode")
        try:
            # Try different terminal emulators
            terminals = [
                ["ghostty", "-e", "bash", "-c", f"{oneqode_cmd}; exec bash"],
                ["konsole", "-e", "bash", "-c", f"{oneqode_cmd}; exec bash"],
                ["xterm", "-e", "bash", "-c", f"{oneqode_cmd}; exec bash"],
            ]

            for term_cmd in terminals:
                try:
                    subprocess.Popen(term_cmd, start_new_session=True)
                    return
                except FileNotFoundError:
                    continue

            # Fallback: try generic x-terminal-emulator
            subprocess.Popen(
                ["x-terminal-emulator", "-e", oneqode_cmd],
                start_new_session=True
            )
        except Exception as e:
            print(f"Error opening terminal: {e}")
            self.tray.showMessage(
                "OneQode",
                f"Could not open terminal: {e}",
                QSystemTrayIcon.MessageIcon.Warning,
                3000
            )

    def update_status(self):
        """Update current theme status and icon."""
        try:
            result = subprocess.run(
                [str(SWITCH_CMD), "--status"],
                capture_output=True,
                text=True,
                timeout=5
            )

            # Parse output
            for line in result.stdout.splitlines():
                if "Current period:" in line:
                    self.current_theme = line.split(":")[-1].strip()
                elif "Mode:" in line:
                    self.current_mode = line.split(":")[-1].strip()

            # Update icon based on theme
            if self.current_theme == "day":
                self.tray.setIcon(self.icon_light)
                self.tray.setToolTip(f"OneQode: Light Glass ({self.current_mode})")
            else:
                self.tray.setIcon(self.icon_dark)
                self.tray.setToolTip(f"OneQode: Night Ride ({self.current_mode})")

            # Update menu status items
            self.status_action.setText(f"Theme: {self.current_theme.title()}")
            self.mode_action.setText(f"Mode: {self.current_mode.title()}")

        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError) as e:
            print(f"Error getting status: {e}")

    def run(self):
        """Run the application."""
        return self.app.exec() if PYQT_VERSION == 6 else self.app.exec_()


def main():
    # Check if already running
    import fcntl
    lock_file = Path("/tmp/oneqode-tray.lock")

    try:
        lock_fd = open(lock_file, "w")
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except IOError:
        print("OneQode tray is already running")
        sys.exit(0)

    tray = OneQodeTray()
    sys.exit(tray.run())


if __name__ == "__main__":
    main()
