import QtQuick
import QtQuick.Controls as QQC2

import org.kde.iconthemes as KIconThemes
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_widgetName: nameField.text
    property alias cfg_showName: showNameBox.checked
    property string cfg_widgetIcon

    Kirigami.FormLayout {
        QQC2.TextField {
            id: nameField
            Kirigami.FormData.label: i18n("Name:")
            placeholderText: i18n("Tile Launcher")
        }

        QQC2.CheckBox {
            id: showNameBox
            text: i18n("Show name next to the icon")
        }

        QQC2.Button {
            id: iconButton

            Kirigami.FormData.label: i18n("Icon:")
            implicitWidth: Kirigami.Units.iconSizes.huge + Kirigami.Units.largeSpacing * 2
            implicitHeight: implicitWidth
            onClicked: iconDialog.open()
            QQC2.ToolTip.text: i18n("Choose icon…")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

            contentItem: Kirigami.Icon {
                source: page.cfg_widgetIcon || Qt.resolvedUrl("../icons/TiledLauncher.svg")
            }
        }

        QQC2.Button {
            icon.name: "edit-undo"
            text: i18n("Use Default Icon")
            enabled: page.cfg_widgetIcon !== ""
            onClicked: page.cfg_widgetIcon = ""
        }
    }

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: iconName => {
            if (iconName) {
                page.cfg_widgetIcon = iconName;
            }
        }
    }
}
