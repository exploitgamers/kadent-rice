pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night Shift: warmer screen colours at night via hyprsunset (4000 K).
// Mode in macos.json nightShift: "auto" (sunset → sunrise, from the times the
// Weather widget fetches; 19:00–07:00 if unknown), "on", or "off".
// Does nothing until hyprsunset is installed.
Singleton {
    id: root

    property bool installed: false
    property int tick: 0 // bumped each minute in auto mode
    // night is computed inside the binding so switching to auto never uses a stale value (no warm flash by day)
    readonly property bool active: installed && (Config.nightShift === "on" || (Config.nightShift === "auto" && isNight(tick)))

    function minutes(hhmm: string, fallback: int): int {
        const m = /^(\d\d):(\d\d)$/.exec(hhmm ?? "");
        return m ? Number(m[1]) * 60 + Number(m[2]) : fallback;
    }

    function isNight(_tick: int): bool {
        const now = new Date();
        const t = now.getHours() * 60 + now.getMinutes();
        const rise = minutes(WeatherData.sunrise, 7 * 60), set = minutes(WeatherData.sunset, 19 * 60);
        return t >= set || t < rise;
    }

    // cycles auto → on → off (Spotlight / desktop menu)
    function cycle(): void {
        Config.setNightShift(Config.nightShift === "auto" ? "on" : Config.nightShift === "on" ? "off" : "auto");
    }

    Timer {
        running: root.installed && Config.nightShift === "auto" // only auto follows the clock
        interval: 60 * 1000
        repeat: true
        onTriggered: root.tick++
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.installed = code === 0
    }

    // One hyprsunset at a time, whoever started it: every change (and every shell
    // start) first stops all of them — a hyprsunset orphaned by a shell restart
    // kept the screen warm after Night Shift was turned off. Off = a moment of
    // the identity matrix, so the colours are reset even if it wasn't running.
    Process {
        id: sunset
    }

    function apply(): void {
        sunset.running = false;
        // set here, not as a binding: a binding may update after onActiveChanged and start the old command
        sunset.command = active
            ? ["sh", "-c", "pkill -x hyprsunset; sleep 0.2; exec hyprsunset -t 4000"]
            : ["sh", "-c", "pkill -x hyprsunset; sleep 0.2; hyprsunset -i & sleep 0.6; kill $! 2>/dev/null; true"];
        sunset.running = true;
    }

    onActiveChanged: apply()
    onInstalledChanged: if (installed) apply()
}
