import QtQuick
import Quickshell

// Hot corners, like macOS: rest the pointer in a screen corner. Detection lives
// in Hyprland (hypr-qol.lua polls the pointer, so no window or layer can cover a
// corner — the earlier 3 px layer targets missed real mouse movement). This just
// hands Hyprland the actions from macos.json → hotCorners whenever they change:
// "launcher", "overview", "showdesktop", "lock", "spotlight", "widgets", "none".
Item {
    function push(): void {
        const c = Config.hotCorners;
        const q = v => `"${String(v ?? "none").replace(/[^a-z]/g, "")}"`;
        Quickshell.execDetached(["hyprctl", "eval",
            `mac_hot_corners({ tl = ${q(c.topLeft)}, tr = ${q(c.topRight)}, bl = ${q(c.bottomLeft)}, br = ${q(c.bottomRight)} })`]);
    }

    Component.onCompleted: push()

    Connections {
        target: Config

        function onHotCornersChanged(): void {
            push();
        }
    }
}
