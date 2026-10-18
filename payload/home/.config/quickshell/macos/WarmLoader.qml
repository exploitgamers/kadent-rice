import QtQuick
import Quickshell

// Per-screen loader for heavy, rarely shown windows (widget gallery, wallpaper browser).
// Loaded when `want` turns on or the desktop menu opens (Shared.prewarm), built in the
// background in spare frame time (no frozen frames), kept `keep` ms after the last use so
// reopening is instant, then unloaded. LazyLoader's own `activeAsync: false` never unloads,
// hence `loading` + `active`.
LazyLoader {
    id: root

    required property ShellScreen modelData
    property bool want: false
    property int keep: 45000
    // set imperatively, never through a binding: a binding on `want || timer.running` dipped to
    // false for a moment on close and rebuilt the window every time
    property bool alive: false
    property bool done: false

    function warm(): void {
        alive = true;
        if (!want)
            hold.restart();
    }

    loading: alive
    active: alive && done
    onWantChanged: {
        if (want) {
            hold.stop();
            alive = true;
        } else {
            hold.restart();
        }
    }
    onAliveChanged: if (!alive) done = false
    onLoadingChanged: if (!loading && alive) done = true
    Component.onCompleted: {
        alive = want;
        Shared.prewarm.connect(warm);
    }
    Component.onDestruction: Shared.prewarm.disconnect(warm)

    property Timer hold: Timer {
        interval: root.keep
        onTriggered: root.alive = false
    }
}
