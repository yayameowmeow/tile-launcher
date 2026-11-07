import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras

ColumnLayout {
    id: picker

    required property var launcher

    readonly property var allApps: launcher.installedApps()
    readonly property var filtered: {
        var query = search.text.trim().toLowerCase();
        if (!query) {
            return allApps;
        }
        return allApps.filter(app => {
            var haystack = [app.name, app.genericName, app.comment].concat(app.keywords || []).join(" ").toLowerCase();
            return haystack.indexOf(query) >= 0;
        });
    }

    function tileFor(menuId) {
        return launcher.items.find(item => item.type === "app" && item.desktop === menuId) || null;
    }

    spacing: Kirigami.Units.smallSpacing

    Keys.onEscapePressed: launcher.closePage()
    Component.onCompleted: search.forceActiveFocus()

    PlasmaExtras.SearchField {
        id: search
        Layout.fillWidth: true
        focus: true
        Keys.onEscapePressed: picker.launcher.closePage()
    }

    PC3.ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: appList

            clip: true
            model: picker.filtered
            reuseItems: true
            delegate: PC3.ItemDelegate {
                id: row

                required property var modelData

                readonly property var existing: picker.tileFor(modelData.menuId)

                width: ListView.view.width
                text: modelData.name
                onClicked: {
                    if (existing) {
                        picker.launcher.removeItem(existing.id);
                    } else {
                        picker.launcher.addApp(modelData);
                    }
                }

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing * 2

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        source: row.modelData.iconName || "application-x-executable"
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: row.text
                        elide: Text.ElideRight
                    }

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        visible: row.existing !== null
                        source: "checkmark"
                    }
                }
            }

            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 2
                visible: appList.count === 0
                iconName: "edit-none"
                text: i18n("No matching applications")
            }
        }
    }
}
