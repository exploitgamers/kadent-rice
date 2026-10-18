import QtQuick
import Quickshell

// Claude widget: quick actions from Claude's launcher entry (New Chat, New Claude
// Code Session…) plus opening the app. Header opens Claude.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    // (touching the app list makes this update once apps have loaded)
    readonly property var entry: DesktopEntries.applications.values.length < 0 ? null
        : DesktopEntries.byId("com.anthropic.Claude") ?? DesktopEntries.heuristicLookup("claude")
    readonly property var actions: entry?.actions ?? []

    function glyphFor(name: string): string {
        return name.toLowerCase().includes("code") ? "terminal" : "edit_square";
    }

    AppHeader {
        id: header

        x: 16
        y: 13
        appId: "com.anthropic.Claude"
        title: "Claude"
    }

    Column {
        x: 16
        y: 46
        width: root.width - 32
        spacing: 4

        Repeater {
            model: root.actions

            AppRow {
                required property var modelData

                width: parent.width
                icon: root.glyphFor(modelData.name)
                label: root.size === "small" ? modelData.name.replace("New Claude Code Session", "New Code Session") : modelData.name
                detail: root.size !== "small" ? (modelData.name.toLowerCase().includes("code") ? "Start coding with Claude" : "Ask Claude anything") : ""
                onActivated: modelData.execute()
            }
        }

        AppRow {
            width: parent.width
            icon: "open_in_new"
            label: "Open Claude"
            visible: root.size !== "small" || root.actions.length < 2
            onActivated: root.entry?.execute()
        }
    }

    Text {
        visible: !root.entry
        anchors.centerIn: parent
        text: "Claude isn't installed"
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: 12
    }
}
