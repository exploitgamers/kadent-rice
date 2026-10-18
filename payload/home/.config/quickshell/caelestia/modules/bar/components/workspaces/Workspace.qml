pragma ComponentBehavior: Bound

import QtQuick
import ".." // [macos] BarInk
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

GridLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    required property bool horizontal
    required property BarInk ink // [macos] the pill's adaptive text colour

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: (horizontal ? implicitWidth : implicitHeight) + (hasWindows ? Tokens.padding.extraSmall : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    Layout.alignment: horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
    Layout.preferredWidth: horizontal ? size : -1
    Layout.preferredHeight: horizontal ? -1 : size

    columns: horizontal ? -1 : 1
    rowSpacing: 0
    columnSpacing: 0

    StyledText {
        id: indicator

        // [macos] centred in its fixed-width slot: left-aligned glyphs of different
        // widths (dot vs Pac-Man) put every marker at a different offset — uneven
        // gaps, off-centre in the active circle, extra room after the last one
        Layout.alignment: root.horizontal ? Qt.AlignVCenter | Qt.AlignHCenter : Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredWidth: root.horizontal ? Tokens.sizes.bar.innerWidth - 6 : -1
        horizontalAlignment: Text.AlignHCenter
        Layout.preferredHeight: root.horizontal ? -1 : Tokens.sizes.bar.innerWidth - 6

        animate: true
        text: {
            const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
            const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
            let displayName = wsName.toString();
            // [macos] 2.5 made this an enum
            if (Config.bar.workspaces.capitalisation === BarWorkspaceCapitalisation.Upper) {
                displayName = displayName.toUpperCase();
            } else if (Config.bar.workspaces.capitalisation === BarWorkspaceCapitalisation.Lower) {
                displayName = displayName.toLowerCase();
            }
            const label = Config.bar.workspaces.label || displayName;
            const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
            const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
            return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? root.ink.c(Colours.palette.m3onSurface) : root.ink.c(Colours.layer(Colours.palette.m3outlineVariant, 2))
        verticalAlignment: Qt.AlignVCenter
        font.family: Tokens.font.workspaces
        // [macos] sized with the bar, by the same factor as every other bar item (it looked right at 32 px; the bar is slimmer now
        // and the markers kept their size, filling the pills edge to edge)
        font.pointSize: Tokens.font.body.small.pointSize * Tokens.sizes.bar.innerWidth / 26
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignHCenter
        Layout.fillWidth: root.horizontal
        Layout.fillHeight: !root.horizontal
        // [macos] half the old pull-in: marker→first icon now matches the gap between icons
        Layout.leftMargin: root.horizontal ? -Tokens.sizes.bar.innerWidth / 20 : 0
        Layout.topMargin: root.horizontal ? 0 : -Tokens.sizes.bar.innerWidth / 10

        visible: active
        active: root.hasWindows

        sourceComponent: Grid {
            columns: root.horizontal ? Math.max(1, items.count) : 1
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                id: items

                model: ScriptModel {
                    values: {
                        const ws = root.ws;
                        const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    fontStyle: Tokens.font.icon.builders.small.scale(Tokens.sizes.bar.innerWidth / 26).build() // [macos] with the bar
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: root.ink.c(Colours.palette.m3onSurfaceVariant)
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }
}
