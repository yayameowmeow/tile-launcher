import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-icons"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Layout & Presets")
        icon: Qt.resolvedUrl("../icons/TiledLauncher.svg")
        source: "ConfigLayout.qml"
    }
    ConfigCategory {
        name: i18n("Popup")
        icon: "transform-move"
        source: "ConfigPopup.qml"
    }
}
