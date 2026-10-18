pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property Item current
    property bool completed

    // [macos] wallpaper change transitions, a different one each time:
    //   iris (circle from the centre) · corner (circle from a corner) ·
    //   wipe (from an edge) · zoom (fade while settling). Every one also
    //   settles the new image from a slight zoom.
    // The new wallpaper is clipped by a growing shape (ClippingRectangle), not
    // a MultiEffect mask — the mask version silently never applied here, so
    // wallpapers just swapped instantly.
    // When the reveal starts it sends custom>>macwall>>ms so the macos shell's
    // widget glass fades in step (DesktopWidgets.qml).
    readonly property var revealStyles: ["iris", "corner", "wipe", "zoom"]
    property string revealStyle: "iris"
    property int revealMs: 1000

    function pickStyle(): string {
        let style = revealStyle;
        while (style === revealStyle)
            style = revealStyles[Math.floor(Math.random() * revealStyles.length)];
        revealStyle = style;
        return style;
    }

    onSourceChanged: {
        if (!source)
            current = null;
        else
            current = imgComp.createObject(this, {
                path: source
            });
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                current = imgComp.createObject(this, {
                    path: source
                });
                completed = true;
            });
    }

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: Tr.tr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: Tr.tr("Select a wallpaper")
                            filterLabel: Tr.tr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: Tr.tr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    Component {
        id: imgComp

        // [macos] one wallpaper: the image inside a clip that grows to reveal it
        // (the first wallpaper after login just fades in, as before)
        Item {
            id: holder

            property string path
            readonly property int status: img.status

            // reveal state: the clip, in holder coordinates
            property real cx: width / 2
            property real cy: height / 2
            property real r: 0          // iris / corner radius
            property real wipe: 0       // wipe progress 0..1
            property string style: "full"
            property bool wipeVertical: false
            property bool wipeReverse: false

            anchors.fill: parent
            opacity: 0

            function reveal(): void {
                Hyprland.dispatch(`hl.dsp.event("macwall>>${root.revealMs}")`);
                style = root.pickStyle();
                opacity = 1;
                if (style === "iris" || style === "corner") {
                    if (style === "corner") {
                        cx = Math.random() < 0.5 ? 0 : width;
                        cy = Math.random() < 0.5 ? 0 : height;
                    }
                    const far = Math.max(Math.hypot(cx, cy), Math.hypot(width - cx, cy), Math.hypot(cx, height - cy), Math.hypot(width - cx, height - cy));
                    r = 0;
                    radiusAnim.to = far + 2;
                    radiusAnim.start();
                } else if (style === "wipe") {
                    wipeVertical = Math.random() < 0.35;
                    wipeReverse = Math.random() < 0.5;
                    wipe = 0;
                    wipeAnim.start();
                } else { // zoom: a fade while it settles
                    style = "full";
                    opacity = 0;
                    fadeIn.duration = 800;
                    fadeIn.start();
                }
                settle.from = style === "full" ? 1.1 : 1.05;
                settle.start();
                doneTimer.restart();
            }

            NumberAnimation {
                id: radiusAnim

                target: holder
                property: "r"
                duration: root.revealMs
                easing.type: Easing.InOutCubic
            }

            NumberAnimation {
                id: wipeAnim

                target: holder
                property: "wipe"
                to: 1
                duration: root.revealMs
                easing.type: Easing.InOutQuart
            }

            NumberAnimation {
                id: fadeIn

                target: holder
                property: "opacity"
                to: 1
                easing.type: Easing.OutCubic
            }

            Timer {
                id: doneTimer

                interval: root.revealMs + 50
                onTriggered: holder.style = "full" // drop the clip
            }

            ClippingRectangle {
                id: clip

                readonly property bool round: holder.style === "iris" || holder.style === "corner"

                color: "transparent"
                x: holder.style === "full" ? 0 : round ? holder.cx - holder.r : !holder.wipeVertical && holder.wipeReverse ? holder.width * (1 - holder.wipe) : 0
                y: holder.style === "full" ? 0 : round ? holder.cy - holder.r : holder.wipeVertical && holder.wipeReverse ? holder.height * (1 - holder.wipe) : 0
                width: holder.style === "full" ? holder.width : round ? holder.r * 2 : holder.wipeVertical ? holder.width : holder.width * holder.wipe
                height: holder.style === "full" ? holder.height : round ? holder.r * 2 : holder.wipeVertical ? holder.height * holder.wipe : holder.height
                radius: round ? holder.r : 0

                CachingImage {
                    id: img

                    path: holder.path
                    // the image stays put while the clip moves over it
                    x: -clip.x
                    y: -clip.y
                    width: holder.width
                    height: holder.height

                    NumberAnimation on scale {
                        id: settle

                        running: false
                        to: 1
                        duration: root.revealMs
                        easing.type: Easing.OutCubic
                    }

                    onStatusChanged: {
                        if (status !== Image.Ready)
                            return;
                        if (root.completed) {
                            holder.reveal();
                        } else {
                            holder.style = "full";
                            fadeIn.duration = 600;
                            fadeIn.start();
                        }
                    }
                }
            }

            Timer {
                running: root.current !== holder && root.current?.status === Image.Ready
                interval: root.revealMs + 150
                onTriggered: holder.destroy()
            }
        }
    }
}
