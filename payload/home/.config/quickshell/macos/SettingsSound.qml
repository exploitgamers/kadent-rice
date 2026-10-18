pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Desktop Settings → Sound (SettingsUi.qml): output and input device, their volume
// and mute, and each app's volume. Same node split as Caelestia's Audio service:
// devices are non-stream nodes (sinks = outputs), apps are streams.
Column {
    id: page

    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && !n.isSink && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function nodeName(n: var): string {
        return n?.description || n?.nickname || n?.name || "Unknown device";
    }

    function appName(n: var): string {
        return n.properties["application.name"] || n.description || n.name || "Unknown app";
    }

    spacing: 22

    // volume / mute are only live on tracked nodes
    PwObjectTracker {
        objects: [page.sink, page.source, ...page.streams].filter(n => n)
    }

    component Volume: SettingsUi.Slider {
        id: vol

        property var node

        from: 0
        to: 1
        step: 0.01
        value: node?.audio?.volume ?? 0
        text: node?.audio?.muted ? "Muted" : Math.round((node?.audio?.volume ?? 0) * 100) + "%"
        onMoved: v => {
            if (vol.node?.audio)
                vol.node.audio.volume = v;
        }
    }

    SettingsUi.Group {
        title: "Output"

        SettingsUi.Setting {
            label: "Play sound through"
            SettingsUi.Choice {
                width: 240
                options: page.sinks.map(n => [n.name, page.nodeName(n)])
                value: page.sink?.name ?? ""
                onPicked: v => Pipewire.preferredDefaultAudioSink = page.sinks.find(n => n.name === v) ?? null
            }
        }

        SettingsUi.Setting {
            label: "Output volume"
            Volume {
                node: page.sink
            }
        }

        SettingsUi.Setting {
            label: "Mute"
            SettingsUi.Toggle {
                checked: page.sink?.audio?.muted ?? false
                onToggled: on => {
                    if (page.sink?.audio)
                        page.sink.audio.muted = on;
                }
            }
        }
    }

    SettingsUi.Group {
        title: "Input"

        SettingsUi.Setting {
            label: "Microphone"
            SettingsUi.Choice {
                width: 240
                options: page.sources.map(n => [n.name, page.nodeName(n)])
                value: page.source?.name ?? ""
                onPicked: v => Pipewire.preferredDefaultAudioSource = page.sources.find(n => n.name === v) ?? null
            }
        }

        SettingsUi.Setting {
            label: "Input volume"
            Volume {
                node: page.source
            }
        }

        SettingsUi.Setting {
            label: "Mute microphone"
            SettingsUi.Toggle {
                checked: page.source?.audio?.muted ?? false
                onToggled: on => {
                    if (page.source?.audio)
                        page.source.audio.muted = on;
                }
            }
        }
    }

    // every app playing now, and every app with a saved volume: moving a slider sets
    // the app's volume now and saves it, so it starts at that volume next time
    readonly property var appNames: [...new Set([...page.streams.filter(n => !(n.properties["media.class"] ?? "").startsWith("Stream/Input")).map(n => page.appName(n)),
        ...Object.keys(Config.appVolumes)])].filter(n => n).sort((a, b) => a.localeCompare(b))

    SettingsUi.Group {
        title: "App Volumes"
        note: page.appNames.length === 0 ? "Apps show up here once they play sound." : "Each app starts at the volume you set here, every time it plays."

        Repeater {
            model: page.appNames

            SettingsUi.Setting {
                id: app

                required property string modelData
                readonly property var playing: page.streams.filter(n => page.appName(n) === modelData)
                readonly property var saved: Config.appVolumes[modelData]

                label: modelData
                detail: (playing.length ? "Playing" : "Not playing") + (saved !== undefined ? "  ·  starts at " + Math.round(saved * 100) + "%" : "")

                Row {
                    spacing: 8

                    SettingsUi.Slider {
                        from: 0
                        to: 1
                        step: 0.01
                        value: app.playing[0]?.audio?.volume ?? app.saved ?? 1
                        text: Math.round((app.playing[0]?.audio?.volume ?? app.saved ?? 1) * 100) + "%"
                        onMoved: v => {
                            for (const n of app.playing)
                                if (n.audio)
                                    n.audio.volume = v;
                            Config.setAppVolume(app.modelData, v);
                        }
                    }

                    SettingsUi.Button {
                        visible: app.saved !== undefined
                        text: "Forget"
                        onClicked: Config.forgetAppVolume(app.modelData)
                    }
                }
            }
        }
    }

    SettingsUi.Group {
        title: "More"

        SettingsUi.Setting {
            label: "Device profiles, channel balance and routing"
            SettingsUi.Button {
                text: "Advanced…"
                onClicked: Quickshell.execDetached(["sh", "-c", "command -v pwvucontrol >/dev/null && exec pwvucontrol || exec pavucontrol"])
            }
        }
    }
}
