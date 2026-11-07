import QtQuick

import org.kde.draganddrop as DragDrop
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras

import "../code/logic.js" as Logic

DragDrop.DropArea {
    id: tileGrid

    required property var launcher

    readonly property var layoutConfig: launcher.layoutConfig
    readonly property int tileSpacing: layoutConfig.spacing
    readonly property int tileHeight: layoutConfig.tileHeight
    // From the full width rather than view.availableWidth: that shrinks when the
    // scrollbar appears, which depends on the row count, which depends on this.
    readonly property int columns: Logic.effectiveColumns(layoutConfig, width)
    readonly property real cellWidth: (view.availableWidth - tileSpacing * (columns - 1)) / columns

    property var cells: []
    property int rowCount: 0
    property bool reordering: false
    property string lastDropTarget: ""
    // JSON of the order the grid itself just committed, to skip rebuilding from it.
    property string committedJson: ""

    function relayout(list) {
        var packed = Logic.pack(list, columns);
        cells = packed.cells;
        rowCount = packed.rows;
    }

    function currentSpans() {
        var list = [];
        for (var i = 0; i < tileModel.count; i++) {
            var entry = tileModel.get(i);
            list.push({ w: entry.spanW, h: entry.spanH });
        }
        return list;
    }

    function rebuild() {
        var items = launcher.items;
        if (JSON.stringify(items) === committedJson) {
            committedJson = "";
            return;
        }
        relayout(items);
        tileModel.clear();
        items.forEach(item => tileModel.append({
            uid: item.id, label: item.name, iconName: item.icon,
            spanW: item.w || 1, spanH: item.h || 1
        }));
    }

    function cellRect(index) {
        var cell = cells[index] || { col: 0, row: 0, w: 1, h: 1 };
        return {
            x: cell.col * (cellWidth + tileSpacing),
            y: cell.row * (tileHeight + tileSpacing),
            width: cell.w * cellWidth + (cell.w - 1) * tileSpacing,
            height: cell.h * tileHeight + (cell.h - 1) * tileSpacing
        };
    }

    // Live reorder while dragging. A target only triggers once per entry, or a
    // tile of a different span would swap back and forth under the cursor.
    function dragOver(index, x, y) {
        scrollToward(y);
        for (var i = 0; i < tileModel.count; i++) {
            var rect = cellRect(i);
            if (x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height) {
                var uid = tileModel.get(i).uid;
                if (i !== index && uid !== lastDropTarget) {
                    lastDropTarget = uid;
                    tileModel.move(index, i, 1);
                    relayout(currentSpans());
                }
                return;
            }
        }
        lastDropTarget = "";
    }

    function scrollToward(y) {
        var margin = Kirigami.Units.gridUnit * 2;
        var viewY = y - flick.contentY;
        var maxY = Math.max(0, flick.contentHeight - flick.height);
        if (viewY < margin) {
            flick.contentY = Math.max(0, flick.contentY - Kirigami.Units.smallSpacing * 2);
        } else if (viewY > flick.height - margin) {
            flick.contentY = Math.min(maxY, flick.contentY + Kirigami.Units.smallSpacing * 2);
        }
    }

    function finishDrag() {
        var ids = [];
        for (var i = 0; i < tileModel.count; i++) {
            ids.push(tileModel.get(i).uid);
        }
        var byId = {};
        launcher.items.forEach(item => byId[item.id] = item);
        committedJson = JSON.stringify(ids.map(id => byId[id]).filter(item => !!item));
        lastDropTarget = "";
        settleTimer.restart();
        launcher.setOrder(ids);
    }

    function openMenu(uid, tile, x, y) {
        tileMenu.uid = uid;
        tileMenu.visualParent = tile;
        tileMenu.open(x, y);
    }

    onColumnsChanged: relayout(currentSpans())
    preventStealing: true

    onDrop: event => {
        launcher.addDropped(event.mimeData.urls);
        event.accept(Qt.CopyAction);
    }

    Connections {
        target: tileGrid.launcher
        function onItemsChanged() {
            tileGrid.rebuild();
        }
    }

    Component.onCompleted: rebuild()

    Timer {
        id: settleTimer
        interval: Kirigami.Units.longDuration
        onTriggered: tileGrid.reordering = false
    }

    ListModel {
        id: tileModel
    }

    PC3.ScrollView {
        id: view
        anchors.fill: parent
        contentWidth: availableWidth
        PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff

        Flickable {
            id: flick
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: tileGrid.rowCount > 0
                ? tileGrid.rowCount * (tileGrid.tileHeight + tileGrid.tileSpacing) - tileGrid.tileSpacing : 0

            Item {
                id: tileContainer
                width: flick.contentWidth
                height: flick.contentHeight

                Repeater {
                    model: tileModel
                    delegate: Tile {
                        grid: tileGrid
                        container: tileContainer
                    }
                }
            }
        }
    }

    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 2
        visible: tileModel.count === 0
        iconName: tileGrid.launcher.defaultIcon
        text: i18n("No tiles yet")
        explanation: i18n("Add applications or scripts from the menu above, or drag them here.")
    }

    Rectangle {
        anchors.fill: parent
        visible: tileGrid.containsDrag
        color: "transparent"
        radius: Kirigami.Units.cornerRadius
        border.width: 2
        border.color: Kirigami.Theme.highlightColor
    }

    PlasmaExtras.Menu {
        id: tileMenu

        property string uid: ""

        PlasmaExtras.MenuItem {
            text: i18n("Edit…")
            icon: "document-edit"
            onClicked: tileGrid.launcher.editItem(tileMenu.uid)
        }
        PlasmaExtras.MenuItem {
            text: i18n("Remove")
            icon: "list-remove"
            onClicked: tileGrid.launcher.removeItem(tileMenu.uid)
        }
    }
}
