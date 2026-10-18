hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves (macOS-style: quick start, long soft settle)
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("macEase", { type = "bezier", points = { { 0.32, 0.72 }, { 0, 1 } } })
hl.curve("macExit", { type = "bezier", points = { { 0.4, 0 }, { 0.9, 0.4 } } })
hl.curve("macOS", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "macOS", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "macExit", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 4, bezier = "macOS" })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "macOS", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "macExit", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5.5, bezier = "macOS" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macOS", style = "slide" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 4,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "macOS" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 5, bezier = "macOS" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "macEase" })
