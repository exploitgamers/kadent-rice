import QtQuick
import Quickshell
import Quickshell.Widgets

// Apps widget: your launcher favourites as big buttons (Apps launcher → pin).
// Small 4, medium 8, large 16 apps. Click to open.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    function activate(): void {
        Shared.toggleLauncher();
    }

    readonly property int cols: size === "small" ? 2 : 4
    readonly property int rows: size === "large" ? 4 : 2
    // DesktopEntries.byId isn't reactive: touching the list re-runs this once apps load
    readonly property var apps: DesktopEntries.applications.values.length < 0 ? [] : Config.launcherPinned
        .map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id))
        .filter(e => e)
        .slice(0, cols * rows)

    Grid {
        anchors.centerIn: parent
        columns: root.cols
        rowSpacing: root.size === "small" ? 10 : 8
        columnSpacing: root.size === "small" ? 14 : 12

        Repeater {
            model: root.apps

            Item {
                id: app

                required property var modelData

                width: root.size === "small" ? 60 : 72
                height: root.size === "small" ? 60 : 66

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.size === "small" ? 4 : 2
                    implicitSize: root.size === "small" ? 52 : 44
                    source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
                    scale: tap.pressed ? 0.88 : hover.hovered ? 1.08 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                Text {
                    visible: root.size !== "small"
                    anchors.bottom: parent.bottom
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: app.modelData.name
                    elide: Text.ElideRight
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 11
                }

                HoverHandler {
                    id: hover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: tap

                    onTapped: { Shared.widgetTapAt = Date.now(); app.modelData.execute() }
                }
            }
        }
    }
}
