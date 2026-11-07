import QtQuick
import QtTest

import "../package/contents/code/logic.js" as Logic

TestCase {
    name: "Logic"

    function layout(columns, tileWidth, spacing) {
        return { columns: columns, tileWidth: tileWidth, spacing: spacing };
    }

    function test_effectiveColumns_fixedCountIgnoresWidth() {
        compare(Logic.effectiveColumns(layout(3, 96, 4), 10), 3);
    }

    function test_effectiveColumns_fitsToWidth() {
        // 3 tiles of 96 with 2 gaps of 4 take exactly 296.
        compare(Logic.effectiveColumns(layout(0, 96, 4), 296), 3);
        compare(Logic.effectiveColumns(layout(0, 96, 4), 295), 2);
    }

    function test_effectiveColumns_alwaysAtLeastOne() {
        compare(Logic.effectiveColumns(layout(0, 96, 4), 0), 1);
    }

    function test_pack_singleCellsFlowInOrder() {
        var packed = Logic.pack([{}, {}, {}], 2);
        compare(packed.rows, 2);
        compare(packed.cells[0].col, 0);
        compare(packed.cells[1].col, 1);
        compare(packed.cells[2].row, 1);
        compare(packed.cells[2].col, 0);
    }

    function test_pack_spanSkipsToRowWhereItFits() {
        var packed = Logic.pack([{}, { w: 2 }], 2);
        compare(packed.cells[1].row, 1);
        compare(packed.cells[1].col, 0);
    }

    function test_pack_laterTileFillsGapLeftByWideTile() {
        var packed = Logic.pack([{}, { w: 2 }, {}], 2);
        compare(packed.cells[2].row, 0);
        compare(packed.cells[2].col, 1);
    }

    function test_pack_tallTileBlocksCellsBelow() {
        var packed = Logic.pack([{ h: 2 }, {}, {}], 2);
        compare(packed.cells[1].col, 1);
        compare(packed.cells[1].row, 0);
        compare(packed.cells[2].col, 1);
        compare(packed.cells[2].row, 1);
        compare(packed.rows, 2);
    }

    function test_pack_clampsSpanWiderThanGrid() {
        var packed = Logic.pack([{ w: 8 }], 2);
        compare(packed.cells[0].w, 2);
        compare(packed.rows, 1);
    }

    function test_pack_empty() {
        compare(Logic.pack([], 3).rows, 0);
    }

    function test_popupOffset_automaticHasNone() {
        compare(Logic.popupOffset(Logic.PLACEMENT_AUTO, { width: 100, height: 100 }, { width: 10, height: 10 }, { x: 1, y: 1 }), null);
    }

    function test_popupOffset_centers() {
        var offset = Logic.popupOffset(Logic.PLACEMENT_CENTER, { width: 1280, height: 900 }, { width: 500, height: 300 }, { x: 0, y: 0 });
        compare(offset.x, 390);
        compare(offset.y, 300);
    }

    function test_popupOffset_customIsKeptOnScreen() {
        var size = { width: 500, height: 300 };
        var screen = { width: 1280, height: 900 };
        compare(Logic.popupOffset(Logic.PLACEMENT_CUSTOM, screen, size, { x: 100, y: 60 }).x, 100);
        compare(Logic.popupOffset(Logic.PLACEMENT_CUSTOM, screen, size, { x: 5000, y: 5000 }).x, 780);
        compare(Logic.popupOffset(Logic.PLACEMENT_CUSTOM, screen, size, { x: 5000, y: 5000 }).y, 600);
    }

    function test_popupOffset_popupLargerThanScreen() {
        var offset = Logic.popupOffset(Logic.PLACEMENT_CENTER, { width: 100, height: 100 }, { width: 500, height: 300 }, { x: 0, y: 0 });
        compare(offset.x, 0);
        compare(offset.y, 0);
    }

    function test_defaultIconFile_followsTheme() {
        compare(Logic.defaultIconFile(true), "TiledLauncherDark.svg");
        compare(Logic.defaultIconFile(false), "TiledLauncher.svg");
    }

    function test_shellQuote_escapesSingleQuotes() {
        compare(Logic.shellQuote("it's"), "'it'\\''s'");
    }

    function test_parseItems_survivesCorruptConfig() {
        compare(Logic.parseItems("{not json").length, 0);
        compare(Logic.parseItems("{\"a\":1}").length, 0);
    }

    function test_normalizeItem_fillsDefaults() {
        var item = Logic.normalizeItem({ type: "app", name: "X" });
        compare(item.type, "app");
        compare(item.w, 1);
        compare(item.terminal, false);
        verify(item.id.length > 0);
        compare(Logic.normalizeItem({ w: "junk" }).w, 1);
        compare(Logic.normalizeItem({}).type, "command");
    }

    function test_launchCommand_appUsesQuotedPath() {
        var command = Logic.launchCommand({ type: "app" }, "/a b/x.desktop");
        compare(command, "setsid -f kioclient exec '/a b/x.desktop' >/dev/null 2>&1");
    }

    function test_launchCommand_scriptIsDetachedAndCdsToHome() {
        var command = Logic.launchCommand({ type: "command", command: "echo hi", name: "T" });
        verify(command.indexOf("setsid -f sh -c ") === 0);
        verify(command.indexOf("cd \"$HOME\"") >= 0);
        verify(command.indexOf("notify-send") >= 0);
    }

    function test_launchCommand_terminalKeepsWindowOpen() {
        var command = Logic.launchCommand({ type: "command", command: "echo hi", terminal: true, workdir: "/tmp" });
        verify(command.indexOf("TerminalApplication") >= 0);
        verify(command.indexOf("read _") >= 0);
        verify(command.indexOf("cd '\\''/tmp'\\''") >= 0);
    }

    function test_classifyUrl() {
        var cases = [
            ["applications:org.kde.kate.desktop", "desktopId", "org.kde.kate.desktop"],
            ["file:///usr/share/applications/org.kde.kate.desktop", "desktopFile", "/usr/share/applications/org.kde.kate.desktop"],
            ["file:///home/me/my%20script.sh", "file", "/home/me/my script.sh"],
            ["https://kde.org", "url", "https://kde.org"]
        ];
        cases.forEach(c => {
            var result = Logic.classifyUrl(c[0]);
            compare(result.kind, c[1]);
            compare(result.value, c[2]);
        });
    }

    function test_parseDesktopEntry_ignoresOtherGroups() {
        var text = "[Desktop Action new]\nName=Wrong\nIcon=wrong\n[Desktop Entry]\nName=Right\nName[de]=Recht\nIcon=right\n";
        var entry = Logic.parseDesktopEntry(text);
        compare(entry.name, "Right");
        compare(entry.icon, "right");
    }

    function test_builtinPresetsAreComplete() {
        verify(Logic.BUILTIN_PRESETS.length >= 3);
        Logic.BUILTIN_PRESETS.forEach(preset => {
            Logic.LAYOUT_KEYS.forEach(key => verify(preset.layout[key] !== undefined, preset.id + " lacks " + key));
        });
    }
}
