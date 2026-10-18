pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData
    required property int index
    property Item tray

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    // [macos] app icons fill their whole box, so they get a smaller one than the glyphs' em box:
    // about the height of the status icons' ink (they used to touch the pill's edges)
    implicitWidth: Math.round(Tokens.sizes.bar.innerWidth * 0.65)
    implicitHeight: Math.round(Tokens.sizes.bar.innerWidth * 0.65)

    // [macos] like the menu bar: right-click opens the app's menu; left-click brings the
    // app up, or opens the menu when that's all it has (right-click used to send the
    // rarely-supported "secondary activate", and the menu could never be reached)
    onClicked: event => {
        if (event.button === Qt.LeftButton && !modelData.onlyMenu)
            modelData.activate();
        else if (modelData.hasMenu)
            (tray as Tray)?.menuRequested(root, index);
        else
            modelData.activate();
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }

    HoverWash {
        anchors.margins: -3 // a circle a little larger than the icon
        radius: width / 2
    }
}
