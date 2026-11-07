import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "../code/logic.js" as Logic

KCM.SimpleKCM {
    id: page

    property alias cfg_windowWidth: widthBox.value
    property alias cfg_windowHeight: heightBox.value
    property alias cfg_popupPlacement: placementBox.currentIndex
    property alias cfg_popupX: xBox.value
    property alias cfg_popupY: yBox.value

    readonly property bool customPosition: placementBox.currentIndex === Logic.PLACEMENT_CUSTOM

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: widthBox
            Kirigami.FormData.label: i18n("Width (px):")
            from: 0
            to: 16384
            stepSize: 10
        }
        QQC2.SpinBox {
            id: heightBox
            Kirigami.FormData.label: i18n("Height (px):")
            from: 0
            to: 16384
            stepSize: 10
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: placementBox
            Kirigami.FormData.label: i18n("Position:")
            model: [i18n("Next to the widget"), i18n("Center of the screen"), i18n("Custom position")]
        }
        QQC2.SpinBox {
            id: xBox
            Kirigami.FormData.label: i18n("From left (px):")
            enabled: page.customPosition
            from: 0
            to: 16384
            stepSize: 10
        }
        QQC2.SpinBox {
            id: yBox
            Kirigami.FormData.label: i18n("From top (px):")
            enabled: page.customPosition
            from: 0
            to: 16384
            stepSize: 10
        }
        QQC2.Label {
            Kirigami.FormData.isSection: false
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18n("Measured from the top-left corner of the screen the widget is on. The popup is kept on screen. Dragging the popup's edges also changes the size here. A size of 0 leaves it to Plasma.")
        }
    }
}
