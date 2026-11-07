import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

import "../code/logic.js" as Logic

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property string displayName: cfg.widgetName || Plasmoid.metaData.name
    readonly property bool darkTheme: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark
    readonly property string defaultIcon: Qt.resolvedUrl("../icons/" + Logic.defaultIconFile(darkTheme))
    readonly property string displayIcon: cfg.widgetIcon || defaultIcon
    readonly property bool showName: cfg.showName
    readonly property int formFactor: Plasmoid.formFactor
    readonly property var items: Logic.parseItems(cfg.itemsJson)
    readonly property var layoutConfig: ({
        columns: cfg.columns,
        tileWidth: cfg.tileWidth,
        tileHeight: cfg.tileHeight,
        iconSize: cfg.iconSize,
        labelMode: cfg.labelMode,
        spacing: cfg.spacing,
        tileStyle: cfg.tileStyle
    })

    // What the popup shows: "grid", "apps" (picker) or "edit" (item editor).
    property string page: "grid"
    property var editing: null
    property bool pinned: false
    // True while a separate dialog window (icon or file chooser) is open, since
    // it would otherwise deactivate the popup and close it.
    property bool holdOpen: false

    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactRepresentation {
        launcher: root
    }
    fullRepresentation: FullRepresentation {
        launcher: root
    }

    hideOnWindowDeactivate: !pinned && !holdOpen
    toolTipMainText: displayName
    toolTipSubText: i18np("%1 item", "%1 items", items.length)

    Plasmoid.title: displayName
    Plasmoid.icon: displayIcon
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Applications…")
            icon.name: "list-add"
            onTriggered: {
                root.openPicker();
                root.expanded = true;
            }
        },
        PlasmaCore.Action {
            text: i18n("Add Script or Command…")
            icon.name: "text-x-script"
            onTriggered: {
                root.editItem(null);
                root.expanded = true;
            }
        }
    ]

    onExpandedChanged: isExpanded => {
        if (isExpanded) {
            syncPreset();
        } else {
            page = "grid";
            editing = null;
        }
    }

    Component.onCompleted: syncPreset()

    PresetStore {
        id: presets
    }

    // Set by the full representation once it is in the popup window.
    property var popupWindow: null

    PopupPlacement {
        popupWindow: root.popupWindow
        widgetItem: root.compactRepresentationItem
        cfg: root.cfg
    }

    // Widgets linked to a preset pick up changes made to it from any other widget.
    function syncPreset() {
        presets.reload();
        var preset = presets.find(cfg.presetId);
        if (!preset) {
            return;
        }
        Logic.LAYOUT_KEYS.forEach(key => {
            if (preset.layout[key] !== undefined && cfg[key] !== preset.layout[key]) {
                cfg[key] = preset.layout[key];
            }
        });
    }

    function saveItems(list) {
        cfg.itemsJson = JSON.stringify(list);
    }

    // Reads the config rather than `items`, so several additions from one drop
    // never overwrite each other.
    function currentItems() {
        return Logic.parseItems(cfg.itemsJson);
    }

    function addItem(item) {
        var normalized = Logic.normalizeItem(item);
        saveItems(currentItems().concat([normalized]));
        return normalized.id;
    }

    function updateItem(item) {
        var normalized = Logic.normalizeItem(item);
        var list = currentItems();
        var index = list.findIndex(i => i.id === normalized.id);
        if (index >= 0) {
            list[index] = normalized;
        } else {
            list.push(normalized);
        }
        saveItems(list);
    }

    function removeItem(id) {
        saveItems(currentItems().filter(i => i.id !== id));
    }

    function setOrder(ids) {
        var byId = {};
        currentItems().forEach(i => byId[i.id] = i);
        saveItems(ids.map(id => byId[id]).filter(i => !!i));
    }

    function itemById(id) {
        return currentItems().find(i => i.id === id) || null;
    }

    function launch(id) {
        var item = itemById(id);
        if (!item) {
            return;
        }
        if (item.type === "app") {
            var path = desktopPathFor(item);
            if (!path) {
                shell("notify-send -i dialog-error " + Logic.shellQuote(i18n("Tile Launcher: %1", item.name))
                      + " " + Logic.shellQuote(i18n("This application is no longer installed.")));
                return;
            }
            shell(Logic.launchCommand(item, path));
        } else {
            shell(Logic.launchCommand(item));
        }
        if (!pinned) {
            expanded = false;
        }
    }

    function desktopPathFor(item) {
        if (item.desktop.charAt(0) === "/") {
            return item.desktop;
        }
        var entry = appsEngine.data[item.desktop];
        return entry ? entry.entryPath : "";
    }

    function openPicker() {
        page = "apps";
    }

    // Opens the editor for an existing item, or for a new script when null.
    function editItem(id) {
        editing = Logic.normalizeItem(id ? itemById(id) : { id: "new", type: "command" });
        page = "edit";
    }

    function closePage() {
        page = "grid";
        editing = null;
    }

    function configure() {
        Plasmoid.internalAction("configure").trigger();
    }

    function installedApps() {
        var result = [];
        var seen = {};
        appsEngine.sources.forEach(source => {
            var entry = appsEngine.data[source];
            if (entry && entry.isApp && entry.display && entry.menuId && !seen[entry.menuId]) {
                seen[entry.menuId] = true;
                result.push(entry);
            }
        });
        return result.sort((a, b) => a.name.localeCompare(b.name));
    }

    function addApp(entry) {
        return addItem({ type: "app", name: entry.name, icon: entry.iconName, desktop: entry.menuId });
    }

    // Accepts what drags deliver: launcher entries, .desktop files, scripts,
    // other files and folders, and web links.
    function addDropped(urls) {
        for (var i = 0; i < urls.length; i++) {
            addDroppedUrl(urls[i]);
        }
    }

    function addDroppedUrl(url) {
        var dropped = Logic.classifyUrl(url);
        if (dropped.kind === "desktopId" || dropped.kind === "desktopFile") {
            var entry = appsEngine.data[Logic.basename(dropped.value)];
            if (entry && entry.isApp) {
                addApp(entry);
            } else if (dropped.kind === "desktopFile") {
                addDesktopFile(dropped.value);
            }
        } else if (dropped.kind === "file") {
            addFile(dropped.value);
        } else {
            addItem({ type: "command", name: dropped.value, icon: "internet-web-browser",
                      command: "xdg-open " + Logic.shellQuote(dropped.value) });
        }
    }

    function addDesktopFile(path) {
        shell("cat -- " + Logic.shellQuote(path), stdout => {
            var entry = Logic.parseDesktopEntry(stdout);
            addItem({ type: "app", desktop: path,
                      name: entry.name || Logic.basename(path).replace(/\.desktop$/, ""),
                      icon: entry.icon });
        });
    }

    function addFile(path) {
        var quoted = Logic.shellQuote(path);
        shell("if [ -d " + quoted + " ]; then echo dir; elif [ -x " + quoted + " ]; then echo exec; else echo file; fi", stdout => {
            var kind = stdout.trim();
            var name = Logic.basename(path);
            if (kind === "exec") {
                addItem({ type: "command", name: name, icon: "text-x-script", command: quoted });
            } else {
                addItem({ type: "command", name: name, icon: kind === "dir" ? "folder" : "document-open",
                          command: "xdg-open " + quoted });
            }
        });
    }

    property var pendingShell: ({})

    function shell(command, callback) {
        pendingShell[command] = callback || null;
        runner.connectSource(command);
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => {
            var callback = root.pendingShell[source];
            delete root.pendingShell[source];
            disconnectSource(source);
            if (callback) {
                callback(data["stdout"] || "");
            }
        }
    }

    P5Support.DataSource {
        id: appsEngine
        engine: "apps"
        connectedSources: sources
    }
}
