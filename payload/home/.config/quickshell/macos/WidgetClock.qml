import QtQuick
import Quickshell

// Clock widget. Small: analog face. Medium: face plus digital time and date.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    SystemClock {
        id: clock

        // seconds only while the desktop is visible (or in the gallery preview)
        precision: root.widgetId === "" || Shared.widgetsLive ? SystemClock.Seconds : SystemClock.Minutes
    }

    Item {
        id: face

        readonly property real r: width / 2

        width: Math.min(root.height, root.size === "small" ? root.width : root.width / 2) - 20
        height: width
        anchors.verticalCenter: parent.verticalCenter
        x: root.size === "small" ? (root.width - width) / 2 : 14

        // minute ticks
        Repeater {
            model: 60

            Rectangle {
                required property int index

                readonly property bool major: index % 5 === 0

                x: face.r - width / 2
                y: 2
                width: major ? 2 : 1
                height: major ? 7 : 4
                radius: 1
                color: Theme.alpha(Theme.fg, major ? 0.55 : 0.25)
                transform: Rotation { origin.x: width / 2; origin.y: face.r - 2; angle: index * 6 }
            }
        }

        // hour numerals
        Repeater {
            model: 12

            Text {
                required property int index

                readonly property real a: (index + 1) * Math.PI / 6

                x: face.r + Math.sin(a) * (face.r - 21) - width / 2
                y: face.r - Math.cos(a) * (face.r - 21) - height / 2
                text: index + 1
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: face.width * 0.105
                font.weight: Font.Medium
            }
        }

        component Hand: Rectangle {
            id: hand

            property real turn // degrees clockwise from 12
            property real length

            x: face.r - width / 2
            y: face.r - length
            height: length + 6
            radius: width / 2
            antialiasing: true
            transform: Rotation { origin.x: hand.width / 2; origin.y: hand.length; angle: hand.turn }
        }

        Hand {
            width: 5
            length: face.r * 0.5
            color: Theme.fg
            turn: (clock.hours % 12 + clock.minutes / 60) * 30
        }

        Hand {
            width: 3.5
            length: face.r * 0.76
            color: Theme.fg
            turn: (clock.minutes + clock.seconds / 60) * 6
        }

        Hand {
            visible: clock.precision === SystemClock.Seconds
            width: 1.5
            length: face.r * 0.84
            color: Theme.primary
            turn: clock.seconds * 6
        }

        Rectangle {
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: 3.5
            color: Theme.primary
            border.width: 1.5
            border.color: Theme.fg
        }
    }

    Column {
        visible: root.size !== "small"
        anchors.left: face.right
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: Qt.formatDateTime(clock.date, "dddd").toUpperCase()
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
        }

        Text {
            text: Qt.formatDateTime(clock.date, Config.clock24 ? "HH:mm" : "h:mm")
            color: Theme.fg
            font.family: Theme.displayFont
            font.pixelSize: 46
            font.weight: Font.Light
            font.features: { "tnum": 1 }
        }

        Text {
            text: Qt.formatDateTime(clock.date, "d MMMM yyyy") + (Config.clock24 ? "" : "  ·  " + Qt.formatDateTime(clock.date, "AP"))
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
