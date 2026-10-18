-- Apple-style Caelestia:
--   Caelestia's own panels, restyled in ~/.config/caelestia/shell.json
--   bottom → macOS-style app dock + Now Playing drop-down (~/.config/quickshell/macos)
--   windows → macOS title bars (hypr-titlebars.lua)

local function exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end

-- Locally built Quickshell (~/.local/bin/qs) must win over any system copy;
-- Caelestia's `caelestia shell` also resolves `qs` through PATH.
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/bin"))

-- Flatpak apps (e.g. Sober) must be findable by the dock, launcher and Caelestia:
-- add Flatpak's exported .desktop dirs to the app search path for everything
-- Hyprland starts (Flatpak's own /etc/profile.d script isn't sourced by this session).

hl.env("XDG_DATA_DIRS", os.getenv("HOME") .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:"
    .. (os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"))

hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 1 && qs -c macos -d")
    hl.exec_cmd("rice-usb-notify") -- USB/SD drive notifications (udev events, no polling)
    -- Title bars plugin: loaded once from outside the config (see hypr-titlebars.lua)
    hl.exec_cmd("hyprctl plugin load " .. os.getenv("HOME") .. "/.local/lib/hyprland/plugins/libhyprbars.so")

    if exists("/usr/share/icons/WhiteSur-dark/index.theme") then
        hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme WhiteSur-dark")
    end
    if exists("/usr/share/fonts/inter/InterVariable.ttf") or exists(os.getenv("HOME") .. "/.local/share/fonts/inter/InterVariable.ttf") then
        hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Inter 10.5'")
    end
end)

-- Frosted glass behind the dock and Now Playing card.
-- The docks animate themselves with springs, so Hyprland's layer anims are off.
-- Not macos-widgets: Hyprland's blur on that bottom layer bled through the title
-- bars of windows above it. The widgets draw their own frosted glass instead.
hl.layer_rule({ match = { namespace = "macos-(dock|music|launcher|gallery|winmenu-anchor)" }, blur = true, blur_popups = true, ignore_alpha = 0.2, no_anim = true })
-- Overview: its dim is a constant alpha and Hyprland fades the whole layer, so the
-- blur fades with it (a QML-faded dim switched the blur on/off in one frame at ignore_alpha).
hl.layer_rule({ match = { namespace = "macos-overview" }, blur = true, ignore_alpha = 0.2, animation = "fade" })

-- Multi-monitor, gaming and video-editing tweaks
require("hypr-qol")
require("hypr-window-memory") -- apps reopen at their last size and place




-- Frosted glass behind Caelestia's panels (only where they are opaque enough)
hl.layer_rule({ match = { namespace = "caelestia-drawers" }, blur = true, blur_popups = true, ignore_alpha = 0.3 })

-- SUPER+Space opens Spotlight: search apps, windows, files, actions, maths, web
-- (was fuzzel in keybinds.lua). Tapping SUPER alone still opens the Apps launcher.
hl.unbind("SUPER + Space") -- Caelestia's fuzzel launcher
mac_bind(require("variables").kbSpotlight, hl.dsp.exec_cmd("qs -c macos ipc call spotlight toggle"))

-- macOS title bars (drag to move, traffic-light buttons)
require("hypr-titlebars")

-- macOS window motion: windows zoom in from ~90 % while fading in, and shrink a
-- little while fading out — not slide (Caelestia's animations.lua; later wins).
-- Speeds are in tenths of a second. Desktop switching keeps its slide.
-- Caelestia's "macOS" curve ({0.25,1},{0.5,1}) covers ~90 % in the first fifth, then
-- hangs: snap-then-crawl. An ease-out cubic decelerates evenly instead.
hl.curve("macOS", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.2, bezier = "macOS", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.2, bezier = "macExit", style = "popin 92%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.6, bezier = "macOS" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.0, bezier = "macExit" })
