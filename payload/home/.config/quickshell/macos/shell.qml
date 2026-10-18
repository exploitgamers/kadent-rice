//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// macOS-style bottom dock and Now Playing card on top of Caelestia.
// Run with: qs -c macos   (started from ~/.config/caelestia/hypr-user.lua)
ShellRoot {
    // no hot reload on QML edits (like Caelestia): each reload kept ~9 MB, and edits are applied with rice-restart anyway
    settings.watchFiles: false

    // per-app volumes start applying as soon as the shell does (AppVolumes.qml)
    readonly property var appVolumes: AppVolumes

    Variants {
        model: Quickshell.screens
        DesktopWidgets {}
    }

    // Heavy (~50 MB of live previews), so loaded only around use (WarmLoader: built in the
    // background when asked for or when the desktop menu opens, kept 45 s after closing)
    Variants {
        model: Quickshell.screens

        WarmLoader {
            id: galleryLoader

            want: Shared.widgetEdit

            WidgetGallery {
                modelData: galleryLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        BottomDock {}
    }

    Variants {
        model: Quickshell.screens
        WindowMenu {}
    }

    Variants {
        model: Quickshell.screens
        SnapPreview {}
    }

    Variants {
        model: Quickshell.screens
        DesktopDropPicker {}
    }

    HotCorners {}

    // qs -c macos ipc call forcequit toggle   (SUPER+ALT+Escape)
    ForceQuit {
        id: forceQuit
    }

    IpcHandler {
        target: "forcequit"

        function toggle(): void {
            forceQuit.open = !forceQuit.open;
        }
    }

    Variants {
        model: Quickshell.screens
        Overview {}
    }

    // qs -c macos ipc call overview toggle   (SUPER+`)
    IpcHandler {
        target: "overview"

        function toggle(): void {
            Shared.overviewOpen = !Shared.overviewOpen;
        }
    }

    Variants {
        model: Quickshell.screens
        StackEditor {}
    }

    Variants {
        model: Quickshell.screens
        Spotlight {}
    }

    Variants {
        model: Quickshell.screens
        AppSwitcher {}
    }

    Variants {
        model: Quickshell.screens
        DesktopIndicator {}
    }

    Variants {
        model: Quickshell.screens
        DesktopSwitcher {}
    }

    // same pattern as the gallery (thumbnails hold a lot)
    Variants {
        model: Quickshell.screens

        WarmLoader {
            id: wallLoader

            want: Shared.wallpaperOpen

            WallpaperBrowser {
                modelData: wallLoader.modelData
            }
        }
    }

    Settings {}

    // qs -c macos ipc call settings open [page]
    IpcHandler {
        target: "settings"

        function open(): void {
            Shared.settingsOpen = true;
        }

        function toggle(): void {
            Shared.settingsOpen = !Shared.settingsOpen;
        }

        // appearance, desktop, widgets, windows, menubar, displays, maintenance
        function page(name: string): void {
            Shared.settingsPage = name;
            Shared.settingsOpen = true;
        }
    }

    // qs -c macos ipc call wallpaper open
    IpcHandler {
        target: "wallpaper"

        function open(): void {
            Shared.wallpaperOpen = true;
        }

        function toggle(): void {
            Shared.wallpaperOpen = !Shared.wallpaperOpen;
        }
    }

    // Smart Rotate runs as soon as any stack has it on
    readonly property bool smartRotateActive: SmartRotate.active
    readonly property bool nightShiftActive: NightShift.active // instantiates it
    readonly property bool powerSaving: PowerSaver.saving // instantiates it

    // qs -c macos ipc call spotlight toggle   (SUPER+Space)
    IpcHandler {
        target: "spotlight"

        function toggle(): void {
            Shared.spotlightOpen = !Shared.spotlightOpen;
        }

        // open with text: qs -c macos ipc call spotlight search "2+2"
        function search(text: string): void {
            Shared.spotlightQuery = text;
            Shared.spotlightOpen = true;
        }
    }

    Variants {
        model: Quickshell.screens
        AppLauncher {}
    }

    Variants {
        model: Quickshell.screens
        EdgeShield {}
    }

    Variants {
        model: Quickshell.screens
        FullscreenBar {}
    }

    // Window-drag signal from Hyprland (left button held), see hypr-qol.lua
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            // Alt+Tab switcher: show|index|addr,addr…  /  hide
            if (event.name === "custom" && event.data.startsWith("macswitch>>")) {
                const parts = event.data.slice(11).split("|");
                if (parts[0] === "show") {
                    // like Cmd+Tab on macOS: switching away dismisses Launchpad/Spotlight
                    // (they stayed up while the keyboard went to the picked window)
                    Shared.launcherOpen = false;
                    Shared.spotlightOpen = false;
                    Shared.appSwitcher(parts[2].split(","), Number(parts[1]) - 1);
                } else {
                    Shared.appSwitcherHide();
                }
                return;
            }
            // SUPER+Tab switcher: show|index|id:class,class;id:…  /  hide
            if (event.name === "custom" && event.data.startsWith("macdesks>>")) {
                const parts = event.data.slice(10).split("|");
                if (parts[0] === "show")
                    Shared.desktopSwitcher(parts[2].split(";").map(d => {
                        const [id, cls] = d.split(":");
                        return { id: Number(id), classes: cls ? cls.split(",").filter(c => c) : [] };
                    }), Number(parts[1]) - 1);
                else
                    Shared.desktopSwitcherHide();
                return;
            }
            // SUPER+Tab landed: current|id,id…
            if (event.name === "custom" && event.data.startsWith("macdesk>>")) {
                const parts = event.data.slice(9).split("|");
                Shared.desktopChanged(Number(parts[0]), parts[1].split(",").map(Number));
                return;
            }
            // title-bar click → window menu (hypr-qol.lua): address,x,y,floating,pinned,button
            if (event.name === "custom" && event.data.startsWith("macwinmenu>>")) {
                const [addr, x, y, fl, pin, button] = event.data.slice(12).split(",");
                // the chosen click opens it, and right-click always does (unless it's off)
                if (Config.titlebarMenu === button || (button === "right" && Config.titlebarMenu !== "off"))
                    Shared.windowMenu(addr, Number(x), Number(y), fl === "1", pin === "1");
                return;
            }
            if (event.name === "custom" && event.data.startsWith("macbarclick>>")) { // title-bar plugin
                Shared.launcherOpen = false; // hyprbars swallows the press, so no macdrag closes it
                Hyprland.dispatch(`mac_bar_click("${event.data.slice(13)}") or hl.dsp.event("macack")`);
                return;
            }
            if (event.name === "custom" && event.data.startsWith("macgrab>>")) {
                const [addr, x, y] = event.data.slice(9).split(",");
                Shared.grabAddr = addr;
                Shared.grabX = Number(x);
                Shared.grabY = Number(y);
                Shared.titleDrag = true;
                Shared.grabbed();
                return;
            }
            if (event.name === "custom" && event.data.startsWith("macdeskdrag>>")) {
                const [what, a, b, ...r] = event.data.slice(13).split(",");
                if (what === "open") {
                    Shared.deskDragAddr = a;
                    Shared.deskDragRect = [Number(b), ...r.map(Number)];
                    Shared.deskDragHow = "";
                    Shared.deskDragOpen = true;
                } else if (what === "pos") {
                    Shared.deskDragX = Number(a);
                    Shared.deskDragY = Number(b);
                } else {
                    Shared.deskDragHow = a ?? "cancel";
                    Shared.deskDragOpen = false;
                }
                return;
            }
            if (event.name === "custom" && event.data.startsWith("macsnap>>")) {
                const v = event.data.slice(9).split(",").map(Number);
                Shared.snapRect = v.length === 4 ? { x: v[0], y: v[1], w: v[2], h: v[3] } : null;
                return;
            }
            // errors inside Hyprland's Lua timers (drag / split code) are otherwise silent
            if (event.name === "custom" && event.data.startsWith("macerr>>")) {
                console.warn("hypr-qol:", event.data.slice(8));
                return;
            }
            if (event.name === "custom" && event.data.startsWith("macgame>>")) {
                Shared.gameMode = event.data.endsWith("1");
                return;
            }
            if (event.name === "custom" && event.data.startsWith("macwall>>")) {
                Shared.wallpaperReveal(Number(event.data.slice(9)) || 1000);
                return;
            }
            if (event.name !== "custom" || !event.data.startsWith("macdrag>>"))
                return;
            Shared.windowDrag = event.data.endsWith("1");
            if (!Shared.windowDrag)
                Shared.titleDrag = false;
            // title-bar drags: the hyprbars plugin swallows the mouse button, so
            // Hyprland's own binds never start/stop the drag tracking — do it here
            // (no-op if the binds already did, or if it isn't a title-bar drag)
            // over the socket (no process start): a fast drag mustn't outrun the tracking
            Hyprland.dispatch(`${Shared.windowDrag ? "mac_snap_drag_start(true)" : "mac_snap_drag_end()"} or hl.dsp.event("macack")`);
            if (Shared.windowDrag)
                dragSafety.restart();
        }
    }

    // Never leave the shield up if a release is ever missed
    Timer {
        id: dragSafety

        interval: 15000
        onTriggered: {
            Shared.windowDrag = false;
            Shared.titleDrag = false;
        }
    }

    Variants {
        model: Config.musicWidget ? Quickshell.screens : []
        MusicDrop {}
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Shared.toggleLauncher(); // guarded: a click that just closed it mustn't reopen it
        }

        // Open with a query pre-filled: qs -c macos ipc call launcher search firefox
        function search(text: string): void {
            Shared.launcherQuery = text;
            Shared.launcherOpen = true;
        }
    }

    // qs -c macos ipc call widgets edit | toggle
    IpcHandler {
        target: "widgets"

        function edit(): void {
            Shared.widgetEdit = !Shared.widgetEdit;
        }

        function toggle(): void {
            Config.setWidgets("enabled", !Config.widgetsEnabled);
        }

        // diagnostics: each stack card's layers (depth, y, scale, opacity)
        function layers(): string {
            return JSON.stringify(Shared.debugCards.filter(c => c.members.length > 1).map(c => c.debugState()));
        }

        // diagnostics: the colours the shell is drawing with right now
        function theme(): string {
            return JSON.stringify({ surface: String(Theme.surface), primary: String(Theme.primary), fg: String(Theme.fg), glassAlpha: Theme.panelAlpha });
        }

        // diagnostics: in-memory stack order (front first)
        function stacks(): string {
            const out = {};
            for (const w of [...Config.widgetItems].sort((a, b) => (a.order ?? 0) - (b.order ?? 0)))
                if (w.stack)
                    (out[w.stack] = out[w.stack] ?? []).push(w.type);
            return JSON.stringify(out);
        }

        // Edit Stack sheet for a stack key (see macos.json widgets.items[].stack)
        function editStack(key: string): void {
            Shared.editStackScreen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
            Shared.editStackKey = key;
        }

        // add to the focused display: qs -c macos ipc call widgets add notes medium
        function add(type: string, size: string): void {
            Shared.addWidget(type, size);
        }
    }

    IpcHandler {
        target: "music"

        function toggle(): void {
            Shared.musicPinned = !Shared.musicPinned;
        }
    }
}
