pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Desktop Settings → Displays & Battery, the monitors part (Settings.qml):
// resolution, scale, arrangement, on/off per monitor. A change applies live, then
// asks to be kept; without "Keep" it reverts after 15 s — like macOS — so a bad
// mode can't leave you with an unusable screen. Kept choices are saved by
// hypr-qol.lua (mac_display_save → hypr-displays.lua) and win over other rules.
Column {
    id: page

    property var monitors: []
    property var pending: null // { name, prev: spec, next: spec }
    property int countdown: 0

    function spec(m: var): var {
        return { name: m.name, mode: `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}Hz`, scale: m.scale, position: `${m.x}x${m.y}`, disabled: m.disabled };
    }

    function lua(fn: string, s: var): void {
        Hyprland.dispatch(`${fn}("${s.name}", "${s.mode}", ${s.scale}, "${s.position}", ${s.disabled}) or hl.dsp.event("macack")`);
    }

    function change(m: var, changes: var): void {
        if (pending)
            revert(); // one change at a time
        const prev = spec(m);
        const next = Object.assign({}, prev, changes);
        pending = { name: m.name, prev: prev, next: next };
        countdown = 15;
        lua("mac_display_set", next);
        refresh.restart();
    }

    function keep(): void {
        if (!pending)
            return;
        lua("mac_display_save", pending.next);
        pending = null;
    }

    function revert(): void {
        if (!pending)
            return;
        lua("mac_display_set", pending.prev);
        pending = null;
        refresh.restart();
    }

    spacing: 22

    Process {
        id: list

        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.monitors = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Timer { // re-read once Hyprland has applied a change
        id: refresh

        interval: 1200
        onTriggered: list.running = true
    }

    Timer {
        running: page.pending !== null
        interval: 1000
        repeat: true
        onTriggered: {
            page.countdown -= 1;
            if (page.countdown <= 0)
                page.revert();
        }
    }

    Component.onDestruction: revert() // closing the window without keeping reverts

    // ── keep / revert ───────────────────────────────────────────────
    Rectangle {
        visible: page.pending !== null
        width: parent.width
        height: 56
        radius: 10
        color: Theme.alpha(Theme.primary, 0.18)
        border.width: 1
        border.color: Theme.alpha(Theme.primary, 0.5)

        Text {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "Keep these display settings?  Reverting in " + page.countdown + " s"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SettingsUi.Button {
                text: "Revert"
                onClicked: page.revert()
            }

            SettingsUi.Button {
                text: "Keep"
                accent: true
                onClicked: page.keep()
            }
        }
    }

    Repeater {
        model: page.monitors

        SettingsUi.Group {
            id: mon

            required property var modelData
            readonly property bool builtIn: modelData.name.startsWith("eDP") || modelData.name.startsWith("LVDS")
            readonly property int enabledCount: page.monitors.filter(m => !m.disabled).length

            title: builtIn ? "Built-in Display" : (modelData.make && modelData.model ? modelData.make + " " + modelData.model : modelData.name)
            note: modelData.disabled ? "Turned off." : (modelData.width + " × " + modelData.height + " at " + Math.round(modelData.refreshRate) + " Hz, looks like "
                + Math.round(modelData.width / modelData.scale) + " × " + Math.round(modelData.height / modelData.scale))

            SettingsUi.Setting {
                visible: page.monitors.length > 1
                height: visible ? implicitHeight : 0
                label: "Use this display"
                detail: !mon.modelData.disabled && mon.enabledCount <= 1 ? "Your only screen that's on" : ""
                SettingsUi.Toggle {
                    checked: !mon.modelData.disabled
                    onToggled: on => {
                        if (on || mon.enabledCount > 1)
                            page.change(mon.modelData, { disabled: !on });
                    }
                }
            }

            SettingsUi.Setting {
                visible: !mon.modelData.disabled
                height: visible ? implicitHeight : 0
                label: "Resolution"
                SettingsUi.Choice {
                    width: 220
                    options: [...new Set(mon.modelData.availableModes ?? [])].map(m => [m, m.replace("@", "  ·  ").replace(/\.\d+Hz$/, " Hz").replace("x", " × ")])
                    value: page.spec(mon.modelData).mode
                    onPicked: v => page.change(mon.modelData, { mode: v })
                }
            }

            SettingsUi.Setting {
                visible: !mon.modelData.disabled
                height: visible ? implicitHeight : 0
                label: "Scale"
                detail: "Larger makes text and windows bigger"
                SettingsUi.Segmented {
                    options: [["1", "100%"], ["1.25", "125%"], ["1.5", "150%"], ["1.75", "175%"], ["2", "200%"]]
                    value: String(mon.modelData.scale)
                    onPicked: v => page.change(mon.modelData, { scale: Number(v) })
                }
            }

            SettingsUi.Setting {
                id: posRow

                // only matters while the laptop panel is on too
                readonly property var other: page.monitors.find(m => m.name !== mon.modelData.name && !m.disabled) ?? null

                visible: !mon.builtIn && !mon.modelData.disabled && other !== null
                height: visible ? implicitHeight : 0
                label: "Position"
                detail: "Where it sits next to your laptop"
                SettingsUi.Segmented {
                    options: [["auto-left", "Left"], ["auto-up", "Above"], ["auto-right", "Right"]]
                    // where it is now, from the two screens' positions
                    value: !posRow.other ? "" : mon.modelData.y + mon.modelData.height <= posRow.other.y ? "auto-up"
                        : mon.modelData.x < posRow.other.x ? "auto-left" : "auto-right"
                    onPicked: v => page.change(mon.modelData, { position: v })
                }
            }
        }
    }
}
