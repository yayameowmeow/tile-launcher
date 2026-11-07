.pragma library

// Pure helpers with no dependency on Plasma, so they can run in tests/.

var LAYOUT_KEYS = ["columns", "tileWidth", "tileHeight", "iconSize", "labelMode", "spacing", "tileStyle"];

var LABEL_BELOW = 0;
var LABEL_BESIDE = 1;
var LABEL_NONE = 2;

var BUILTIN_PRESETS = [
    { id: "builtin:two-columns", name: "Two columns",
      layout: { columns: 2, tileWidth: 96, tileHeight: 96, iconSize: 48, labelMode: 0, spacing: 4, tileStyle: 0 } },
    { id: "builtin:list", name: "List with names",
      layout: { columns: 1, tileWidth: 96, tileHeight: 44, iconSize: 32, labelMode: 1, spacing: 2, tileStyle: 0 } },
    { id: "builtin:compact-list", name: "Compact list",
      layout: { columns: 1, tileWidth: 96, tileHeight: 30, iconSize: 22, labelMode: 1, spacing: 0, tileStyle: 0 } },
    { id: "builtin:two-column-list", name: "Two-column list",
      layout: { columns: 2, tileWidth: 96, tileHeight: 44, iconSize: 32, labelMode: 1, spacing: 2, tileStyle: 0 } },
    { id: "builtin:start-tiles", name: "Start menu tiles",
      layout: { columns: 4, tileWidth: 96, tileHeight: 96, iconSize: 48, labelMode: 0, spacing: 4, tileStyle: 1 } },
    { id: "builtin:icon-grid", name: "Icon grid (fits width)",
      layout: { columns: 0, tileWidth: 64, tileHeight: 64, iconSize: 48, labelMode: 2, spacing: 2, tileStyle: 0 } }
];

// The default icon's file name: the dark version goes with a dark theme.
function defaultIconFile(darkTheme) {
    return darkTheme ? "TiledLauncherDark.svg" : "TiledLauncher.svg";
}

function findPreset(presets, id) {
    for (var i = 0; i < presets.length; i++) {
        if (presets[i].id === id) {
            return presets[i];
        }
    }
    return null;
}

// Number of grid columns that fit `available` px given the layout.
function effectiveColumns(layout, available) {
    if (layout.columns > 0) {
        return layout.columns;
    }
    return Math.max(1, Math.floor((available + layout.spacing) / (layout.tileWidth + layout.spacing)));
}

// First-fit packing of tiles that may span cells. Returns one {col, row, w, h}
// per item, in item order, plus the total row count. Spans wider than the grid
// are clamped so a tile can never be unplaceable.
function pack(items, columns) {
    var occupied = {};
    var isFree = function (col, row, w, h) {
        for (var r = row; r < row + h; r++) {
            for (var c = col; c < col + w; c++) {
                if (occupied[r + ":" + c]) {
                    return false;
                }
            }
        }
        return true;
    };

    var cells = [];
    var rows = 0;
    for (var i = 0; i < items.length; i++) {
        var w = Math.min(Math.max(1, items[i].w || 1), columns);
        var h = Math.max(1, items[i].h || 1);
        var placed = false;
        for (var row = 0; !placed; row++) {
            for (var col = 0; col + w <= columns; col++) {
                if (isFree(col, row, w, h)) {
                    for (var r = row; r < row + h; r++) {
                        for (var c = col; c < col + w; c++) {
                            occupied[r + ":" + c] = true;
                        }
                    }
                    cells.push({ col: col, row: row, w: w, h: h });
                    rows = Math.max(rows, row + h);
                    placed = true;
                    break;
                }
            }
        }
    }
    return { cells: cells, rows: rows };
}

var PLACEMENT_AUTO = 0;
var PLACEMENT_CENTER = 1;
var PLACEMENT_CUSTOM = 2;

