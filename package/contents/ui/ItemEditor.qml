import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.iconthemes as KIconThemes
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

import "../code/logic.js" as Logic

ColumnLayout {
    id: editor

    required property var launcher
    required property var item

    readonly property bool isScript: item.type !== "app"
    readonly property bool isNew: item.id === "new"
    readonly property bool valid: nameField.text.trim().length > 0
                                  && (!isScript || commandField.text.trim().length > 0)

    property string iconName: item.icon

    function save() {
        if (!valid) {
            return;
        }
        var updated = Object.assign({}, item, {
            name: nameField.text.trim(),
            icon: iconName,
            w: widthBox.value,
            h: heightBox.value
        });
        if (isScript) {
            updated.command = commandField.text;
            updated.workdir = workdirField.text.trim();
            updated.terminal = terminalBox.checked;
        }
        if (isNew) {
            delete updated.id;
            launcher.addItem(updated);
        } else {
            launcher.updateItem(updated);
        }
        launcher.closePage();
    }

    spacing: Kirigami.Units.smallSpacing

    Keys.onEscapePressed: launcher.closePage()
    Component.onCompleted: nameField.forceActiveFocus()

    PC3.ScrollView {
        id: scroller

        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroller.availableWidth
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 2

                PC3.ToolButton {
                    id: iconButton
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    onClicked: iconDialog.open()
                    PC3.ToolTip.text: i18n("Choose icon…")
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay

                    contentItem: Kirigami.Icon {
                        source: editor.iconName
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PC3.Label {
                        text: i18n("Name:")
                    }
                    PC3.TextField {
                        id: nameField
                        Layout.fillWidth: true
                        text: editor.item.name
                        focus: true
                        placeholderText: editor.isScript ? i18n("Script name") : i18n("Application name")
                        Keys.onReturnPressed: editor.save()
                        Keys.onEscapePressed: editor.launcher.closePage()
                    }
                }
            }

            PC3.Label {
                visible: !editor.isScript
                Layout.fillWidth: true
                elide: Text.ElideMiddle
                opacity: 0.7
                text: i18n("Application: %1", editor.item.desktop)
            }

            PC3.Label {
                visible: editor.isScript
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Command or script:")
            }
            PC3.TextArea {
                id: commandField
                visible: editor.isScript
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 6
                text: editor.item.command
                wrapMode: TextEdit.Wrap
                font.family: "monospace"
                placeholderText: i18n("Run with sh, e.g.\nnotify-send \"Hello\"")
            }
            PC3.Button {
                visible: editor.isScript
                icon.name: "document-open"
                text: i18n("Choose Script File…")
                onClicked: fileDialog.open()
            }

            PC3.Label {
                visible: editor.isScript
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Working folder:")
            }
            PC3.TextField {
                id: workdirField
                visible: editor.isScript
                Layout.fillWidth: true
                text: editor.item.workdir
                placeholderText: i18n("Home folder")
            }
            PC3.CheckBox {
                id: terminalBox
                visible: editor.isScript
                text: i18n("Run in terminal")
                checked: editor.item.terminal
            }

            PC3.Label {
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Tile size in grid cells:")
            }
            RowLayout {
                spacing: Kirigami.Units.smallSpacing

                PC3.Label {
                    text: i18n("Across")
                }
                PC3.SpinBox {
                    id: widthBox
                    from: 1
                    to: 32
                    value: editor.item.w
                }
                PC3.Label {
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    text: i18n("Down")
                }
                PC3.SpinBox {
                    id: heightBox
                    from: 1
                    to: 32
                    value: editor.item.h
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            visible: !editor.isNew
            icon.name: "list-remove"
            text: i18n("Remove")
            onClicked: {
                editor.launcher.removeItem(editor.item.id);
                editor.launcher.closePage();
            }
        }
        Item {
            Layout.fillWidth: true
        }
        PC3.Button {
            icon.name: "dialog-cancel"
            text: i18n("Cancel")
            onClicked: editor.launcher.closePage()
        }
        PC3.Button {
            icon.name: "dialog-ok"
            text: editor.isNew ? i18n("Add") : i18n("Save")
            enabled: editor.valid
            onClicked: editor.save()
        }
    }

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => {
            if (iconName) {
                editor.iconName = iconName;
            }
        }
        onVisibleChanged: editor.launcher.holdOpen = visible
    }

    FileDialog {
        id: fileDialog
        title: i18n("Choose Script File")
        onVisibleChanged: editor.launcher.holdOpen = visible
        onAccepted: {
            var path = Logic.fileUrlToPath(selectedFile);
            commandField.text = Logic.shellQuote(path);
            if (!nameField.text) {
                nameField.text = Logic.basename(path);
            }
        }
    }
}
