pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Recent items for the app widgets (Files, Photos, VSCodium, Kdenlive).
// Each source refreshes every 30 s, and only while a widget that shows it exists.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    function used(type: string): bool {
        return Config.widgetItems.some(w => w.type === type) || Shared.widgetEdit;
    }

    property var recentFiles: []  // [{ path, name }]
    property var photos: []       // [path]
    property var codeFolders: []  // [{ path, name }]
    property var kdenliveProjects: [] // [{ path, name }]
    property var firefoxSites: []     // [{ path: url, name: title }]

    function baseName(p: string): string {
        return p.replace(/\/+$/, "").split("/").pop();
    }

    function open(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function refresh(): void {
        if (used("files"))
            xbel.reload();
        if (used("photos"))
            photoScan.running = true;
        if (used("vscodium"))
            codeScan.running = true;
        if (used("kdenlive"))
            kdenliverc.reload();
        if (used("firefox"))
            firefoxScan.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        running: root.used("files") || root.used("photos") || root.used("vscodium") || root.used("kdenlive") || root.used("firefox")
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // GTK's recently-used list (Thunar, file pickers, most GTK apps)
    FileView {
        id: xbel

        path: root.home + "/.local/share/recently-used.xbel"
        printErrors: false
        onLoaded: {
            const items = [];
            const re = /<bookmark href="file:\/\/([^"]+)"[^>]*modified="([^"]+)"/g;
            let m;
            while ((m = re.exec(text())) !== null) {
                const p = decodeURIComponent(m[1]);
                items.push({ path: p, name: root.baseName(p), when: Date.parse(m[2]) || 0 });
            }
            items.sort((a, b) => b.when - a.when);
            root.recentFiles = items.slice(0, 8);
        }
    }

    // newest images in Pictures (incl. Screenshots) and Downloads
    Process {
        id: photoScan

        command: ["sh", "-c", "find \"$HOME/Pictures\" \"$HOME/Downloads\" -maxdepth 3 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) -printf '%T@ %p\\n' 2>/dev/null | sort -rn | head -9 | cut -d' ' -f2-"]
        stdout: StdioCollector {
            onStreamFinished: root.photos = text.trim() ? text.trim().split("\n") : []
        }
    }

    // VSCodium's recently opened folders/workspaces
    Process {
        id: codeScan

        command: ["sqlite3", "-readonly", root.home + "/.config/VSCodium/User/globalStorage/state.vscdb",
            "select value from ItemTable where key='history.recentlyOpenedPathsList'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try {
                    list = (JSON.parse(text || "{}").entries ?? [])
                        .map(e => e.folderUri ?? e.workspace?.configPath ?? e.fileUri ?? "")
                        .filter(u => u.startsWith("file://"))
                        .map(u => decodeURIComponent(u.slice(7)));
                } catch (e) {}
                root.codeFolders = list.slice(0, 6).map(p => ({ path: p, name: root.baseName(p) }));
            }
        }
    }

    // Firefox's most visited sites. immutable=1 reads the history database
    // without touching Firefox's lock, so it works while Firefox is open.
    Process {
        id: firefoxScan

        command: ["sh", "-c", "db=$(ls -t \"$HOME\"/.config/mozilla/firefox/*/places.sqlite \"$HOME\"/.mozilla/firefox/*/places.sqlite 2>/dev/null | head -1); [ -n \"$db\" ] && sqlite3 -separator '\t' \"file:$db?immutable=1\" \"select title, url from moz_places where hidden = 0 and title is not null and title <> '' and url like 'http%' order by frecency desc limit 12\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = new Set();
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const [name, url] = line.split("\t");
                    if (!url)
                        continue;
                    const host = url.replace(/^https?:\/\/(www\.)?/, "").split("/")[0];
                    if (seen.has(host))
                        continue; // one entry per site
                    seen.add(host);
                    out.push({ path: url, name: name.replace(/^\u200e/, "").trim() || host, host: host });
                }
                root.firefoxSites = out.slice(0, 8);
            }
        }
    }

    // Kdenlive's recent projects ([RecentFiles] File1=… in kdenliverc)
    FileView {
        id: kdenliverc

        path: root.home + "/.config/kdenliverc"
        printErrors: false
        onLoaded: {
            const sec = (text().split(/^\[RecentFiles\]$/m)[1] ?? "").split(/^\[/m)[0];
            const files = [];
            const re = /^File(\d+)=(.+)$/gm;
            let m;
            while ((m = re.exec(sec)) !== null)
                files.push({ n: Number(m[1]), path: m[2].trim() });
            // KDE lists the most recent last
            files.sort((a, b) => b.n - a.n);
            root.kdenliveProjects = files.slice(0, 6).map(f => ({ path: f.path, name: root.baseName(f.path).replace(/\.kdenlive$/, "") }));
        }
        onLoadFailed: root.kdenliveProjects = []
    }
}
