import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import org.kde.draganddrop as DragDrop
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.core as PlasmaCore

MouseArea {
    id: compact

    required property var launcher

    readonly property bool onPanel: launcher.formFactor === PlasmaCore.Types.Horizontal
                                    || launcher.formFactor === PlasmaCore.Types.Vertical
    readonly property bool horizontalPanel: launcher.formFactor === PlasmaCore.Types.Horizontal
    // A vertical panel is too narrow for text, so it keeps to the icon.
    readonly property bool labelShown: launcher.showName && launcher.formFactor !== PlasmaCore.Types.Vertical

    property bool wasExpanded: false

    // The screen this button is on, which the popup's configured position is relative to.
    readonly property string screenName: Screen.name
    readonly property rect screenGeometry: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)

    Layout.minimumWidth: horizontalPanel && labelShown
        ? height + label.implicitWidth + Kirigami.Units.smallSpacing * 2
        : (onPanel ? -1 : Kirigami.Units.iconSizes.large)
    Layout.minimumHeight: onPanel ? -1 : Kirigami.Units.iconSizes.large + (labelShown ? label.implicitHeight : 0)
    Layout.preferredWidth: Layout.minimumWidth

    activeFocusOnTab: true
    hoverEnabled: true

    onPressed: wasExpanded = launcher.expanded
    onClicked: launcher.expanded = !wasExpanded
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            launcher.expanded = !launcher.expanded;
        }
    }

    GridLayout {
        anchors.fill: parent
        anchors.rightMargin: compact.horizontalPanel && compact.labelShown ? Kirigami.Units.smallSpacing : 0
        columns: compact.horizontalPanel ? 2 : 1
        rowSpacing: 0
        columnSpacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.fillHeight: true
            Layout.fillWidth: !(compact.horizontalPanel && compact.labelShown)
            Layout.preferredWidth: compact.horizontalPanel && compact.labelShown ? compact.height : -1
            source: compact.launcher.displayIcon
            active: compact.containsMouse || compact.launcher.expanded
        }

        PC3.Label {
            id: label
            visible: compact.labelShown
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: compact.launcher.displayName
            elide: Text.ElideRight
            horizontalAlignment: compact.horizontalPanel ? Text.AlignLeft : Text.AlignHCenter
        }
    }

    DragDrop.DropArea {
        anchors.fill: parent
        preventStealing: true

        onDragEnter: event => {
            if (event.mimeData.urls.length > 0) {
                springLoad.restart();
            }
        }
        onDragLeave: springLoad.stop()
        onDrop: event => {
            springLoad.stop();
            compact.launcher.addDropped(event.mimeData.urls);
            event.accept(Qt.CopyAction);
        }

        // Holding a drag over the button opens the popup, as a drop target.
        Timer {
            id: springLoad
            interval: Kirigami.Units.longDuration * 3
            onTriggered: compact.launcher.expanded = true
        }
    }
}
