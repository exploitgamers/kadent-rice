pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    readonly property int spacing: Tokens.spacing.small
    property bool flag

    function shouldShowToast(toast: Toast): bool {
        if (!Notifs.hasFullscreen())
            return true;
        if (GlobalConfig.utilities.toasts.fullscreen === "all")
            return true;
        if (GlobalConfig.utilities.toasts.fullscreen === "important")
            return toast.type === Toast.Warning || toast.type === Toast.Error;
        return false;
    }

    // [macos] compact toasts (caps lock etc. were too big and distracting)
    implicitWidth: Math.round((Tokens.sizes.utilities.toastWidth - Tokens.padding.medium * 2) * 0.72)
    implicitHeight: {
        let h = -spacing;
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i) as ToastWrapper;
            if (!item.modelData.closed && !item.previewHidden)
                h += item.implicitHeight + spacing;
        }
        return h;
    }

    // [macos] temporary messages (caps lock, charger, audio device, VPN…) go to the
    // notification centre as real notifications — same look and place as the others, and
    // kept in the list — instead of separate toasts. The same kind of message (caps lock
    // on, then off) replaces its earlier notification rather than stacking.
    property var forwarded: []
    property var replaceIds: ({})

    function kindOf(title: string): string {
        return title.replace(/\b(enabled|disabled|on|off|connected|disconnected|plugged in|unplugged|changed|failed|required)\b/gi, "").trim().toLowerCase();
    }

    function forward(toast: Toast): void {
        const key = kindOf(Tr.trMarked(toast.title));
        const urgency = toast.type === Toast.Error ? "critical" : toast.type === Toast.Warning ? "normal" : "low";
        const args = ["notify-send", "-p", "-a", "System", "-u", urgency];
        if (urgency === "low")
            args.push("-t", "3000");
        // [macos] close the previous one of this kind in-process and send a fresh one:
        // a `-r` replace only updates a tracked notification and never pops it up again
        const prev = Notifs.list.find(n => n.notificationId === replaceIds[key]);
        if (prev)
            prev.close();
        args.push("--", Tr.trMarked(toast.title), Tr.trMarked(toast.message)); // [macos] "--": a title/message (track artist, VPN name) starting with '-' isn't an option
        sender.createObject(root, { key: key, command: args });
    }

    Component {
        id: sender

        Process {
            id: proc

            property string key

            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const id = text.trim();
                    if (id)
                        root.replaceIds[proc.key] = id;
                }
            }
            onExited: destroy()
        }
    }

    Connections {
        target: Toaster

        function onToastsChanged(): void {
            const fresh = Toaster.toasts.filter(t => !t.closed && !root.forwarded.includes(t));
            for (const t of fresh) {
                root.forward(t);
                t.close();
            }
            root.forwarded = Toaster.toasts.filter(t => root.forwarded.includes(t) || fresh.includes(t));
        }
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: {
                return []; // [macos] shown as notifications instead (see forward())
                const toasts = [];
                let count = 0;
                for (const toast of Toaster.toasts) {
                    if (!root.shouldShowToast(toast))
                        continue;
                    toasts.push(toast);
                    if (!toast.closed) {
                        count++;
                        if (count > root.Config.utilities.maxToasts)
                            break;
                    }
                }
                return toasts;
            }
            onValuesChanged: root.flagChanged()
        }

        ToastWrapper {}
    }

    component ToastWrapper: MouseArea {
        id: toast

        required property int index
        required property Toast modelData

        readonly property bool previewHidden: {
            let extraHidden = 0;
            for (let i = 0; i < index; i++)
                if (Toaster.toasts[i].closed)
                    extraHidden++;
            return index >= Config.utilities.maxToasts + extraHidden;
        }

        onPreviewHiddenChanged: {
            if (initAnim.running && previewHidden)
                initAnim.stop();
        }

        opacity: modelData.closed || previewHidden ? 0 : 1
        scale: modelData.closed || previewHidden ? 0.7 : 1

        anchors.bottomMargin: {
            root.flag; // Force update
            let y = 0;
            for (let i = 0; i < index; i++) {
                const item = repeater.itemAt(i) as ToastWrapper;
                if (item && !item.modelData.closed && !item.previewHidden)
                    y += item.implicitHeight + root.spacing;
            }
            return y;
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: toastInner.implicitHeight

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: modelData.close()

        Component.onCompleted: modelData.lock(this)

        Anim {
            id: initAnim

            Component.onCompleted: running = !toast.previewHidden

            target: toast
            properties: "opacity,scale"
            from: 0
            to: 1
        }

        ParallelAnimation {
            running: toast.modelData.closed
            onStarted: toast.anchors.bottomMargin = toast.anchors.bottomMargin
            onFinished: toast.modelData.unlock(toast)

            Anim {
                type: Anim.DefaultEffects
                target: toast
                property: "opacity"
                to: 0
            }
            Anim {
                target: toast
                property: "scale"
                to: 0.7
            }
        }

        ToastItem {
            id: toastInner

            modelData: toast.modelData
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on anchors.bottomMargin {
            Anim {}
        }
    }
}
