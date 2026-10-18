pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    required property string position

    readonly property bool horizontal: position !== "left"
    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int clampedExtent: Math.max(Config.border.minThickness, extent)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentThickness: Tokens.sizes.bar.innerWidth + padding * 2
    // [macos] 4 px less than the bar: windows sit 8 px below the pills (4 here + the 4 px
    // window gap), the same as the gap between a window and the dock
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentThickness - 4 : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered
    property real extent: fullscreen ? 0 : Config.border.thickness

    readonly property bool controlsFlash: (content.item as Bar)?.controlsFlash ?? false // [macos]

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function togglePopout(pos: real): void {
        (content.item as Bar)?.togglePopout(pos);
    }

    // [macos] entries whose drop-down opens on hover alone (the now-playing pill)
    function opensOnHover(pos: real): bool {
        const b = content.item as Bar;
        return !!b && b.entryAt(pos) === "media";
    }

    function isPopoutEntry(pos: real): bool {
        const b = content.item as Bar;
        return !!b && b.popoutEntries.includes(b.entryAt(pos));
    }

    function checkPopout(pos: real): void {
        (content.item as Bar)?.checkPopout(pos);
    }

    function entryAt(pos: real): string {
        return (content.item as Bar)?.entryAt(pos) ?? "";
    }

    function handleWheel(pos: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(pos, angleDelta);
    }

    clip: true
    visible: extent > Config.border.thickness
    implicitWidth: extent
    implicitHeight: extent

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.extent: root.contentThickness
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "extent"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "extent"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.top: root.position !== "top" ? parent.top : undefined
        anchors.bottom: root.position !== "bottom" ? parent.bottom : undefined
        anchors.left: root.horizontal ? parent.left : undefined
        anchors.right: parent.right

        width: root.contentThickness
        height: root.contentThickness

        active: root.shouldBeVisible

        sourceComponent: Bar {
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
            horizontal: root.horizontal
        }
    }
}
