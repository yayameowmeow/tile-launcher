import QtQuick
import QtCore

import "../code/logic.js" as Logic

// Layout presets. Built-ins ship with the widget; custom ones live in a file
// outside any one applet's config so every Tile Launcher on the system sees them.
QtObject {
    id: store

    property var custom: []
    readonly property var all: Logic.BUILTIN_PRESETS.concat(custom)

    property Settings settings: Settings {
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/tilelauncherpresets.conf"
        category: "presets"
    }

    function reload() {
        settings.sync();
        store.custom = Logic.parseItems(settings.value("json", "[]"));
    }

    function find(id) {
        return Logic.findPreset(all, id);
    }

    function findCustomByName(name) {
        var wanted = String(name).trim().toLowerCase();
        for (var i = 0; i < custom.length; i++) {
            if (custom[i].name.toLowerCase() === wanted) {
                return custom[i];
            }
        }
        return null;
    }

    // Saves under `name`, overwriting a custom preset of the same name. Returns the id.
    function save(name, layout) {
        reload();
        var existing = findCustomByName(name);
        var id = existing ? existing.id : "custom:" + Logic.newId();
        var next = custom.filter(p => p.id !== id);
        next.push({ id: id, name: String(name).trim(), layout: layout });
        write(next);
        return id;
    }

    function remove(id) {
        reload();
        write(custom.filter(p => p.id !== id));
    }

    function write(list) {
        settings.setValue("json", JSON.stringify(list));
        settings.sync();
        store.custom = list;
    }

    Component.onCompleted: reload()
}
