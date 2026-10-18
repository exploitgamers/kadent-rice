import QtQuick

// Weather widget. Small: now. Medium: + next hours. Large: + 5-day forecast.
// Location: macos.json widgets.weatherLocation (empty = from your IP address).
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    readonly property string deg: "°"


    function t(v: real): string {
        return Math.round(v) + deg;
    }

    component Icon: Text {
        property string name
        property bool filled: true

        text: name
        color: Theme.fg
        font.family: "Material Symbols Rounded"
        font.variableAxes: { "FILL": filled ? 1 : 0 }
    }

    Text {
        visible: !WeatherData.loaded
        anchors.centerIn: parent
        text: WeatherData.failed ? "Weather unavailable" : "Loading weather…"
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: 13
    }

    Item {
        id: now

        visible: WeatherData.loaded
        x: 16
        y: 14
        width: root.width - 32
        height: 140

        Text {
            id: place

            width: parent.width - 30
            text: WeatherData.city + (Config.weatherLocation ? "" : "  ➤")
            elide: Text.ElideRight
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        Text {
            anchors.top: place.bottom
            anchors.topMargin: -6
            text: root.t(WeatherData.temp)
            color: Theme.fg
            font.family: Theme.displayFont
            font.pixelSize: 46
            font.weight: Font.Light
        }

        Icon {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -2
            name: WeatherData.icon
            color: Theme.primary
            font.pixelSize: root.size === "small" ? 26 : 34
        }

        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.size === "small" ? 0 : 2
            visible: root.size === "small"

            Text {
                text: WeatherData.condition
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                text: `H:${root.t(WeatherData.high)}  L:${root.t(WeatherData.low)}`
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: 12
            }
        }

        // medium / large: condition beside the icon instead
        Column {
            visible: root.size !== "small"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 40

            Text {
                anchors.right: parent.right
                text: WeatherData.condition
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                anchors.right: parent.right
                text: `H:${root.t(WeatherData.high)}  L:${root.t(WeatherData.low)}`
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    // next hours
    Row {
        visible: WeatherData.loaded && root.size !== "small"
        x: 16
        y: 96
        width: root.width - 32

        Repeater {
            model: WeatherData.hourly

            Column {
                required property var modelData

                width: (root.width - 32) / 6
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.hour
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: WeatherData.iconFor(parent.modelData.code, parent.modelData.isDay)
                    font.pixelSize: 19
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.t(parent.modelData.temp)
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }
    }

    // 5-day forecast
    Column {
        visible: WeatherData.loaded && root.size === "large"
        x: 16
        y: 178
        width: root.width - 32

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.fg, 0.12)
        }

        Repeater {
            model: WeatherData.daily.slice(1, 6)

            Item {
                id: day

                required property var modelData

                // range bar: this day's low..high within the week's span
                readonly property real minT: Math.min(...WeatherData.daily.map(d => d.low))
                readonly property real maxT: Math.max(...WeatherData.daily.map(d => d.high))

                width: parent.width
                height: 34

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: day.modelData.day
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Icon {
                    x: 58
                    anchors.verticalCenter: parent.verticalCenter
                    name: WeatherData.iconFor(day.modelData.code, true)
                    font.pixelSize: 19
                }

                Text {
                    x: 100
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: root.t(day.modelData.low)
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                Rectangle {
                    id: track

                    x: 144
                    width: parent.width - 144 - 46
                    height: 4
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.alpha(Theme.fg, 0.12)

                    Rectangle {
                        readonly property real span: Math.max(1, day.maxT - day.minT)

                        x: track.width * (day.modelData.low - day.minT) / span
                        width: Math.max(4, track.width * (day.modelData.high - day.modelData.low) / span)
                        height: 4
                        radius: 2
                        color: Theme.primary
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.t(day.modelData.high)
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }
        }
    }
}
