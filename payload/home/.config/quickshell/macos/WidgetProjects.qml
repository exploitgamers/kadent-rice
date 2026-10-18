import QtQuick
import Quickshell

// Recent-projects widget for one app (VSCodium folders or Kdenlive projects).
// Header opens the app; a project opens in it. Used by WidgetCode / WidgetKdenlive.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    property string appId
    property string appTitle
    property string binary
    property string itemIcon: "folder"
    property var projects: []
    property string emptyText: "Nothing recent"
    property string newLabel: "Open"

    readonly property int limit: size === "large" ? 7 : size === "medium" ? 3 : 3

    AppHeader {
        id: header

        x: 16
        y: 13
        appId: root.appId
        title: root.appTitle
        command: [root.binary]
    }

    Column {
        x: 16
        y: 44
        width: root.width - 32
        spacing: 1

        Repeater {
            model: root.projects.slice(0, root.limit)

            AppRow {
                required property var modelData

                width: parent.width
                icon: root.itemIcon
                label: modelData.name
                detail: root.size !== "small" ? (modelData.host ?? modelData.path.replace(Quickshell.env("HOME"), "~")) : ""
                onActivated: Quickshell.execDetached([root.binary, modelData.path])
            }
        }
    }

    // empty: say so, and offer to open the app
    Column {
        visible: root.projects.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 12
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.emptyText
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 12
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: label.implicitWidth + 24
            height: 28
            radius: 14
            color: hover.hovered ? Theme.primary : Theme.alpha(Theme.primary, 0.85)

            Text {
                id: label

                anchors.centerIn: parent
                text: root.newLabel
                color: Theme.fgOnPrimary
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            HoverHandler {
                id: hover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: { Shared.widgetTapAt = Date.now(); header.open() }
            }
        }
    }
}
