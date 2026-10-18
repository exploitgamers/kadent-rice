import QtQuick
import Quickshell
import qs.services

// [macos] adaptive ink for one bar pill, like the macOS menu bar: its text and icons turn dark
// over a bright wallpaper and light over a dark one. The pill's colour is composited over the
// wallpaper's average colour behind it (services/WallStrip.qml) and whichever ink has the higher
// WCAG contrast wins, with some hysteresis. Pass every foreground colour through c().
Item {
    id: root

    required property Item pill
    property bool dark: nativeDark

    readonly property bool nativeDark: Colours.palette.m3onSurface.hslLightness < 0.5
    readonly property var strip: WallStrip.columns[(QsWindow.window as QsWindow)?.screen?.name ?? ""] ?? null
    // the pill's span on its screen (the bar window covers the screen); re-read when it moves
    readonly property real x0: {
        pill.width;
        pill.parent?.x;
        pill.parent?.parent?.x;
        return pill.mapToItem(null, 0, 0).x;
    }
    // > 0: dark ink reads better, < 0: light ink (log of the contrast ratio between the two)
    readonly property real score: {
        const s = strip;
        const sw = (QsWindow.window as QsWindow)?.screen?.width ?? 0;
        if (!s || !s.length || sw <= 0 || pill.width <= 0)
            return 0;
        const a = Math.max(0, Math.min(s.length - 1, Math.floor(x0 / sw * s.length)));
        const b = Math.max(a, Math.min(s.length - 1, Math.floor((x0 + pill.width) / sw * s.length)));
        const bg = [0, 0, 0];
        for (let i = a; i <= b; i++)
            for (let k = 0; k < 3; k++)
                bg[k] += s[i][k] / (b - a + 1);
        const p = pill.color ?? Qt.rgba(0, 0, 0, 0); // OsIcon / Power have no pill
        const comp = Qt.rgba(p.r * p.a + bg[0] * (1 - p.a), p.g * p.a + bg[1] * (1 - p.a), p.b * p.a + bg[2] * (1 - p.a), 1);
        const fg = Colours.palette.m3onSurface;
        const dk = nativeDark ? fg : invert(fg, true);
        const lt = nativeDark ? invert(fg, false) : fg;
        return Math.log(contrast(dk, comp) / contrast(lt, comp));
    }

    onScoreChanged: {
        if (score === 0)
            dark = nativeDark;
        else if (dark ? score < -0.15 : score > 0.15)
            dark = !dark;
    }
    onNativeDarkChanged: dark = score === 0 ? nativeDark : score > 0

    function lum(c: color): real {
        const f = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
    }

    function contrast(x: color, y: color): real {
        const a = lum(x), b = lum(y);
        return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
    }

    // same hue and saturation, lightness mirrored (accents stay recognisable: red stays red)
    function invert(c: color, toDark: bool): color {
        const l = 1 - c.hslLightness;
        return Qt.hsla(Math.max(0, c.hslHue), c.hslSaturation, toDark ? Math.min(0.32, l) : Math.max(0.75, l), c.a);
    }

    function c(col: color): color {
        return dark === nativeDark ? col : invert(col, dark);
    }
}
