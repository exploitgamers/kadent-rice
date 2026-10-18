pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// [macos] the wallpaper's average colour along the top of every screen (64 columns), for the
// bar's adaptive ink (modules/bar/components/BarInk.qml). Recomputed when the wallpaper or the
// screens change; {} (scheme colours) when the script can't read the image.
Singleton {
    id: root

    property var columns: ({})
    readonly property list<string> command: ["python3", "-I", Quickshell.shellPath("utils/scripts/wallstrip.py"), Wallpapers.current, ...Quickshell.screens.map(s => `${s.name}:${s.width}:${s.height}`)]

    onCommandChanged: debounce.restart()
    Component.onCompleted: debounce.restart()

    Timer {
        id: debounce

        interval: 300
        onTriggered: {
            proc.running = false;
            proc.command = root.command;
            proc.running = true;
        }
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.columns = JSON.parse(text);
                } catch (e) {
                    root.columns = {};
                }
            }
        }
    }
}
