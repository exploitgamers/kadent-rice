import QtQuick

// Weather conditions (replaces the dashboard's Weather tab details):
// feels like, humidity, wind, UV, sunrise and sunset. Click opens the forecast.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""


    readonly property var tiles: [
        { icon: "thermostat", label: "Feels Like", value: Math.round(WeatherData.feelsLike) + "°" },
        { icon: "humidity_percentage", label: "Humidity", value: Math.round(WeatherData.humidity) + "%" },
        { icon: "air", label: "Wind", value: Math.round(WeatherData.wind) + " km/h" },
        { icon: "sunny", label: "UV Index", value: Math.round(WeatherData.uv) },
        { icon: "wb_twilight", label: "Sunrise", value: WeatherData.sunrise || "--:--" },
        { icon: "nights_stay", label: "Sunset", value: WeatherData.sunset || "--:--" }
    ]

    Text {
        visible: !WeatherData.loaded
        anchors.centerIn: parent
        text: WeatherData.failed ? "Weather unavailable" : "Loading…"
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: 13
    }

    Grid {
        visible: WeatherData.loaded
        anchors.centerIn: parent
        columns: root.size === "small" ? 2 : 3
        rowSpacing: root.size === "small" ? 6 : 14
        columnSpacing: root.size === "small" ? 10 : 18

        Repeater {
            model: root.size === "small" ? root.tiles.slice(0, 4) : root.tiles

            Column {
                required property var modelData

                width: root.size === "small" ? 64 : 92
                spacing: 1

                Row {
                    spacing: 3

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.parent.modelData.icon
                        color: Theme.fgDim
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                    }

                    Text {
                        text: parent.parent.modelData.label.toUpperCase()
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.4
                    }
                }

                Text {
                    text: parent.modelData.value
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: root.size === "small" ? 17 : 20
                    font.weight: Font.Medium
                }
            }
        }
    }
}
