import QtQuick
import Quickshell
import Quickshell.Wayland

// Drag previews (hypr-qol.lua sends them while a window is dragged by its title bar):
//   zoom       — custom>>macsnap>>x,y,w,h: where the window will land
//   grab       — custom>>macgrab>>…: a ripple where a window was picked up
// Translucent rounded outlines; click-through.
PanelWindow {
    id: win

    required property ShellScreen modelData

    function onScreen(r: var): bool {
        return r !== null && r !== undefined && r.x >= (modelData?.x ?? 0) && r.x < (modelData?.x ?? 0) + (modelData?.width ?? 0);
    }

    screen: modelData
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    visible: snapBox.opacity > 0.01 || ripple.running || win.onScreen(Shared.snapRect)

    WlrLayershell.namespace: "macos-snap"
    WlrLayershell.layer: WlrLayer.Top

    component Outline: Rectangle {
        id: box

        property var target: null // { x, y, w, h } (global) or null
        property real strength: 1
        readonly property bool shown: win.onScreen(target)
        property var r: ({ x: 0, y: 0, w: 0, h: 0 })
        onTargetChanged: if (win.onScreen(target)) r = target

        x: r.x - (win.modelData?.x ?? 0) + 6
        y: r.y - (win.modelData?.y ?? 0) + 6
        width: Math.max(0, r.w - 12)
        height: Math.max(0, r.h - 12)
        radius: 16
        color: Theme.alpha(Theme.primary, 0.24 * strength)
        border.width: 3
        border.color: Theme.alpha(Theme.primary, 0.9 * strength)
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.96

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    Outline {
        id: snapBox

        target: Shared.snapRect
    }

    // grab ripple: a ring expanding from where the window was picked up
    Rectangle {
        id: ring

        width: 56
        height: 56
        radius: 28
        color: Theme.alpha(Theme.primary, 0.18)
        border.width: 2
        border.color: Theme.alpha(Theme.primary, 0.85)
        opacity: 0
        scale: 0.3

        Connections {
            target: Shared

            function onGrabbed(): void {
                if (!win.onScreen({ x: Shared.grabX }))
                    return;
                ring.x = Shared.grabX - (win.modelData?.x ?? 0) - 28;
                ring.y = Shared.grabY - (win.modelData?.y ?? 0) - 28;
                ripple.restart();
            }
        }

        // seen on every grab, so short; render-thread animators
        ParallelAnimation {
            id: ripple

            ScaleAnimator { target: ring; from: 0.55; to: 1; duration: 240; easing.type: Easing.OutCubic }
            OpacityAnimator { target: ring; from: 0.9; to: 0; duration: 240; easing.type: Easing.OutQuad }
        }
    }
}
