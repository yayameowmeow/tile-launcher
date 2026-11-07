import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Representation {
    id: full

    required property var launcher

    readonly property bool onGrid: launcher.page === "grid"

    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10
    Layout.preferredWidth: Kirigami.Units.gridUnit * 20
    Layout.preferredHeight: Kirigami.Units.gridUnit * 26

    collapseMarginsHint: true

    readonly property var popupWindow: Window.window
    onPopupWindowChanged: launcher.popupWindow = popupWindow
    Component.onCompleted: launcher.popupWindow = popupWindow

    header: PlasmaExtras.PlasmoidHeading {
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PC3.ToolButton {
                visible: !full.onGrid
                icon.name: "go-previous"
                display: PC3.AbstractButton.IconOnly
                text: i18n("Back")
                onClicked: full.launcher.closePage()
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                Layout.leftMargin: full.onGrid ? Kirigami.Units.smallSpacing : 0
                level: 3
                elide: Text.ElideRight
                text: {
                    if (full.launcher.page === "apps") {
                        return i18n("Add Applications");
                    }
                    if (full.launcher.page === "edit") {
                        return full.launcher.editing && full.launcher.editing.id !== "new"
                            ? i18n("Edit Tile") : i18n("Add Script or Command");
                    }
                    return full.launcher.displayName;
                }
            }

            PC3.ToolButton {
                id: menuButton
                visible: full.onGrid
                icon.name: "overflow-menu"
                display: PC3.AbstractButton.IconOnly
                text: i18n("Menu")
                down: pressed
                onClicked: headerMenu.openRelative()
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay

                PlasmaExtras.Menu {
                    id: headerMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedRightAlignedPopup

                    PlasmaExtras.MenuItem {
                        text: i18n("Add Applications…")
                        icon: "list-add"
                        onClicked: full.launcher.openPicker()
                    }
                    PlasmaExtras.MenuItem {
                        text: i18n("Add Script or Command…")
                        icon: "text-x-script"
                        onClicked: full.launcher.editItem(null)
                    }
                    PlasmaExtras.MenuItem {
                        text: i18n("Configure…")
                        icon: "configure"
                        onClicked: full.launcher.configure()
                    }
                }
            }

            PC3.ToolButton {
                icon.name: "window-pin"
                display: PC3.AbstractButton.IconOnly
                text: i18n("Keep Open")
                checkable: true
                checked: full.launcher.pinned
                onToggled: full.launcher.pinned = checked
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }

    contentItem: Item {
        TileGrid {
            anchors.fill: parent
            visible: full.onGrid
            launcher: full.launcher
        }

        Loader {
            anchors.fill: parent
            active: full.launcher.page === "apps"
            focus: active
            sourceComponent: AppPicker {
                launcher: full.launcher
            }
        }

        Loader {
            anchors.fill: parent
            active: full.launcher.page === "edit" && full.launcher.editing !== null
            focus: active
            sourceComponent: ItemEditor {
                launcher: full.launcher
                item: full.launcher.editing
            }
        }
    }
}
