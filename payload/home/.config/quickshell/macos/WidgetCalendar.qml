import QtQuick
import Quickshell

// Calendar widget. Small: weekday and date. Medium: date beside the month.
// Large: the month, big.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    readonly property date today: clock.date
    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7 // 0 = Sunday
    property int monthOffset: 0 // large size: ‹ › browse months
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property bool thisMonth: monthOffset === 0

    // 42 cells (6 weeks) for the shown month; day 0 = outside the month
    readonly property var cells: {
        const y = shown.getFullYear(), m = shown.getMonth();
        const lead = (new Date(y, m, 1).getDay() - firstDay + 7) % 7;
        const days = new Date(y, m + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = i - lead + 1;
            out.push(d >= 1 && d <= days ? d : 0);
        }
        // drop a trailing empty week
        return out.slice(35).every(d => d === 0) ? out.slice(0, 35) : out;
    }

    // Weekday + big date (small, and the left half of medium)
    Column {
        visible: root.size !== "large"
        x: 16
        y: 14
        width: root.size === "small" ? root.width - 32 : root.width / 2 - 40
        spacing: -4

        Text {
            text: Qt.formatDateTime(root.today, "dddd").toUpperCase()
            color: Theme.primary
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Bold
            font.letterSpacing: 0.6
        }

        Text {
            text: root.today.getDate()
            color: Theme.fg
            font.family: Theme.displayFont
            font.pixelSize: 64
            font.weight: Font.Light
        }

        Text {
            topPadding: 8
            text: Qt.formatDateTime(root.today, "MMMM yyyy")
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    // Month grid (medium: right half, large: whole widget)
    Column {
        id: month

        visible: root.size !== "small"
        x: root.size === "medium" ? root.width / 2 - 14 : 18
        y: root.size === "medium" ? 14 : 16
        width: root.size === "medium" ? root.width / 2 : root.width - 36
        spacing: root.size === "large" ? 8 : 2

        readonly property real cellW: width / 7
        readonly property real cellH: root.size === "large" ? 38 : 17

        Item {
            width: parent.width
            height: monthName.height

            Text {
                id: monthName

                text: Qt.formatDateTime(root.size === "large" ? root.shown : root.today, root.size === "large" ? "MMMM yyyy" : "MMMM").toUpperCase()
                color: Theme.primary
                font.family: Theme.font
                font.pixelSize: root.size === "large" ? 15 : 11
                font.weight: Font.Bold
                font.letterSpacing: 0.6
                bottomPadding: root.size === "large" ? 4 : 1
            }

            Row {
                visible: root.size === "large"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: -4
                spacing: 2

                Repeater {
                    model: [{ icon: "chevron_left", step: -1 }, { icon: "today", step: 0 }, { icon: "chevron_right", step: 1 }]

                    Rectangle {
                        required property var modelData

                        width: 28
                        height: 28
                        radius: 8
                        visible: modelData.step !== 0 || !root.thisMonth
                        color: navArea.containsMouse ? Theme.alpha(Theme.fg, 0.12) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.icon
                            color: Theme.fg
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                        }

                        MouseArea {
                            id: navArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthOffset = parent.modelData.step === 0 ? 0 : root.monthOffset + parent.modelData.step
                        }
                    }
                }
            }
        }

        Row {
            Repeater {
                model: 7

                Text {
                    required property int index

                    width: month.cellW
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((index + root.firstDay) % 7, Locale.NarrowFormat)
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: root.size === "large" ? 13 : 9
                    font.weight: Font.DemiBold
                }
            }
        }

        Grid {
            columns: 7

            Repeater {
                model: root.cells

                Item {
                    required property int modelData

                    readonly property bool isToday: root.thisMonth && modelData === root.today.getDate()

                    width: month.cellW
                    height: month.cellH

                    Rectangle {
                        visible: parent.isToday
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - (root.size === "large" ? 4 : 1)
                        height: width
                        radius: width / 2
                        color: Theme.primary
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData || ""
                        color: parent.isToday ? Theme.fgOnPrimary : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: root.size === "large" ? 16 : 10
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
