import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// While a window is being dragged or resized (Shared.windowDrag), thin invisible
// strips sit over all four screen edges — above Caelestia's hover triggers —
// so dragging a window to an edge doesn't pop out the side bar, dashboard,
// sidebar or volume panel. Otherwise the input region is empty and Caelestia's
// edges behave exactly as normal.
//
// After the drag ends, the strip the pointer is still on stays up until the
// pointer leaves it: releasing a resize at the very top edge used to drop the
// shield with the pointer sitting in Caelestia's top trigger, so the dashboard
// opened right at release.
PanelWindow {
    id: win

    required property ShellScreen modelData

    // Wider than Caelestia's edge trigger strips (their width isn't configurable)
    readonly property int thickness: 12
    property bool lingering: false
    // not for title-bar drags: a release on these strips would be dropped by the title-bar
    // plugin (Caelestia goes input-less for those instead); SUPER-drags and resizes keep it
    // never over a fullscreen window: its edges are its own UI (Firefox's tabs, tab list
    // and window buttons along the top) — any click raised the strips there, so the
    // click went to the shield and Firefox hid its toolbar again
    // the shown desktop's windows, like BottomDock: activeToplevel stayed "fullscreen" after Alt+Tab hid a game
    readonly property bool fullscreenActive: Shared.fullscreenOn(modelData)
    readonly property bool active: !fullscreenActive && ((Shared.windowDrag && !Shared.titleDrag) || lingering)
    readonly property bool pointerOnStrip: leftHover.hovered || topHover.hovered || rightHover.hovered || bottomHover.hovered

    Connections {
        target: Shared

        function onWindowDragChanged(): void {
            // drag just ended: keep the shield only if the pointer is on an edge
            if (!Shared.windowDrag)
                win.lingering = win.pointerOnStrip;
        }
    }

    // pointer moved off the edge → hand the edges back to Caelestia
    onPointerOnStripChanged: if (!pointerOnStrip) lingering = false

    // mapped only around drags: an idle full-screen layer still holds ~110 MB of GPU
    // buffers. Unmapping waits a moment so the release-time hover check above still
    // sees the strips. [ram]
    visible: active || unmapDelay.running
    onActiveChanged: if (!active) unmapDelay.restart()

    Timer {
        id: unmapDelay

        interval: 500
    }

    screen: modelData
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.namespace: "macos-edgeshield"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    mask: Region {
        item: win.active ? leftEdge : null

        Region { item: win.active ? topEdge : null }
        Region { item: win.active ? rightEdge : null }
        Region { item: win.active ? bottomEdge : null }
    }

    Item {
        id: leftEdge

        x: 0
        y: 0
        width: win.thickness
        height: win.height

        HoverHandler { id: leftHover }
    }

    Item {
        id: topEdge

        x: 0
        y: 0
        width: win.width
        height: win.thickness

        HoverHandler { id: topHover }
    }

    // bottom too: resizing toward the dock reached Caelestia's bottom-corner panel
    Item {
        id: bottomEdge

        x: 0
        y: win.height - win.thickness
        width: win.width
        height: win.thickness

        HoverHandler { id: bottomHover }
    }

    Item {
        id: rightEdge

        x: win.width - win.thickness
        y: 0
        width: win.thickness
        height: win.height

        HoverHandler { id: rightHover }
    }
}
