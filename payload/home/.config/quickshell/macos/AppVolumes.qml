pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Saved per-app volumes (Desktop Settings → Sound → App Volumes, kept in macos.json
// sound.appVolumes): each time an app starts playing, its stream gets the volume
// saved for it. Apps are matched by the name Pipewire reports for them.
Singleton {
    id: root

    // apps playing sound (not recording)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio
        && !(n.properties["media.class"] ?? "").startsWith("Stream/Input"))
    property var applied: ({}) // stream id → true, once its saved volume is set

    function appName(n: var): string {
        return n?.properties["application.name"] || n?.description || n?.name || "";
    }

    function apply(): void {
        const saved = Config.appVolumes;
        const next = {}; // live streams only: Pipewire reuses ids, a stale entry skipped a new stream
        for (const n of streams) {
            const v = saved[appName(n)];
            if (applied[n.id])
                next[n.id] = true;
            else if (v !== undefined && n.ready && n.audio) {
                n.audio.volume = v;
                next[n.id] = true;
            }
        }
        applied = next; // a new object, so `pending` updates
    }

    // a saved app's stream still waits for its volume
    readonly property bool pending: streams.some(n => Config.appVolumes[appName(n)] !== undefined && !applied[n.id])

    // volumes can only be set on tracked nodes
    PwObjectTracker {
        objects: Object.keys(Config.appVolumes).length ? root.streams : []
    }

    onStreamsChanged: Qt.callLater(apply)

    // a new stream is often not ready the instant it appears
    Timer {
        running: root.pending // was: any stream at all → a 700 ms wake-up for as long as audio played
        repeat: true
        interval: 700
        onTriggered: root.apply()
    }
}
