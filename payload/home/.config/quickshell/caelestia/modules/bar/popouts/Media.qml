pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtQuick.Effects
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// [macos] the top bar's now-playing pill, expanded (opens on hover): the album art on
// a spinning disc — it turns while playing and holds still when paused — the track,
// a progress line, and back / play-pause / skip.
Row {
    id: root

    readonly property var player: Players.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string art: Players.getArtUrl(player)

    function time(s: real): string {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    spacing: Tokens.spacing.large
    padding: 0 // [macos] the drop-down already pads 12 px, like every other one

    // ── the disc ──
    Item {
        id: disc

        width: 112
        height: 112
        anchors.verticalCenter: parent.verticalCenter

        // render thread, so it stays smooth while the shell is busy
        RotationAnimator {
            target: record
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
            running: true
            paused: !root.playing
        }

        Item {
            id: record

            anchors.fill: parent
            // drawn once into a smooth texture, so the turning edge stays clean (it was jagged)
            layer.enabled: true
            layer.smooth: true
            layer.textureSize: Qt.size(width * 2, height * 2)

            // the record: dark vinyl, the album art masked to a circle with a soft,
            // antialiased edge (a clipping rectangle left it ragged)
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#161616"
            }

            Image {
                id: artImage

                anchors.fill: parent
                visible: false
                source: root.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(256, 256)
            }

            Item {
                id: circleMask

                anchors.fill: parent
                visible: false
                layer.enabled: true
                layer.smooth: true

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    antialiasing: true
                }
            }

            MultiEffect {
                anchors.fill: parent
                visible: root.art !== ""
                source: artImage
                maskEnabled: true
                maskSource: circleMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            // no art: a plain record with a note
            MaterialIcon {
                anchors.centerIn: parent
                visible: root.art === ""
                text: "music_note"
                color: "#8a8a8a"
                fontStyle: Tokens.font.icon.large
            }

            // vinyl grooves over the art
            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    anchors.centerIn: parent
                    width: disc.width * (0.86 - index * 0.18)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.18)
                }
            }
        }

        // the rim: a crisp edge all the way round (doesn't turn, so it never shimmers)
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            antialiasing: true
            border.width: 1.5
            border.color: Qt.rgba(0, 0, 0, 0.55)
        }

        // the hole in the middle (doesn't turn)
        Rectangle {
            anchors.centerIn: parent
            width: 22
            height: 22
            radius: 11
            color: Colours.palette.m3surfaceContainer
            border.width: 2
            border.color: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: 220
        spacing: Tokens.spacing.small

        StyledText {
            width: parent.width
            elide: Text.ElideRight
            text: root.player?.trackTitle || "Nothing playing"
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
        }

        StyledText {
            width: parent.width
            elide: Text.ElideRight
            text: root.player?.trackArtist || Players.getIdentity(root.player)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        // progress (MPRIS only reports the position when asked)
        Item {
            width: parent.width
            height: 22
            visible: (root.player?.length ?? 0) > 0

            Timer {
                running: root.playing && root.visible
                interval: 1000
                repeat: true
                onTriggered: root.player?.positionChanged()
            }

            Rectangle {
                id: track

                width: parent.width
                height: 4
                radius: 2
                color: Colours.tPalette.m3surfaceContainerHighest

                Rectangle {
                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                    height: parent.height
                    radius: 2
                    color: Colours.palette.m3primary

                    Behavior on width {
                        NumberAnimation { duration: 900; easing.type: Easing.Linear }
                    }
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: root.time(root.player?.position ?? 0)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.85).build()
            }

            StyledText {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: root.time(root.player?.length ?? 0)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(0.85).build()
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.spacing.medium

            MediaButton {
                icon: "skip_previous"
                enabled: root.player?.canGoPrevious ?? false
                onActivated: root.player?.previous()
            }

            MediaButton {
                icon: root.playing ? "pause" : "play_arrow"
                big: true
                enabled: root.player?.canTogglePlaying ?? false
                onActivated: root.player?.togglePlaying()
            }

            MediaButton {
                icon: "skip_next"
                enabled: root.player?.canGoNext ?? false
                onActivated: root.player?.next()
            }
        }
    }

    component MediaButton: StyledRect {
        id: button

        property string icon
        property bool big
        signal activated

        width: big ? 40 : 32
        height: width
        radius: width / 2
        color: big ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer
        opacity: enabled ? 1 : 0.4

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            color: button.big ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            fontStyle: button.big ? Tokens.font.icon.large : Tokens.font.icon.medium
        }

        StateLayer {
            radius: button.radius
            color: button.big ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            disabled: !button.enabled
            onClicked: button.activated()
        }
    }
}
