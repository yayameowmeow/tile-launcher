import QtQuick
import QtQuick.Window

import "../code/logic.js" as Logic

// Applies the configured size and position to the applet popup.
//
// Plasma's popup offers no way to set a position: it places itself against its
// visualParent item, using the edge of the window that item is in for the main
// axis. So a custom position comes from anchoring it to an item in a helper
// window placed for the purpose. That window is never shown, as only its
// geometry is read.
Item {
    id: placement

    required property var popupWindow
    required property var widgetItem
    required property var cfg

    property bool syncingFromWindow: false
    property var autoDirection: null

    readonly property string settings: [cfg.windowWidth, cfg.windowHeight, cfg.popupPlacement,
                                        cfg.popupX, cfg.popupY].join()

    function applySize() {
        if (cfg.windowWidth > 0) {
            popupWindow.width = Math.max(cfg.windowWidth, popupWindow.minimumWidth);
        }
        if (cfg.windowHeight > 0) {
            popupWindow.height = Math.max(cfg.windowHeight, popupWindow.minimumHeight);
        }
    }

    function applyPosition() {
        var screen = widgetItem ? widgetItem.screenGeometry : null;
        var offset = screen ? Logic.popupOffset(cfg.popupPlacement, screen,
                                                { width: popupWindow.width, height: popupWindow.height },
                                                { x: cfg.popupX, y: cfg.popupY }) : null;
        if (!offset) {
            popupWindow.visualParent = widgetItem;
            popupWindow.popupDirection = autoDirection;
            return;
        }
        var qscreen = Array.from(Qt.application.screens).find(s => s.name === widgetItem.screenName);
        if (qscreen) {
            anchorWindow.screen = qscreen;
        }
        moveAnchor(offset);
        // Reassigned so the popup re-reads the anchor when only its coordinates changed.
        popupWindow.visualParent = null;
        popupWindow.popupDirection = Qt.TopEdge;
        popupWindow.visualParent = anchor;
    }

    // With Qt.TopEdge the popup sits directly above the anchor's window and is
    // horizontally centred on the anchor item.
    function moveAnchor(offset) {
        var screen = widgetItem.screenGeometry;
        anchorWindow.x = screen.x;
        anchorWindow.width = screen.width;
        anchorWindow.height = 1;
        anchorWindow.y = screen.y + offset.y + popupWindow.height + popupWindow.margin;
        anchor.x = offset.x + Math.ceil(popupWindow.width / 2) - anchor.width / 2;
    }

    function apply() {
        if (!popupWindow || syncingFromWindow) {
            return;
        }
        if (autoDirection === null) {
            autoDirection = popupWindow.popupDirection;
        }
        applySize();
        applyPosition();
    }

    // Edge dragging is the other way to set the size, so it keeps the settings current.
    function syncSizeFromWindow() {
        syncingFromWindow = true;
        cfg.windowWidth = popupWindow.width;
        cfg.windowHeight = popupWindow.height;
        syncingFromWindow = false;
        var offset = Logic.popupOffset(cfg.popupPlacement, widgetItem.screenGeometry,
                                       { width: popupWindow.width, height: popupWindow.height },
                                       { x: cfg.popupX, y: cfg.popupY });
        if (offset) {
            moveAnchor(offset);
        }
    }

    onPopupWindowChanged: apply()
    onSettingsChanged: apply()

    Connections {
        target: placement.popupWindow
        function onVisibleChanged() {
            if (placement.popupWindow.visible) {
                placement.apply();
                placement.syncSizeFromWindow();
            }
        }
        function onWidthChanged() {
            if (placement.popupWindow.visible) {
                placement.syncSizeFromWindow();
            }
        }
        function onHeightChanged() {
            if (placement.popupWindow.visible) {
                placement.syncSizeFromWindow();
            }
        }
    }

    Window {
        id: anchorWindow
        visible: false

        Item {
            id: anchor
            width: 2
            height: 1
        }
    }
}
