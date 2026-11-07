import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "../code/logic.js" as Logic

KCM.SimpleKCM {
    id: page

    property string cfg_presetId
    property int cfg_columns
    property int cfg_tileWidth
    property int cfg_tileHeight
    property int cfg_iconSize
    property int cfg_labelMode
    property int cfg_spacing
    property int cfg_tileStyle

    readonly property var presetChoices: [{ id: "", name: i18n("Custom (this widget only)") }].concat(
        store.all.map(p => ({
            id: p.id,
            name: p.id.indexOf("custom:") === 0 ? i18n("%1 (shared)", p.name) : p.name
        })))
    readonly property bool customPresetSelected: cfg_presetId.indexOf("custom:") === 0 && store.find(cfg_presetId) !== null
    readonly property var overwriteTarget: store.findCustomByName(saveName.text)

    function currentLayout() {
        return {
            columns: cfg_columns,
            tileWidth: cfg_tileWidth,
            tileHeight: cfg_tileHeight,
            iconSize: cfg_iconSize,
            labelMode: cfg_labelMode,
            spacing: cfg_spacing,
            tileStyle: cfg_tileStyle
        };
    }

    function applyPreset(id) {
        cfg_presetId = id;
        var preset = store.find(id);
        if (preset) {
            Logic.LAYOUT_KEYS.forEach(key => {
                if (preset.layout[key] !== undefined) {
                    page["cfg_" + key] = preset.layout[key];
                }
            });
        }
    }

    function savePreset() {
        var name = saveName.text.trim();
        if (name) {
            cfg_presetId = store.save(name, currentLayout());
            saveName.text = "";
        }
    }

    PresetStore {
        id: store
    }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: presetBox

            Kirigami.FormData.label: i18n("Preset:")
            model: page.presetChoices
            textRole: "name"
            valueRole: "id"
            currentIndex: Math.max(0, page.presetChoices.findIndex(p => p.id === page.cfg_presetId))
            onActivated: page.applyPreset(currentValue)
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Share as preset:")

            QQC2.TextField {
                id: saveName
                Layout.fillWidth: true
                placeholderText: i18n("Preset name")
                onAccepted: page.savePreset()
            }
            QQC2.Button {
                icon.name: "document-save"
                text: page.overwriteTarget ? i18n("Overwrite") : i18n("Save")
                enabled: saveName.text.trim().length > 0
                onClicked: page.savePreset()
            }
        }

        QQC2.Button {
            icon.name: "edit-delete"
            text: i18n("Delete Selected Preset")
            enabled: page.customPresetSelected
            onClicked: {
                store.remove(page.cfg_presetId);
                page.cfg_presetId = "";
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            text: i18n("Saved presets are available in every Tile Launcher. Widgets using a preset update when it is overwritten. Changing a value below makes this widget's layout its own again.")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: fitBox
            Kirigami.FormData.label: i18n("Columns:")
            text: i18n("Fit as many as the width allows")
            checked: page.cfg_columns === 0
            onToggled: {
                page.cfg_presetId = "";
                page.cfg_columns = checked ? 0 : 2;
            }
        }
        QQC2.SpinBox {
            enabled: page.cfg_columns !== 0
            from: 1
            to: 32
            value: Math.max(1, page.cfg_columns)
            onValueModified: {
                page.cfg_presetId = "";
                page.cfg_columns = value;
            }
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Tile width:")
            enabled: page.cfg_columns === 0
            from: 16
            to: 1024
            value: page.cfg_tileWidth
            onValueModified: {
                page.cfg_presetId = "";
                page.cfg_tileWidth = value;
            }
            QQC2.ToolTip.text: i18n("With a fixed column count, tiles share the popup's width equally.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Tile height:")
            from: 16
            to: 1024
            value: page.cfg_tileHeight
            onValueModified: {
                page.cfg_presetId = "";
                page.cfg_tileHeight = value;
            }
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Icon size:")
            from: 8
            to: 512
            value: page.cfg_iconSize
            onValueModified: {
                page.cfg_presetId = "";
                page.cfg_iconSize = value;
            }
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Spacing:")
            from: 0
            to: 64
            value: page.cfg_spacing
            onValueModified: {
                page.cfg_presetId = "";
                page.cfg_spacing = value;
            }
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Names:")
            model: [i18n("Under the icon"), i18n("Beside the icon"), i18n("Hidden")]
            currentIndex: page.cfg_labelMode
            onActivated: {
                page.cfg_presetId = "";
                page.cfg_labelMode = currentIndex;
            }
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Tile style:")
            model: [i18n("Flat"), i18n("Filled")]
            currentIndex: page.cfg_tileStyle
            onActivated: {
                page.cfg_presetId = "";
                page.cfg_tileStyle = currentIndex;
            }
        }
    }
}
