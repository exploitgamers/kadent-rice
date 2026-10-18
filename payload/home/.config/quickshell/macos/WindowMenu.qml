pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Window menu: click a window's title bar (hypr-qol.lua emits the event).
// A 1×1 anchor surface at the pointer carries the glass menu. Setting:
// macos.json windows.titlebarMenu = "right" (default, like macOS), "left" (single click) or "off".
PanelWindow {
    id: win

    required property ShellScreen modelData

    property string address
    property bool floating
    property bool pinned
    readonly property var toplevel: Hyprland.toplevels.values.find(t => ("0x" + String(t.address).replace(/^0x/, "")) === address) ?? null
    // its window went away (closed from the menu or otherwise): the menu goes too
    onToplevelChanged: if (!toplevel && visible) menu.close()

    function hypr(cmd: string): void {
        Hyprland.dispatch(cmd);
    }

    function evalLua(code: string): void {
        Quickshell.execDetached(["hyprctl", "eval", code]);
    }

    function entries(): var {
        const w = `window = "address:${address}"`;
        const ws = toplevel?.workspace?.id ?? 0;
        const title = toplevel?.title ?? "";
        return [
            { header: title.length > 34 ? title.slice(0, 33) + "…" : (title || "Window") },
            { label: "Minimize", action: () => evalLua(`mac_minimize("${address}")`) },
            { label: "Zoom", action: () => { hypr(`hl.dsp.focus({ ${w} })`); evalLua("mac_zoom()"); } },
            { label: "Enter Full Screen", action: () => hypr(`hl.dsp.window.fullscreen({ mode = "fullscreen", ${w} })`) },
            { separator: true },
            { label: "Center", action: () => evalLua(`mac_snap("${address}", "center")`) },
            { separator: true },
            { label: "Floating Window", checked: floating, action: () => hypr(`hl.dsp.window.float({ action = "toggle", ${w} })`) },
            { label: "Show on All Desktops", checked: pinned, enabled: floating, action: () => hypr(`hl.dsp.window.pin({ action = "toggle", ${w} })`) },
            { label: "Move to Previous Desktop", enabled: ws > 1, action: () => hypr(`hl.dsp.window.move({ workspace = "${ws - 1}", ${w} })`) },
            { label: "Move to Next Desktop", enabled: ws > 0, action: () => hypr(`hl.dsp.window.move({ workspace = "${ws + 1}", ${w} })`) },
            { separator: true },
            { label: "Close Window", action: () => hypr(`hl.dsp.window.close({ ${w} })`) }
        ];
    }

    screen: modelData
    color: "transparent"
    visible: false
    anchors.top: true
    anchors.left: true
    implicitWidth: 1
    implicitHeight: 1
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "macos-winmenu-anchor"
    WlrLayershell.layer: WlrLayer.Overlay

    Connections {
        target: Shared

        function onWindowMenu(address: string, x: real, y: real, floating: bool, pinned: bool): void {
            const s = win.modelData;
            if (x < s.x || x >= s.x + s.width || y < s.y || y >= s.y + s.height)
                return; // another display's
            win.address = address;
            win.floating = floating;
            win.pinned = pinned;
            win.margins.left = Math.round(x - s.x);
            win.margins.top = Math.round(y - s.y);
            win.visible = true;
            Qt.callLater(() => menu.open(point, win.entries(), Edges.Bottom | Edges.Right));
        }
    }

    Item {
        id: point

        width: 1
        height: 1
    }

    GlassMenu {
        id: menu

        onVisibleChanged: if (!visible) win.visible = false
    }
}
