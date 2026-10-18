pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Smart Rotate for widget stacks (toggle in Edit Stack). Scores each widget in a
// stack from what's going on right now and brings the most relevant one to the
// front:
//   music playing → Now Playing      rain/storm in the next 3 h → Weather
//   morning → Calendar, Weather      battery ≤ 20 % and not charging → Batteries
//   CPU / memory busy → System       work hours → VSCodium, Files, Notes
//   evening → Kdenlive               weekend → Photos
// It never fights you: after you cycle a stack by hand it waits 10 minutes.
Singleton {
    id: root

    readonly property var smartKeys: {
        const keys = new Set();
        for (const w of Config.widgetItems)
            if (w.smartRotate && w.stack)
                keys.add(w.stack);
        return [...keys];
    }
    readonly property bool active: smartKeys.length > 0

    // ── context ──────────────────────────────────────────────────────────
    readonly property bool musicPlaying: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool rainSoon: WeatherData.hourly.slice(0, 4).some(h =>
        (h.code >= 51 && h.code <= 67) || (h.code >= 71 && h.code <= 86) || h.code >= 95)
    readonly property bool batteryLow: UPower.displayDevice.isLaptopBattery && UPower.displayDevice.percentage <= 0.2
        && UPower.displayDevice.state !== UPowerDeviceState.Charging
    readonly property bool busy: SysStats.cpu > 0.85 || SysStats.mem > 0.9

    function score(type: string): real {
        const now = new Date();
        const h = now.getHours();
        const weekend = now.getDay() === 0 || now.getDay() === 6;
        const work = !weekend && h >= 9 && h < 18;
        switch (type) {
        case "music": return musicPlaying ? 100 : 5;
        case "weather": return rainSoon ? 90 : h >= 6 && h < 10 ? 55 : 30;
        case "conditions": return rainSoon ? 70 : h >= 11 && h < 16 && WeatherData.uv >= 6 ? 60 : 20;
        case "calendar": return h >= 6 && h < 11 ? 60 : 25;
        case "battery": return batteryLow ? 95 : 10;
        case "system": return busy ? 80 : 15;
        case "vscodium": return work ? 45 : 15;
        case "files": return work ? 35 : 20;
        case "notes": return work ? 35 : 20;
        case "kdenlive": return h >= 18 ? 40 : 15;
        case "photos": return weekend ? 35 : 15;
        case "shortcuts": return 30;
        case "clock": return 20;
        default: return 10;
        }
    }

    function evaluate(): void {
        for (const key of smartKeys) {
            if (Date.now() - (Shared.stackTouched[key] ?? 0) < 10 * 60 * 1000)
                continue; // you picked one recently
            const members = Config.widgetItems.filter(w => Config.stackKey(w) === key)
                .sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
            if (members.length < 2)
                continue;
            let best = members[0];
            for (const m of members)
                if (score(m.type) > score(best.type))
                    best = m;
            if (best !== members[0] && score(best.type) > score(members[0].type) + 5)
                Config.bringToFront(best.id);
        }
    }

    Timer {
        running: root.active
        interval: 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.evaluate()
    }

    // react right away when something important changes
    onMusicPlayingChanged: if (active) evaluate()
    onRainSoonChanged: if (active) evaluate()
    onBatteryLowChanged: if (active) evaluate()
    onBusyChanged: if (active) evaluate()
    onSmartKeysChanged: if (active) Qt.callLater(root.evaluate) // deferred: evaluate() writes widgets.items, which smartKeys is bound to (binding loop)
}
