import QtQuick
import Caelestia.Services

// System widget. Small: usage bars. Medium: rings plus temperature and uptime.
// Click opens System Monitor. GPU comes from Caelestia's Gpu service.
Item {
    id: root

    property string size: "small"
    property string widgetId: ""

    // GpuType lives in Caelestia.Config (whose Config would shadow ours): 3 = None
    readonly property bool hasGpu: Gpu.type !== 3 && !Gpu.detecting
    readonly property var stats: [
        { label: "CPU", value: SysStats.cpu },
        ...(hasGpu ? [{ label: "GPU", value: Gpu.percentage }] : []),
        { label: "Memory", value: SysStats.mem },
        { label: "Disk", value: SysStats.disk }
    ]

    ServiceRef {
        service: Gpu
    }

    function tint(v: real): color {
        return v > 0.9 ? "#ff5f57" : v > 0.75 ? "#febc2e" : Theme.primary;
    }

    // small: three labelled bars
    Column {
        visible: root.size === "small"
        x: 16
        width: root.width - 32
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.stats.length > 3 ? 7 : 11

        Repeater {
            model: root.stats

            Column {
                required property var modelData

                width: parent.width
                spacing: 5

                Item {
                    width: parent.width
                    height: 15

                    Text {
                        text: parent.parent.modelData.label
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.right: parent.right
                        text: Math.round(parent.parent.modelData.value * 100) + "%"
                        color: Theme.fgDim
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.features: { "tnum": 1 }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.alpha(Theme.fg, 0.12)

                    Rectangle {
                        width: Math.max(6, parent.width * Math.min(1, parent.parent.modelData.value))
                        height: 6
                        radius: 3
                        color: root.tint(parent.parent.modelData.value)
                        // no Behavior: a 500 ms slide every 2 s refresh kept the desktop repainting
                    }
                }
            }
        }
    }

    // medium: three rings + footer
    Row {
        visible: root.size === "medium"
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        spacing: root.stats.length > 3 ? 16 : 34

        Repeater {
            model: root.stats

            Column {
                required property var modelData

                spacing: 6

                Item {
                    width: 66
                    height: 66

                    Ring {
                        anchors.fill: parent
                        value: parent.parent.modelData.value
                        colour: root.tint(parent.parent.modelData.value)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(parent.parent.modelData.value * 100) + "%"
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.label
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }

    Text {
        visible: root.size === "medium"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        text: (SysStats.tempC > 0 ? Math.round(SysStats.tempC) + "°C  ·  " : "") + "Up " + SysStats.uptimeText()
            + "  ·  " + SysStats.gib(SysStats.memUsed) + " of " + SysStats.gib(SysStats.memTotal)
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: 11
        font.features: { "tnum": 1 }
    }
}
