pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Force Quit Applications (SUPER+ALT+Escape, like Cmd+Option+Esc):
// qs -c macos ipc call forcequit toggle. One row per app class with windows; Force Quit
// sends SIGTERM to its window processes, then SIGKILL after 2 s to any still alive.
// Built only while open (nothing to keep warm for a rarely used panel).
Scope {
    id: root

    property bool open: false

    // the shells and the compositor are never listed (their own windows, e.g. Desktop Settings)
    readonly property var protectedComms: ["quickshell", "qs", ".quickshell-wra", "Hyprland", "Xwayland"]

    // argv: class (as @tsv-escaped in the list), jq filter, pids
    readonly property string liveFilter: '.[] | select(.mapped and ([.class] | @tsv) == $c) | .pid'
    readonly property string killScript: 'c=$1; f=$2; shift 2; live=" $(hyprctl clients -j | jq -r --arg c "$c" "$f" | tr "\\n" " ") "; ok=""; for p; do case $live in *" $p "*) ok="$ok $p:$(ps -o lstart= -p "$p" | tr -d " ")";; esac; done; for e in $ok; do kill -TERM "${e%%:*}" 2>/dev/null; done; sleep 2; for e in $ok; do p=${e%%:*}; [ -n "${e#*:}" ] && [ "$p:$(ps -o lstart= -p "$p" | tr -d " ")" = "$e" ] && kill -KILL "$p" 2>/dev/null; done'

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win

            property var apps: [] // [{ cls, name, icon, pids }]
            property int selected: 0
            property bool confirming: false

            function close(): void {
                root.open = false;
            }

            function forceQuit(): void {
                const app = apps[selected];
                const pids = (app?.pids ?? []).filter(p => Number.isInteger(p) && p > 1);
                // The list may be minutes old: only signal PIDs that still own a window of this
                // class now, and SIGKILL only if the PID's start time is unchanged (not reused).
                if (pids.length)
                    Quickshell.execDetached(["sh", "-c", root.killScript, "sh", app.cls, root.liveFilter].concat(pids.map(String)));
                close();
            }

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            color: "transparent"
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "macos-forcequit"
            WlrLayershell.layer: WlrLayer.Overlay
            // covers the whole screen, so taking all input is fine: a click outside the panel closes it
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Process {
                running: true
                // pid<TAB>process name<TAB>class<TAB>title, one line per mapped window
                command: ["sh", "-c", 'hyprctl clients -j | jq -r \'.[] | select(.mapped and .pid > 1) | [.pid, .class, .title] | @tsv\' | while IFS="$(printf "\\t")" read -r p c t; do printf "%s\\t%s\\t%s\\t%s\\n" "$p" "$(cat /proc/$p/comm 2>/dev/null)" "$c" "$t"; done']
                stdout: StdioCollector {
                    onStreamFinished: {
                        const byClass = {};
                        for (const line of text.split("\n")) {
                            const [pid, comm, cls, title] = line.split("\t");
                            const p = parseInt(pid);
                            if (!p || !cls || root.protectedComms.includes(comm) || /quickshell|caelestia/i.test(cls))
                                continue;
                            const app = byClass[cls] ?? (byClass[cls] = { cls: cls, title: title, pids: [] });
                            if (!app.pids.includes(p))
                                app.pids.push(p);
                        }
                        win.apps = Object.values(byClass).map(a => {
                            const e = DesktopEntries.byId(a.cls) ?? DesktopEntries.heuristicLookup(a.cls);
                            return { cls: a.cls, pids: a.pids, name: e?.name || a.cls, icon: Quickshell.iconPath(e?.icon ?? a.cls, "application-x-executable") };
                        }).sort((a, b) => a.name.localeCompare(b.name));
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: win.close()
            }

            Rectangle {
                id: panel

                anchors.centerIn: parent
                width: 360
                height: body.implicitHeight + 32
                radius: Theme.panelRadius
                color: Theme.glassStrong
                border.width: 1
                border.color: Theme.glassBorder

                MouseArea { // clicks on the panel don't reach the close-on-click backdrop
                    anchors.fill: parent
                }

                focus: true
                Component.onCompleted: forceActiveFocus()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape)
                        win.confirming ? win.confirming = false : win.close();
                    else if (event.key === Qt.Key_Up && !win.confirming)
                        win.selected = Math.max(0, win.selected - 1);
                    else if (event.key === Qt.Key_Down && !win.confirming)
                        win.selected = Math.min(win.apps.length - 1, win.selected + 1);
                    else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && win.apps.length)
                        win.confirming ? win.forceQuit() : win.confirming = true;
                    else
                        return;
                    event.accepted = true;
                }

                Column {
                    id: body

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: "Force Quit Applications"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        textFormat: Text.PlainText
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 12
                        text: win.confirming
                            ? `Do you want to force “${win.apps[win.selected]?.name ?? ""}” to quit? You’ll lose any unsaved changes.`
                            : "If an app doesn’t respond for a while, select its name and click Force Quit."
                    }

                    Rectangle {
                        visible: !win.confirming
                        width: parent.width
                        height: Math.min(Math.max(win.apps.length, 1), 12) * 22 + 10
                        radius: Theme.menuRadius
                        color: Theme.alpha(Theme.fg, 0.05)

                        Text {
                            visible: win.apps.length === 0
                            anchors.centerIn: parent
                            text: "No open apps"
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 5
                            clip: true
                            model: win.apps
                            currentIndex: win.selected

                            delegate: Rectangle {
                                id: row

                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                height: 22 // macOS menu metrics, as in GlassMenu
                                radius: Theme.menuRadius - 5
                                color: win.selected === index ? Theme.alpha(Theme.primary, 0.7) : "transparent"

                                Image {
                                    id: icon

                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16
                                    sourceSize: Qt.size(32, 32)
                                    source: row.modelData.icon
                                }

                                Text {
                                    anchors.left: icon.right
                                    anchors.leftMargin: 7
                                    anchors.right: parent.right
                                    anchors.rightMargin: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    textFormat: Text.PlainText // untrusted window classes
                                    elide: Text.ElideRight
                                    text: row.modelData.name
                                    color: win.selected === row.index ? Theme.fgOnPrimary : Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: win.selected = row.index
                                    onDoubleClicked: win.confirming = true
                                }
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 8

                        component Button: Rectangle {
                            id: btn

                            property string label
                            property bool primary
                            signal clicked

                            width: Math.max(80, txt.implicitWidth + 24)
                            height: 24
                            radius: 7
                            opacity: enabled ? 1 : 0.4
                            color: primary ? Theme.alpha(Theme.primary, area.pressed ? 1 : 0.85) : Theme.alpha(Theme.fg, area.pressed ? 0.2 : 0.12)

                            Text {
                                id: txt

                                anchors.centerIn: parent
                                text: btn.label
                                color: btn.primary ? Theme.fgOnPrimary : Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: area

                                anchors.fill: parent
                                onClicked: btn.clicked()
                            }
                        }

                        Button {
                            label: "Cancel"
                            onClicked: win.confirming ? win.confirming = false : win.close()
                        }

                        Button {
                            label: "Force Quit"
                            primary: true
                            enabled: win.apps.length > 0
                            onClicked: win.confirming ? win.forceQuit() : win.confirming = true
                        }
                    }
                }
            }
        }
    }
}
