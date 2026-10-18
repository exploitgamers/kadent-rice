pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery-smart mode: on battery at ≤ 30 %, switch to the power-saver profile and
// drop the costliest effects (widget frosted glass and dimming, per-second widget
// updates). Plugging in (or charging above 30 %) restores the previous profile.
// The previous profile is kept in a file: held only in memory, a shell restart while
// saving forgot it, and the laptop stayed in power-saver after being plugged back in.
Singleton {
    id: root

    readonly property bool saving: UPower.onBattery && UPower.displayDevice.isLaptopBattery
        && UPower.displayDevice.percentage <= 0.3

    property string previousProfile: ""

    function remember(p: string): void {
        previousProfile = p;
        store.setText(p);
    }

    function restore(): void {
        if (previousProfile)
            Quickshell.execDetached(["powerprofilesctl", "set", previousProfile]);
        remember("");
    }

    onSavingChanged: {
        if (saving)
            getProfile.running = true; // remember it, then switch
        else
            restore();
    }

    Component.onCompleted: {
        previousProfile = store.text().trim();
        if (saving)
            getProfile.running = true;
        else if (previousProfile)
            checkStuck.running = true;
    }

    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.local/state/macos-power-previous"
        blockLoading: true
    }

    Process {
        id: getProfile

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p && p !== "power-saver")
                    root.remember(p);
                if (root.saving)
                    Quickshell.execDetached(["powerprofilesctl", "set", "power-saver"]);
            }
        }
    }

    // started with a profile still to restore: put it back only if we're still in the
    // power-saver this switched to (not if it was changed by hand since)
    Process {
        id: checkStuck

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "power-saver")
                    root.restore();
                else
                    root.remember("");
            }
        }
    }
}
