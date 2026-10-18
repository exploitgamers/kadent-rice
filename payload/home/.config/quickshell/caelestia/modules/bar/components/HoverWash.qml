import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// [macos] the one hover hint every top-bar item uses: a soft wash over the whole pill
// (or a circle for a lone icon), the same strength as the clickable chips' StateLayer.
// Hover only — it takes no clicks, so the bar's own click handling (drop-downs) is untouched.
Rectangle {
    anchors.fill: parent
    radius: parent.radius ?? Tokens.rounding.full
    color: Colours.palette.m3onSurface
    opacity: hover.containsMouse ? 0.08 : 0

    Behavior on opacity {
        Anim {}
    }

    // a hover-only mouse area, as StateLayer uses (a HoverHandler never saw hover in the
    // bar); no buttons, so clicks still reach the bar's own handling
    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
