import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.configuration

import "../code/logic.js" as Logic

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-icons"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Layout & Presets")
        icon: Qt.resolvedUrl("../icons/" + Logic.defaultIconFile(Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark))
        source: "ConfigLayout.qml"
    }
    ConfigCategory {
        name: i18n("Popup")
        icon: "transform-move"
        source: "ConfigPopup.qml"
    }
}
