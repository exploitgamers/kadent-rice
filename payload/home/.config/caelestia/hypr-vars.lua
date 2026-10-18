-- Window defaults (macOS floating mode) must load before Caelestia's rules.lua
require("hypr-window-defaults")

local overrides = {}

-- WhiteSur cursors once installed (falls back to the default theme otherwise)
local f = io.open("/usr/share/icons/WhiteSur-cursors/index.theme")
if f then
    f:close()
    overrides.cursorTheme = "WhiteSur-cursors"
end

-- Three fingers are used to drag windows (macOS three-finger drag, see hypr-qol.lua),
-- so the special-workspace swipes move to four fingers (up/down) next to the
-- existing four-finger workspace swipe. The swipe-to-sleep gesture moves to five.
overrides.gestureFingers = 4
overrides.gestureFingersMore = 5

-- macOS window chrome: opaque windows, a faint hairline instead of a coloured
-- glow (depth comes from the shadow, as on macOS)
overrides.windowOpacity = 1.0
-- tinted from the wallpaper scheme's text colour, so the hairline stays subtle in
-- both dark and light mode (it was fixed white, invisible on light schemes)
local scheme = require("scheme.current")
overrides.activeWindowBorderColour = "rgba(" .. scheme.onSurface .. "2e)"
overrides.inactiveWindowBorderColour = "rgba(" .. scheme.onSurface .. "14)"

-- Soft, light shadow like macOS (Caelestia's 25 px at 55 % black read as a heavy dark band)
overrides.shadowRange = 18
overrides.shadowRenderPower = 2
overrides.shadowOffset = "0 3"
overrides.shadowColour = "rgba(00000040)"
overrides.shadowColourInactive = "rgba(0000001c)"

-- Smoother on the Iris Xe iGPU: 2 blur passes look almost identical to 3
overrides.blurPasses = 2
overrides.blurSize = 8

-- Volume keys change the volume 5 % at a time (Caelestia's default is 10); the bar's
-- scroll step is shell.json services.audioIncrement
overrides.volumeStep = 5

-- Tight gaps: more room for windows between the top bar and the dock
overrides.windowGapsOut = 4
overrides.windowGapsIn = 4

-- Shortcuts for this desktop's own features (bound with mac_bind in hypr-qol.lua and
-- hypr-user.lua), next to Caelestia's kb* ones from variables.lua
overrides.kbSpotlight = "SUPER + Space"
overrides.kbOverview = "SUPER + grave"
overrides.kbShowDesktop = "SUPER + F3"
overrides.kbGameMode = "SUPER + F1"
overrides.kbDesktopSettings = "SUPER + I"
-- macOS Cmd+M; off by default because SUPER + M is Caelestia's music desktop
overrides.kbMinimize = ""
-- macOS Cmd+H (Hide app) and Cmd+Alt+Esc (Force Quit Applications); "" turns one off
overrides.kbHide = "SUPER + H"
overrides.kbForceQuit = "SUPER + ALT + Escape"

-- Shortcuts changed in Desktop Settings → Keyboard (macos.json "keybinds":
-- { "kbName": "SUPER + X", … }; "" turns one off). Applied by a config reload.
do
    local f = io.open(os.getenv("HOME") .. "/.config/caelestia/macos.json")
    local text = f and f:read("*a") or ""
    if f then f:close() end
    local block = text:match('"keybinds"%s*:%s*(%b{})')
    if block then
        for name, combo in block:gmatch('"(kb%w+)"%s*:%s*"([^"]*)"') do
            overrides[name] = combo
        end
    end
end

return overrides
