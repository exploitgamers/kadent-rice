pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

// [macos] the top bar's system pill, expanded on hover: CPU (with the last minute
// as a graph), GPU, memory, disks and the apps using the most CPU. Click "Open
// System Monitor" for everything else.
Column {
    id: root

    readonly property int histLen: 60
    property var cpuHist: []
    property var topApps: [] // [{ name, cpu, mem }]

    function gb(kib: real): string {
        return (kib / 1048576).toFixed(kib >= 10485760 ? 0 : 1) + " GB";
    }

    width: 340
    spacing: Tokens.spacing.medium

    ServiceRef { service: Cpu }
    ServiceRef { service: Memory }
    ServiceRef { service: Storage }
    ServiceRef { service: Gpu }

    Timer {
        running: true
        repeat: true
        interval: 1000
        triggeredOnStart: true
        onTriggered: root.cpuHist = [...root.cpuHist.slice(1 - root.histLen), Cpu.percentage]
    }

    // busiest apps right now, every 2 s while open: top's second sample (ps gives
    // each process's average since it started, which made short-lived ones look huge);
    // processes with the same name are added up
    Process {
        id: ps

        running: true
        command: ["sh", "-c", "top -b -n 2 -d 0.7 -w 300 -o %CPU | awk '/^top -/{n++} n==2 && $1 ~ /^[0-9]+$/ {c=$12; for (i=13;i<=NF;i++) c=c\" \"$i; print $9\"\\t\"$10\"\\t\"c}' | head -40"]
        stdout: StdioCollector {
            onStreamFinished: {
                const byName = {};
                for (const l of text.trim().split("\n")) {
                    let [cpu, mem, name] = l.split("\t");
                    // not apps: top itself and the kernel's own threads (kworker/…, ksoftirqd/…)
                    if (!name || name === "top" || name.includes("/") || /^(kthreadd|rcu_|migration|irq_|idle_inject)/.test(name))
                        continue;
                    // Firefox's helper processes, by what they do
                    const nice = { "Isolated Web Co": "Firefox (tabs)", "Web Content": "Firefox (tabs)", "RDD Process": "Firefox (video)", "Socket Process": "Firefox (network)", "Privileged Cont": "Firefox (tabs)", "WebExtensions": "Firefox (extensions)" };
                    name = nice[name] ?? name;
                    if (!byName[name])
                        byName[name] = { name: name, cpu: 0, mem: 0 };
                    const a = byName[name];
                    a.cpu += Number(cpu.replace(",", "."));
                    a.mem += Number(mem.replace(",", "."));
                }
                root.topApps = Object.values(byName).filter(a => a.cpu > 0).sort((x, y) => y.cpu - x.cpu).slice(0, 5);
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 2000
        onTriggered: ps.running = true
    }

    component Meter: Rectangle {
        property real value

        height: 5
        radius: 2.5
        color: Qt.alpha(Colours.palette.m3onSurface, 0.12)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.value))
            height: parent.height
            radius: parent.radius
            color: parent.value > 0.9 ? Colours.palette.m3error : Colours.palette.m3tertiary

            Behavior on width { Anim {} }
        }
    }

    // a label left, a value right, and a meter under them
    component Gauge: Column {
        property string label
        property string value
        property real fraction

        width: root.width
        spacing: 5

        Item {
            width: parent.width
            height: gaugeLabel.implicitHeight

            StyledText {
                id: gaugeLabel

                text: parent.parent.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                anchors.right: parent.right
                text: parent.parent.value
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        Meter {
            width: parent.width
            value: parent.fraction
        }
    }

    // ── CPU ─────────────────────────────────────────────────────────
    Item {
        width: root.width
        height: cpuBig.implicitHeight

        StyledText {
            id: cpuBig

            text: Math.round(Cpu.percentage * 100) + "%"
            font: Tokens.font.title.large
            color: Colours.palette.m3onSurface
        }

        Column {
            anchors.left: cpuBig.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: parent.right
            anchors.verticalCenter: cpuBig.verticalCenter

            StyledText {
                width: parent.width
                text: "CPU" + (Cpu.temperature > 0 ? "  ·  " + Math.round(Cpu.temperature) + "°C" : "")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                width: parent.width
                text: Cpu.name
                elide: Text.ElideRight
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // the last minute, one bar per second, newest on the right
    Row {
        height: 36
        spacing: 1

        Repeater {
            model: root.histLen

            Rectangle {
                required property int index

                readonly property real v: root.cpuHist[index - (root.histLen - root.cpuHist.length)] ?? 0

                anchors.bottom: parent.bottom
                width: (root.width - (root.histLen - 1)) / root.histLen
                height: Math.max(1, 36 * Math.min(1, v))
                radius: 1
                color: v > 0.9 ? Colours.palette.m3error : Qt.alpha(Colours.palette.m3tertiary, 0.35 + 0.65 * index / root.histLen)
            }
        }
    }

    // ── GPU, memory, disks ──────────────────────────────────────────
    Gauge {
        visible: Gpu.type !== GpuType.None
        label: "GPU" + (Gpu.name ? "  ·  " + Gpu.name : "")
        value: Math.round(Gpu.percentage * 100) + "%" + (Gpu.temperature > 0 ? "  " + Math.round(Gpu.temperature) + "°C" : "")
        fraction: Gpu.percentage
    }

    Gauge {
        label: "Memory"
        value: root.gb(Memory.used) + " of " + root.gb(Memory.total)
        fraction: Memory.percentage
    }

    Repeater {
        model: Array.from(Storage.disks).slice(0, 3)

        Gauge {
            required property var modelData

            label: Storage.disks.length === 1 || modelData.hasRoot ? "Disk" : modelData.mount
            value: root.gb(modelData.used) + " of " + root.gb(modelData.total)
            fraction: modelData.perc
        }
    }

    // ── busiest apps ────────────────────────────────────────────────
    StyledText {
        visible: root.topApps.length > 0
        text: "Using the most CPU"
        font: Tokens.font.label.small
        color: Colours.palette.m3onSurfaceVariant
    }

    Column {
        width: root.width

        Repeater {
            model: root.topApps

            Item {
                required property var modelData

                width: root.width
                height: appName.implicitHeight + 4

                StyledText {
                    id: appName

                    width: parent.width - 110
                    text: parent.modelData.name
                    elide: Text.ElideRight
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    anchors.right: parent.right
                    text: parent.modelData.cpu.toFixed(1) + "%  ·  " + parent.modelData.mem.toFixed(1) + "% RAM"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    // ── open the full app ───────────────────────────────────────────
    StyledRect {
        width: root.width
        height: openText.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainer

        StyledText {
            id: openText

            anchors.centerIn: parent
            text: "Open System Monitor"
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurface
        }

        StateLayer {
            radius: parent.radius
            color: Colours.palette.m3onSurface
            onClicked: Quickshell.execDetached(["plasma-systemmonitor"])
        }
    }
}
