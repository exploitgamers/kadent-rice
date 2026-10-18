pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Edit Stack (right-click a stack → Edit Stack…), like macOS / iOS:
//   · drag the ≡ handles to reorder (top = front)
//   · ⊖ removes a widget from the stack (and the desktop)
//   · Smart Rotate: let the stack bring the most relevant widget to the front
//     (time of day, rain on the way, music playing, low battery… SmartRotate.qml)
PanelWindow {
    id: sheet

    required property ShellScreen modelData

    // the stack being edited; copied when the sheet opens (and kept while it
    // closes) so closing can't feed back into it
    property string stackKey: ""
    readonly property bool shown: Shared.editStackKey !== "" && Shared.editStackScreen === modelData?.name
    readonly property var members: stackKey ? Config.widgetItems.filter(w => Config.stackKey(w) === stackKey)
        .sort((a, b) => (a.order ?? 0) - (b.order ?? 0)) : []

    // local order while dragging (ids, front first)
    property var ids: []
    property string draggingId: ""
    property real dragY: 0
    readonly property int rowH: 58

    onMembersChanged: {
        if (!draggingId)
            ids = members.map(m => m.id);
        if (shown && members.length < 2)
            Qt.callLater(close);
    }
    onShownChanged: {
        grabArmed = false;
        if (shown) {
            stackKey = Shared.editStackKey;
            ids = members.map(m => m.id);
            armGrab.restart();
        }
    }

    function close(): void {
        Shared.editStackKey = "";
    }

    screen: modelData
    color: "transparent"
    implicitWidth: 420
    implicitHeight: list.y + Math.max(1, ids.length) * rowH + 50
    exclusionMode: ExclusionMode.Ignore
    visible: shown || pop.value > 0.01

    WlrLayershell.namespace: "macos-gallery"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool grabArmed: false

    Timer {
        id: armGrab

        interval: 80
        onTriggered: sheet.grabArmed = sheet.shown
    }

    HyprlandFocusGrab {
        windows: [sheet]
        active: sheet.shown && sheet.grabArmed
        onCleared: sheet.close()
    }


    Spring {
        id: pop

        target: sheet.shown ? 1 : 0
        response: 0.3
        epsilon: 0.002
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        radius: Theme.panelRadius
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.glassBorder
        opacity: pop.value
        scale: 0.94 + 0.06 * pop.value

        focus: sheet.shown
        Keys.onEscapePressed: sheet.close()

        Text {
            x: 14
            y: 18
            text: "Edit Stack"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 18
            font.weight: Font.Bold
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 15
            // same macOS blue Done as the widget gallery
            width: doneText.implicitWidth + 32
            height: 28
            radius: 7
            color: doneArea.pressed ? Qt.darker("#0a84ff", 1.15) : "#0a84ff"

            Text {
                id: doneText

                anchors.centerIn: parent
                text: "Done"
                color: "white"
                font.family: Theme.font
                font.pixelSize: 13 // same Done as the widget gallery
                font.weight: Font.Medium
            }

            MouseArea {
                id: doneArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sheet.close()
            }
        }

        // ── Smart Rotate ────────────────────────────────────────────────
        Rectangle {
            id: smart

            x: 14
            y: 58
            width: parent.width - 28
            height: 58
            radius: 12
            color: Theme.alpha(Theme.fg, 0.06)

            readonly property bool on: sheet.stackKey !== "" && Config.smartRotate(sheet.stackKey)

            Column {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 90

                Text {
                    text: "Smart Rotate"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: "Brings the most relevant widget to the front"
                    elide: Text.ElideRight
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }

            // switch
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 46
                height: 26
                radius: 13
                color: smart.on ? "#30d158" : Theme.alpha(Theme.fg, 0.2)

                Behavior on color {
                    ColorAnimation { duration: 180 }
                }

                Rectangle {
                    x: smart.on ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: "white"

                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.setSmartRotate(sheet.stackKey, !smart.on)
                }
            }
        }

        Text {
            x: 14
            y: smart.y + smart.height + 14
            text: "WIDGETS — TOP IS IN FRONT"
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
        }

        // ── reorderable list ────────────────────────────────────────────
        Item {
            id: list

            x: 14
            y: smart.y + smart.height + 34
            width: parent.width - 28
            height: sheet.ids.length * sheet.rowH

            Repeater {
                model: sheet.members

                Rectangle {
                    id: row

                    required property var modelData

                    readonly property var kind: WidgetTypes.kind(modelData.type)
                    readonly property int slot: sheet.ids.indexOf(modelData.id)
                    readonly property bool dragged: sheet.draggingId === modelData.id

                    width: list.width
                    height: sheet.rowH - 6
                    radius: 12
                    y: dragged ? sheet.dragY : slot * sheet.rowH
                    z: dragged ? 10 : 0
                    scale: dragged ? 1.03 : 1
                    color: dragged ? Theme.alpha(Theme.fg, 0.14) : Theme.alpha(Theme.fg, 0.06)
                    border.width: dragged ? 1 : 0
                    border.color: Theme.glassBorder

                    Behavior on y {
                        enabled: !row.dragged
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 150 }
                    }

                    // remove
                    Rectangle {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        radius: 11
                        color: removeArea.containsMouse ? "#ff3b30" : "#ff5f57"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 2
                            radius: 1
                            color: "white"
                        }

                        MouseArea {
                            id: removeArea

                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.removeFromStack(row.modelData.id)
                        }
                    }

                    KindIcon {
                        x: 46
                        anchors.verticalCenter: parent.verticalCenter
                        kind: row.kind
                        size: 30
                    }

                    Column {
                        x: 88
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: row.kind?.name ?? row.modelData.type
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        Text {
                            text: row.slot === 0 ? "In front" : WidgetTypes.sizeName(row.modelData.size)
                            color: row.slot === 0 ? Theme.primary : Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 11
                        }
                    }

                    // drag handle
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "drag_handle"
                        color: handle.containsMouse || row.dragged ? Theme.fg : Theme.fgDim
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24

                        MouseArea {
                            id: handle

                            anchors.fill: parent
                            anchors.margins: -10
                            hoverEnabled: true
                            cursorShape: row.dragged ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            property real grabY

                            onPressed: m => {
                                grabY = mapToItem(row, m.x, m.y).y;
                                sheet.dragY = row.y;
                                sheet.draggingId = row.modelData.id;
                            }
                            onPositionChanged: m => {
                                if (!pressed)
                                    return;
                                const y = mapToItem(list, m.x, m.y).y - grabY;
                                sheet.dragY = Math.max(-8, Math.min(y, list.height - sheet.rowH + 8));
                                // live reorder: the others slide out of the way
                                const to = Math.max(0, Math.min(sheet.ids.length - 1, Math.round(sheet.dragY / sheet.rowH)));
                                const from = sheet.ids.indexOf(row.modelData.id);
                                if (to !== from) {
                                    const next = sheet.ids.filter(i => i !== row.modelData.id);
                                    next.splice(to, 0, row.modelData.id);
                                    sheet.ids = next;
                                }
                            }
                            onReleased: {
                                sheet.draggingId = "";
                                Config.setStackOrder(sheet.stackKey, sheet.ids);
                            }
                        }
                    }
                }
            }
        }

        Text {
            x: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            width: parent.width - 28
            wrapMode: Text.WordWrap
            text: "To add a widget, drag it onto the stack on your desktop."
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 11
        }
    }
}
