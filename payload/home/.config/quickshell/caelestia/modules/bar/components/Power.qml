import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState

    BarInk { id: pillInk; pill: root }

    // [macos] as tall as the other pills (the bar's inner width)
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: Tokens.sizes.bar.innerWidth

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: Tokens.sizes.bar.innerWidth
        radius: Tokens.rounding.full
        onClicked: root.screenState.session = !root.screenState.session
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "power_settings_new"
        color: pillInk.c(Colours.palette.m3error) // [macos] adaptive (BarInk)
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).scale(Tokens.sizes.bar.innerWidth / 26).build() // [macos] with the bar
    }
}