// Where a popup's top-left corner goes, relative to its screen's top-left and
// kept on that screen, or null when Plasma should place it next to the widget.
function popupOffset(placement, screenSize, popupSize, custom) {
    var maxX = Math.max(0, screenSize.width - popupSize.width);
    var maxY = Math.max(0, screenSize.height - popupSize.height);
    if (placement === PLACEMENT_CENTER) {
        return { x: Math.round(maxX / 2), y: Math.round(maxY / 2) };
    }
    if (placement === PLACEMENT_CUSTOM) {
        return { x: Math.min(custom.x, maxX), y: Math.min(custom.y, maxY) };
    }
    return null;
}

function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'";
}

function newId() {
    return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
}

function parseItems(json) {
    try {
        var parsed = JSON.parse(json);
        return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
        return [];
    }
}

// Fills in every field, so stored items always have the same shape.
function normalizeItem(item) {
    return {
        id: item.id || newId(),
        type: item.type === "app" ? "app" : "command",
        name: String(item.name || ""),
        icon: String(item.icon || (item.type === "app" ? "application-x-executable" : "text-x-script")),
        desktop: String(item.desktop || ""),
        command: String(item.command || ""),
        workdir: String(item.workdir || ""),
        terminal: !!item.terminal,
        w: Math.max(1, Number(item.w) || 1),
        h: Math.max(1, Number(item.h) || 1)
    };
}

// The shell command that launches a tile, detached so it outlives plasmashell
// and a slow script never holds up the data engine. desktopPath is the absolute
// path of an app tile's .desktop file.
function launchCommand(item, desktopPath) {
    if (item.type === "app") {
        return "setsid -f kioclient exec " + shellQuote(desktopPath) + " >/dev/null 2>&1";
    }

    var cd = item.workdir ? "cd " + shellQuote(item.workdir) : "cd \"$HOME\"";
    var body = String(item.command || "");
    var script;
    if (item.terminal) {
        // Hold the terminal open so the output can be read. The script runs in
        // its own sh so that an `exit` in it still reaches the prompt.
        var held = "sh -c " + shellQuote(body)
            + "; printf '\\n[exited with status %s] Press Enter to close' \"$?\"; read _";
        script = cd + "; t=$(kreadconfig6 --file kdeglobals --group General --key TerminalApplication --default konsole); "
            + "exec $t -e sh -c " + shellQuote(held);
    } else {
        // Run in a subshell for the same reason, so failure can be reported.
        var title = shellQuote("Tile Launcher: " + (item.name || "script"));
        script = cd + "; sh -c " + shellQuote(body) + " >/dev/null 2>&1; s=$?; "
            + "[ \"$s\" -eq 0 ] || notify-send -i dialog-error " + title + " \"Exited with status $s\"";
    }
    return "setsid -f sh -c " + shellQuote(script) + " >/dev/null 2>&1";
}

function fileUrlToPath(url) {
    return decodeURIComponent(String(url).replace(/^file:\/\/(localhost)?/, ""));
}

// Classifies a dropped URL. kind: "desktopId" (installed app by menu id),
// "desktopFile" (a .desktop on disk), "file" (any other local path) or "url".
function classifyUrl(urlValue) {
    var url = String(urlValue);
    var match = url.match(/^applications:\/*(.+\.desktop)$/);
    if (match) {
        return { kind: "desktopId", value: decodeURIComponent(match[1]) };
    }
    if (url.indexOf("file:") === 0 || url.charAt(0) === "/") {
        var path = fileUrlToPath(url);
        return { kind: /\.desktop$/.test(path) ? "desktopFile" : "file", value: path };
    }
    return { kind: "url", value: url };
}

function basename(path) {
    var trimmed = String(path).replace(/\/+$/, "");
    return trimmed.substring(trimmed.lastIndexOf("/") + 1);
}

// Pulls Name= and Icon= from the [Desktop Entry] group of a .desktop file.
function parseDesktopEntry(text) {
    var result = { name: "", icon: "" };
    var inEntry = false;
    var lines = String(text).split("\n");
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim();
        if (line.charAt(0) === "[") {
            inEntry = line === "[Desktop Entry]";
        } else if (inEntry && line.indexOf("Name=") === 0 && !result.name) {
            result.name = line.substring(5);
        } else if (inEntry && line.indexOf("Icon=") === 0 && !result.icon) {
            result.icon = line.substring(5);
        }
    }
    return result;
}
