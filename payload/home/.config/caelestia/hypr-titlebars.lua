-- macOS-style title bars on every window (hyprbars plugin, built locally for
-- Hyprland 0.56.2 into ~/.local/lib/hyprland/plugins; source in
-- ~/.local/opt/hyprbars-build). Rebuild it after Hyprland upgrades.
--   drag the bar        → move the window (tiled windows swap places)
--   double-click        → maximise / restore
--   ● ● ●  (left)       → close, minimise, zoom — glyphs appear on hover

-- IMPORTANT: never call hl.plugin.load() here. Loading a plugin triggers a
-- config reload, which would run this file again → endless reload loop that
-- freezes Hyprland. The plugin is loaded once at startup via `hyprctl plugin
-- load` (hypr-user.lua); this file only styles it when it's present.
if not hl.plugin.hyprbars then return end

local scheme = require("scheme.current")

hl.config({
    plugin = {
        hyprbars = {
            enabled                    = true,
            bar_height                 = mac_bar_height or 28, -- hypr-qol.lua
            -- Same colour as the window background (terminal bg = scheme background),
            -- so bar and content read as one surface like a macOS unified title bar
            bar_color                  = "rgb(" .. scheme.background .. ")",
            col = { text = "rgb(" .. scheme.onSurface .. ")" },
            bar_blur                   = true,
            bar_title_enabled          = true,
            bar_text_font              = "Inter",
            bar_text_size              = 10,
            bar_text_weight            = "medium",
            bar_text_align             = "center",
            bar_buttons_alignment      = "left",
            bar_part_of_window         = true,
            bar_precedence_over_border = true,
            bar_padding                = 12,
            bar_button_padding         = 7,
            icon_on_hover              = true,
            inactive_button_color      = "rgba(" .. scheme.onSurface .. "33)",
            on_double_click            = "hyprctl eval 'mac_zoom()'",
        },
    },
})

-- Traffic lights, left to right: close, minimise, zoom
local function light(bg, icon, action)
    hl.plugin.hyprbars.add_button({
        bg_color = bg,
        fg_color = "rgba(000000c0)", -- glyphs: dark and bold on hover (patched plugin)
        size     = 12,
        icon     = icon,
        action   = action,
    })
end

light("rgb(ff5f57)", "×", "hyprctl dispatch 'hl.dsp.window.close()'")
light("rgb(febc2e)", "−", "hyprctl eval 'mac_minimize()'")
-- Zoom, not Hyprland's maximise: any number of windows can be zoomed at once
-- (mac_zoom in hypr-qol.lua)
light("rgb(28c840)", "+", "hyprctl eval 'mac_zoom()'")

-- Every app gets this bar (working minimise + hover hints, uniform spacing).
-- Apps' own window buttons are hidden instead: GTK/Firefox follow
-- gsettings org.gnome.desktop.wm.preferences button-layout ':' and Firefox uses
-- the system title bar (browser.tabs.inTitlebar = 0 in its user.js).
