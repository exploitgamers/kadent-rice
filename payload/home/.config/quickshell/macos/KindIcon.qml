import QtQuick
import Quickshell
import Quickshell.Widgets

// Icon for a widget kind: its app's icon when it has one, else a symbol tile.
Item {
    id: ki

    property var kind
    property int size: 22

    implicitWidth: size
    implicitHeight: size

    readonly property var entry: kind?.appId && DesktopEntries.applications.values.length >= 0 ? (DesktopEntries.byId(kind.appId) ?? DesktopEntries.heuristicLookup(kind.appId)) : null

    IconImage {
        visible: ki.entry !== null
        anchors.fill: parent
        source: ki.entry ? Quickshell.iconPath(ki.entry.icon, "application-x-executable") : ""
    }

    Rectangle {
        visible: ki.entry === null
        anchors.fill: parent
        radius: ki.size * 0.28
        color: Theme.primary

        Text {
            anchors.centerIn: parent
            text: ki.kind?.glyph ?? "widgets"
            color: Theme.fgOnPrimary
            font.family: "Material Symbols Rounded"
            font.variableAxes: { "FILL": 1 }
            font.pixelSize: ki.size * 0.64
        }
    }
}
