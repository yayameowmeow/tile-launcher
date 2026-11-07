import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras

import "../code/logic.js" as Logic

Item {
    id: tile

    required property int index
    required property string uid
    required property string label
    required property string iconName
    required property int spanW
    required property int spanH
    required property var grid
    required property Item container

    readonly property var rect: grid.cellRect(index)
    readonly property int labelMode: grid.layoutConfig.labelMode
    readonly property bool dragging: mouse.dragging

    property real dragX: 0
    property real dragY: 0

    x: dragging ? dragX : rect.x
    y: dragging ? dragY : rect.y
    z: dragging ? 1 : 0
    width: rect.width
    height: rect.height

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: grid.launcher.launch(uid)
    Keys.onEnterPressed: grid.launcher.launch(uid)
    Keys.onSpacePressed: grid.launcher.launch(uid)

    Behavior on x {
        enabled: tile.grid.reordering && !tile.dragging
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        enabled: tile.grid.reordering && !tile.dragging
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: tile.grid.layoutConfig.tileStyle === 1
        radius: Kirigami.Units.cornerRadius
        color: Kirigami.Theme.textColor
        opacity: 0.08
    }

    PlasmaExtras.Highlight {
        anchors.fill: parent
        visible: mouse.containsMouse || tile.activeFocus
        hovered: true
        pressed: mouse.pressed
    }

    GridLayout {
        id: content

        // Vertically centred at its natural height, so icon and name stay
        // together on a tile spanning several rows.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Kirigami.Units.smallSpacing
        columns: tile.labelMode === Logic.LABEL_BESIDE ? 2 : 1
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing * 2

        Kirigami.Icon {
            // A tile spanning several cells gets a bigger icon, within what fits.
            readonly property int wanted: tile.grid.layoutConfig.iconSize * Math.min(tile.spanW, tile.spanH)
            readonly property int inner: tile.height - content.anchors.margins * 2
            readonly property int fit: tile.labelMode === Logic.LABEL_BELOW
                ? inner - nameLabel.implicitHeight - content.rowSpacing : inner
            readonly property int size: Math.max(Kirigami.Units.iconSizes.small, Math.min(wanted, fit, content.width))

            Layout.preferredWidth: size
            Layout.preferredHeight: size
            Layout.alignment: tile.labelMode === Logic.LABEL_BESIDE
                ? Qt.AlignLeft | Qt.AlignVCenter : Qt.AlignHCenter | Qt.AlignVCenter
            source: tile.iconName
            active: mouse.containsMouse
        }

        PC3.Label {
            id: nameLabel

            visible: tile.labelMode !== Logic.LABEL_NONE
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: tile.label
            elide: Text.ElideRight
            wrapMode: tile.labelMode === Logic.LABEL_BELOW ? Text.Wrap : Text.NoWrap
            maximumLineCount: tile.labelMode === Logic.LABEL_BELOW ? 2 : 1
            horizontalAlignment: tile.labelMode === Logic.LABEL_BELOW ? Text.AlignHCenter : Text.AlignLeft
        }
    }

    MouseArea {
        id: mouse

        property bool dragging: false
        property bool dragged: false
        property point pressPoint
        property point pressTile

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        // On a touchscreen a drag scrolls the list; with a mouse it reorders.
        preventStealing: !Kirigami.Settings.tabletMode

        onPressed: event => {
            dragged = false;
            pressPoint = mapToItem(tile.container, event.x, event.y);
            pressTile = Qt.point(tile.x, tile.y);
        }
        onPositionChanged: event => {
            if (!pressed || !(event.buttons & Qt.LeftButton) || Kirigami.Settings.tabletMode) {
                return;
            }
            var point = mapToItem(tile.container, event.x, event.y);
            var dx = point.x - pressPoint.x;
            var dy = point.y - pressPoint.y;
            if (!dragging && Math.max(Math.abs(dx), Math.abs(dy)) > Application.styleHints.startDragDistance) {
                tile.dragX = pressTile.x;
                tile.dragY = pressTile.y;
                tile.grid.reordering = true;
                dragging = true;
                dragged = true;
            }
            if (dragging) {
                tile.dragX = pressTile.x + dx;
                tile.dragY = pressTile.y + dy;
                tile.grid.dragOver(tile.index, point.x, point.y);
            }
        }
        function endDrag() {
            if (dragging) {
                dragging = false;
                tile.grid.finishDrag();
                // A release outside the popup sends no leave event, which would
                // leave the hover highlight stuck on until the next hover.
                hoverEnabled = false;
                hoverEnabled = true;
            }
        }

        onReleased: endDrag()
        onCanceled: endDrag()
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                tile.grid.openMenu(tile.uid, tile, event.x, event.y);
            } else if (!dragged) {
                tile.grid.launcher.launch(tile.uid);
            }
        }
    }

    PC3.ToolTip.text: label
    PC3.ToolTip.visible: mouse.containsMouse && !dragging && (labelMode === Logic.LABEL_NONE || nameLabel.truncated)
    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
}
