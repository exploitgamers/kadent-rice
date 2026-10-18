pragma ComponentBehavior: Bound

import "./kblayout"
import "../../dashboard/dash" as Dash
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property PopoutState popouts
    readonly property Popout currentPopout: content.children.find(c => c.shouldBeActive) ?? null
    readonly property Item current: currentPopout?.item ?? null

    readonly property var trayItemsToIndices: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id)).reduce((acc, item, i) => {
        acc[item.id] = i;
        return acc;
    }, {})

    // [macos] 12 px inside the 22 px panel corner, so corner cards nest at 22 − 12 = 10 (macos MusicDrop does the same)
    implicitWidth: currentPopout ? currentPopout.implicitWidth + Tokens.padding.medium * 2 : 0
    implicitHeight: currentPopout ? currentPopout.implicitHeight + Tokens.padding.medium * 2 : 0

    // which month the clock's calendar shows (its own, the dashboard is off)
    ScreenState {
        id: calendarState

        modelData: Quickshell.screens[0]
    }

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium // [macos]

        Popout {
            name: "activewindow"
            sourceComponent: ActiveWindow {
                popouts: root.popouts
            }
        }

        Popout {
            id: networkPopout

            name: "network"
            sourceComponent: Network {
                popouts: root.popouts
                view: Nmcli.activeEthernet ? "ethernet" : "wireless"
            }
        }

        Popout {
            id: passwordPopout

            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                id: passwordComponent

                popouts: root.popouts
                network: (networkPopout.item as Network)?.passwordNetwork ?? null
            }

            Connections {
                function onCurrentNameChanged() {
                    // Update network immediately when password popout becomes active
                    if (root.popouts.currentName === "wirelesspassword") {
                        // Set network immediately if available
                        if ((networkPopout.item as Network)?.passwordNetwork) {
                            if (passwordPopout.item) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        }
                        // Also try after a short delay in case networkPopout.item wasn't ready
                        Qt.callLater(() => {
                            if (passwordPopout.item && (networkPopout.item as Network)?.passwordNetwork) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        }, 100);
                    }
                }

                target: root.popouts
            }

            Connections {
                function onItemChanged() {
                    // When network popout loads, update password popout if it's active
                    if (root.popouts.currentName === "wirelesspassword" && passwordPopout.item) {
                        Qt.callLater(() => {
                            if ((networkPopout.item as Network)?.passwordNetwork) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        });
                    }
                }

                target: networkPopout
            }
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                popouts: root.popouts
            }
        }

        Popout {
            name: "battery"
            sourceComponent: Battery {}
        }

        // [macos] the top bar's volume / brightness pill, expanded
        Popout {
            name: "controls"
            sourceComponent: Controls {}
        }

        // [macos] the top bar's now-playing pill, expanded (on hover)
        Popout {
            name: "media"
            sourceComponent: Media {}
        }

        // [macos] the top bar's system pill, expanded
        Popout {
            name: "sysmon"
            sourceComponent: SystemMonitor {}
        }

        // [macos] the top-bar clock: the time and date beside a month calendar
        // (Caelestia's dashboard pieces; scroll or use the arrows to change month)
        Popout {
            name: "calendar"
            sourceComponent: Row {
                spacing: Tokens.spacing.medium

                Dash.DateTime {
                    // [macos] DateTime anchors top/bottom for the dashboard; here it takes the calendar's height
                    anchors.top: undefined
                    anchors.bottom: undefined
                    height: calendar.implicitHeight
                }

                StyledRect {
                    width: 300
                    height: calendar.implicitHeight
                    radius: 10 // [macos] concentric: 22 panel corner − 12 inset
                    color: Colours.tPalette.m3surfaceContainer

                    Dash.Calendar {
                        id: calendar

                        screenState: calendarState
                    }
                }
            }
        }

        Popout {
            name: "audio"
            sourceComponent: AudioPopout {
                popouts: root.popouts
            }
        }

        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }

        Popout {
            name: "lockstatus"
            sourceComponent: LockStatus {}
        }

        Repeater {
            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.hasMenu && i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData

                name: `traymenu${root.trayItemsToIndices[modelData.id]}`
                sourceComponent: trayMenuComp

                Connections {
                    function onHasCurrentChanged(): void {
                        if (root.popouts.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }

                    target: root.popouts
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.popouts
                        trayItem: trayMenu.modelData.menu // qmllint disable unresolved-type
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: root.popouts.currentName === name
        property bool ready: true

        anchors.centerIn: parent

        opacity: 0
        active: false

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        property: "opacity"
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        property: "opacity"
                        type: Anim.SlowEffects
                    }
                }
            }
        ]
    }
}
