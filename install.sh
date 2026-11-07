#!/bin/sh
# Installs or upgrades the widget for the current user.
set -e
cd "$(dirname "$0")"
if kpackagetool6 -t Plasma/Applet -l | grep -qx 'local.tilelauncher'; then
    kpackagetool6 -t Plasma/Applet -u package
    echo "Upgraded. Widgets already placed use the new version after: systemctl --user restart plasma-plasmashell"
else
    kpackagetool6 -t Plasma/Applet -i package
    echo "Installed. Right-click your panel or desktop, choose Add Widgets, and search for Tile Launcher."
fi
