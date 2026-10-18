-- macOS window mode: new windows open floating, centred, at 62% × 70% of the
-- screen — decided by a window rule, so the window appears directly in its final
-- spot. (The old window.open hook floated windows *after* they had been tiled, so
-- every launch reshuffled the layout and then jumped — the awkward open animation.)
--
-- Loaded from hypr-vars.lua, i.e. BEFORE Caelestia's rules.lua: for static rule
-- effects the later rule wins, so Caelestia's own per-app rules (float_60_70 etc.)
-- still override this default. Toggled live from the dock's right-click menu via
-- `hyprctl eval 'mac_set_floating(true|false)'`; stored in macos.json.

local settings_path = os.getenv("HOME") .. "/.config/caelestia/macos.json"

local function floating_from_settings()
    local f = io.open(settings_path)
    if not f then return true end
    local text = f:read("*a")
    f:close()
    return text:match('"floating"%s*:%s*false') == nil
end

local not_games = "negative:^(steam_app_.*|steam_app_default|gamescope)$"

mac_float_rule = hl.window_rule({
    name   = "mac-float-default",
    match  = { class = not_games },
    float  = true,
})

-- Centred, except XWayland windows Hyprland already guessed floating (`float` is its guess,
-- made before rules apply): X11 menus, tooltips and dialogs are all windows there, and the
-- app puts them itself (at the pointer, over their parent) — centring opened right-click menus
-- mid-screen. Caelestia's own centre rule skips XWayland too. X11 main windows still centre.
mac_center_rule = hl.window_rule({
    name   = "mac-center-default",
    match  = { class = not_games, xwayland = false },
    center = true,
})
mac_center_x11_rule = hl.window_rule({
    name   = "mac-center-x11-main",
    match  = { class = not_games, xwayland = true, float = false },
    center = true,
})

-- The 62% × 70% size only for normal top-level windows. `float = false` is matched
-- against Hyprland's own guess, made before any rule applies: dialogs, pop-ups,
-- transient/child windows and fixed-size windows already float, so they keep the
-- size the app asks for (Resolve's pickers opened near full-screen before).
mac_size_rule = hl.window_rule({
    name   = "mac-size-default",
    match  = { class = not_games, float = false, modal = false },
    size   = "(monitor_w*0.62) (monitor_h*0.7)",
})

function mac_set_floating(on)
    mac_float_rule:set_enabled(on and true or false)
    mac_center_rule:set_enabled(on and true or false)
    mac_center_x11_rule:set_enabled(on and true or false)
    mac_size_rule:set_enabled(on and true or false)
end

mac_set_floating(floating_from_settings())
