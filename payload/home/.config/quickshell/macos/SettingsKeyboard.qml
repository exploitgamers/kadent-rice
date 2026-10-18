pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Desktop Settings → Keyboard (Settings.qml): change the shortcut for each action.
// Choices are saved in macos.json "keybinds" (kb var name → "SUPER + X", "" = none);
// hypr-vars.lua reads them and Config.setKeybind reloads Hyprland to apply them.
// Modifiers are toggles rather than captured, because Hyprland swallows any combo
// that's already bound before it could reach this window.
Column {
    id: page

    // [kb var, what it does, default]
    readonly property var groups: [
        { title: "Desktop", items: [
            ["kbShowSidebar", "Show the side panel", "SUPER + N"],
            ["kbSpotlight", "Spotlight search", "SUPER + Space"],
            ["kbOverview", "Show all windows", "SUPER + grave"],
            ["kbShowDesktop", "Show the desktop", "SUPER + F3"],
            ["kbDesktopSettings", "Open Desktop Settings", "SUPER + I"],
            ["kbLock", "Lock the screen", "SUPER + L"],
            ["kbSession", "Power menu", "CTRL + ALT + Delete"],
            ["kbGameMode", "Game mode", "SUPER + F1"]] },
        { title: "Windows", items: [
            ["kbCloseWindow", "Close the window", "SUPER + Q"],
            ["kbMinimize", "Minimise the window", ""],
            ["kbHide", "Hide the app", "SUPER + H"],
            ["kbForceQuit", "Force Quit Applications", "SUPER + ALT + Escape"],
            ["kbWindowFullscreen", "Full screen", "SUPER + F"],
            ["kbToggleWindowFloating", "Float or tile the window", "SUPER + ALT + Space"],
            ["kbCenterWindow", "Centre the window", "CTRL + SUPER + Backslash"],
            ["kbPinWindow", "Show the window on all desktops", "SUPER + P"]] },
        { title: "Apps", items: [
            ["kbTerminal", "Terminal", "SUPER + T"],
            ["kbBrowser", "Web browser", "SUPER + W"],
            ["kbFileExplorer", "Files", "SUPER + E"],
            ["kbEditor", "Code editor", "SUPER + C"]] },
        { title: "Screenshots", items: [
            ["kbScreenshot", "Screenshot", "Print"],
            ["kbScreenshotRegion", "Screenshot of an area", "SUPER + SHIFT + ALT + S"],
            ["kbScreenshotFreeze", "Screenshot of an area (screen frozen)", "SUPER + SHIFT + S"]] }
    ]
    readonly property var modNames: ["SUPER", "CTRL", "ALT", "SHIFT"]
    readonly property var modLabels: ({ SUPER: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift" })

    // the shortcut being changed
    property string editing: ""
    property var mods: []
    property string key: ""
    readonly property string draft: key ? [...modNames.filter(m => mods.includes(m)), key].join(" + ") : ""

    function current(name: string, fallback: string): string {
        const v = Config.keybinds[name];
        return v === undefined ? fallback : v;
    }

    function norm(combo: string): string {
        return combo.toUpperCase().split("+").map(p => p.trim()).sort().join("+");
    }

    // the other action already using this combo, if any
    function conflict(name: string, combo: string): string {
        if (!combo)
            return "";
        for (const g of groups)
            for (const [n, label, def] of g.items)
                if (n !== name && current(n, def) && norm(current(n, def)) === norm(combo))
                    return label;
        return "";
    }

    function startEdit(name: string, combo: string): void {
        const parts = combo.split("+").map(p => p.trim()).filter(p => p);
        mods = parts.filter(p => modNames.includes(p.toUpperCase())).map(p => p.toUpperCase());
        key = parts.filter(p => !modNames.includes(p.toUpperCase())).join("") || "";
        editing = name;
    }

    function keyLabel(k: string): string {
        return ({ grave: "`", Backslash: "\\", Comma: ",", Period: ".", Slash: "/", Minus: "-", Equal: "=", Semicolon: ";",
            Apostrophe: "'", BracketLeft: "[", BracketRight: "]", Return: "Return", BackSpace: "⌫", Delete: "Del",
            Left: "←", Right: "→", Up: "↑", Down: "↓" })[k] ?? k;
    }

    // Qt key → the name Hyprland uses ("" = not usable)
    function keyName(k: int): string {
        if (k >= Qt.Key_A && k <= Qt.Key_Z)
            return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9)
            return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12)
            return "F" + (k - Qt.Key_F1 + 1);
        const named = {};
        named[Qt.Key_Space] = "Space";
        named[Qt.Key_Tab] = "Tab";
        named[Qt.Key_Return] = "Return";
        named[Qt.Key_Enter] = "Return";
        named[Qt.Key_Backspace] = "BackSpace";
        named[Qt.Key_Delete] = "Delete";
        named[Qt.Key_Left] = "Left";
        named[Qt.Key_Right] = "Right";
        named[Qt.Key_Up] = "Up";
        named[Qt.Key_Down] = "Down";
        named[Qt.Key_Home] = "Home";
        named[Qt.Key_End] = "End";
        named[Qt.Key_Print] = "Print";
        named[Qt.Key_QuoteLeft] = "grave";
        named[Qt.Key_Comma] = "Comma";
        named[Qt.Key_Period] = "Period";
        named[Qt.Key_Slash] = "Slash";
        named[Qt.Key_Backslash] = "Backslash";
        named[Qt.Key_Minus] = "Minus";
        named[Qt.Key_Equal] = "Equal";
        named[Qt.Key_BracketLeft] = "BracketLeft";
        named[Qt.Key_BracketRight] = "BracketRight";
        named[Qt.Key_Semicolon] = "Semicolon";
        named[Qt.Key_Apostrophe] = "Apostrophe";
        return named[k] ?? "";
    }

    spacing: 22

    // a shortcut drawn as key caps
    component KeyCaps: Row {
        id: caps

        property string combo

        spacing: 4

        Text {
            visible: caps.combo === ""
            anchors.verticalCenter: parent.verticalCenter
            text: "None"
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 12
        }

        Repeater {
            model: caps.combo ? caps.combo.split("+").map(p => p.trim()) : []

            Rectangle {
                id: cap

                required property string modelData

                width: Math.max(24, capText.implicitWidth + 12)
                height: 22
                radius: 5
                color: Theme.alpha(Theme.fg, 0.1)
                border.width: 1
                border.color: Theme.alpha(Theme.fg, 0.14)

                Text {
                    id: capText

                    anchors.centerIn: parent
                    text: page.modLabels[cap.modelData.toUpperCase()] ?? page.keyLabel(cap.modelData)
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Click Change, choose the modifier keys, then press the key. Changes apply straight away."
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: 12
    }

    Repeater {
        model: page.groups

        SettingsUi.Group {
            id: group

            required property var modelData

            title: modelData.title

            Repeater {
                model: group.modelData.items

                SettingsUi.Setting {
                    id: row

                    required property var modelData
                    readonly property string name: modelData[0]
                    readonly property string combo: page.current(name, modelData[2])
                    readonly property bool editingThis: page.editing === name
                    readonly property string clash: editingThis ? page.conflict(name, page.draft) : ""

                    label: modelData[1]
                    detail: clash ? "Also used for “" + clash + "”" : ""

                    Row {
                        spacing: 6

                        // ── showing ──
                        KeyCaps {
                            visible: !row.editingThis
                            anchors.verticalCenter: parent.verticalCenter
                            combo: row.combo
                        }

                        SettingsUi.Button {
                            visible: !row.editingThis && Config.keybinds[row.name] !== undefined
                            text: "Reset"
                            onClicked: Config.setKeybind(row.name, null)
                        }

                        SettingsUi.Button {
                            visible: !row.editingThis
                            text: "Change"
                            onClicked: page.startEdit(row.name, row.combo)
                        }

                        // ── changing ──
                        Repeater {
                            model: row.editingThis ? page.modNames : []

                            Rectangle {
                                id: mod

                                required property string modelData
                                readonly property bool on: page.mods.includes(modelData)

                                anchors.verticalCenter: parent.verticalCenter
                                width: modText.implicitWidth + 16
                                height: 24
                                radius: 6
                                color: on ? Theme.primary : Theme.alpha(Theme.fg, 0.08)

                                Text {
                                    id: modText

                                    anchors.centerIn: parent
                                    text: page.modLabels[mod.modelData]
                                    color: mod.on ? Theme.fgOnPrimary : Theme.fgDim
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: page.mods = mod.on ? page.mods.filter(m => m !== mod.modelData) : [...page.mods, mod.modelData]
                                }
                            }
                        }

                        // the key: press it while this box has focus
                        Rectangle {
                            visible: row.editingThis
                            anchors.verticalCenter: parent.verticalCenter
                            width: 92
                            height: 24
                            radius: 6
                            color: Theme.alpha(Theme.fg, 0.08)
                            border.width: 2
                            border.color: Theme.primary
                            focus: row.editingThis
                            onVisibleChanged: if (visible) forceActiveFocus()

                            Text {
                                anchors.centerIn: parent
                                text: page.key ? page.keyLabel(page.key) : "Press a key"
                                color: page.key ? Theme.fg : Theme.fgDim
                                font.family: Theme.font
                                font.pixelSize: 11
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    page.editing = "";
                                } else {
                                    const name = page.keyName(event.key);
                                    if (name)
                                        page.key = name;
                                    // Ctrl / Alt / Shift held while pressing it count too
                                    const held = [];
                                    if (event.modifiers & Qt.ControlModifier)
                                        held.push("CTRL");
                                    if (event.modifiers & Qt.AltModifier)
                                        held.push("ALT");
                                    if (event.modifiers & Qt.ShiftModifier)
                                        held.push("SHIFT");
                                    if (event.modifiers & Qt.MetaModifier)
                                        held.push("SUPER");
                                    if (name && held.length)
                                        page.mods = held;
                                }
                                event.accepted = true;
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: parent.forceActiveFocus()
                            }
                        }

                        SettingsUi.Button {
                            visible: row.editingThis
                            text: "None"
                            onClicked: {
                                Config.setKeybind(row.name, "");
                                page.editing = "";
                            }
                        }

                        SettingsUi.Button {
                            visible: row.editingThis
                            text: "Cancel"
                            onClicked: page.editing = ""
                        }

                        SettingsUi.Button {
                            visible: row.editingThis
                            text: "Save"
                            accent: true
                            opacity: page.draft ? 1 : 0.4
                            onClicked: {
                                if (!page.draft)
                                    return;
                                Config.setKeybind(row.name, page.draft);
                                page.editing = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
