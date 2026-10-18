pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which app icons need a rounded tile so they match WhiteSur's squircle icons
// (round or odd-shaped icons: Equibop, pwvucontrol, Sober…). Measured by
// ~/.local/bin/rice-icon-tiles into ~/.cache/macos-icon-tiles.json; refreshed
// at shell start (only new apps are measured).
Singleton {
    id: root

    property var tiles: ({})

    function needsTile(icon: string): bool {
        return tiles[icon] === true;
    }

    Process {
        running: true
        command: [Quickshell.env("HOME") + "/.local/bin/rice-icon-tiles"]
        onExited: cache.reload()
    }

    FileView {
        id: cache

        path: Quickshell.env("HOME") + "/.cache/macos-icon-tiles.json"
        printErrors: false
        onLoaded: {
            try {
                root.tiles = JSON.parse(text());
            } catch (e) {}
        }
    }
}
