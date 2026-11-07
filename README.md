# Tile Launcher

Note. This project was entirely coded by Claude Opus 5.5. Art assets were done by me. Below is the readme created by Claude.

# Tile Launcher

A Plasma 6 widget: click it and a resizable popup of tiled buttons opens. Tiles
launch applications and scripts. Place as many widgets as you like, on panels or
the desktop. Each has its own tiles, name and icon.

## Install

    ./install.sh

Then right-click a panel or the desktop, choose **Add Widgets**, and add
**Tile Launcher**.

## Using it

- **Add apps:** choose **Add Applications** from the popup's ⋮ menu for a
  searchable list, where a click adds or removes an app. You can also drag one onto the widget. Holding a drag over the
  button opens the popup.
- **Add scripts:** choose **Add Script or Command** from the ⋮ menu, or drag an
  executable file onto the widget. Dragged documents, folders and links become
  tiles that open them.
- **Resize the popup:** drag its edges, or enter a size in the settings. Each
  widget remembers its size.
- **Reorder:** drag a tile.
- **Edit or remove:** right-click a tile. Editing covers the name, icon, command,
  working folder, terminal option and tile size in cells (across and down).
- **Keep it open:** the pin button stops the popup closing when it loses focus.

Scripts run with `sh` from your home folder unless you set a working folder. A
script that exits non-zero shows a notification.

## Settings

Right-click the widget and choose Configure, or use the popup's ⋮ menu.

- **General:** name, icon (with a button to return to the default) and whether the name is shown beside the icon. Vertical
  panels always show just the icon.
- **Layout & Presets:** columns (a fixed count, or as many as fit), tile size,
  icon size, spacing, name position and tile style.
- **Popup:** width and height, and position: next to the widget, the center of
  the screen, or a custom offset from the screen's top-left corner. The popup is
  kept on screen. With a set position, its bottom edge can't be dragged, so resize
  from the top or sides.

## Presets

A preset is a layout, not a list of tiles. The built-ins are Two columns, List
with names, Compact list, Two-column list, Start menu tiles and Icon grid.

Saving under **Share as preset** makes it available in every Tile Launcher. A
widget using a shared preset picks up changes to it the next time its popup
opens. Saving with an existing preset's name overwrites that preset. Changing any
value by hand gives that widget its own layout again.

## Where things are stored

- Each widget's tiles and settings: `~/.config/plasma-org.kde.plasma.desktop-appletsrc`
- Shared presets: `~/.config/tilelauncherpresets.conf`

## Tests

    QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/tst_logic.qml

These cover the pure logic in `contents/code/logic.js`: tile packing, launch
commands and shell quoting, and classifying dropped URLs.

## Uninstall

    kpackagetool6 -t Plasma/Applet -r local.tilelauncher

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
