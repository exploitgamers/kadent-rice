local vars = require("variables")

hl.config({
    decoration = {
        rounding = vars.windowRounding,
        rounding_power = vars.windowRoundingPower,

        blur = {
            enabled           = vars.blurEnabled,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true, -- Allows opacity blurring
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            size              = vars.blurSize,
            passes            = vars.blurPasses,
            vibrancy          = vars.blurVibrancy,
            noise             = vars.blurNoise,
            contrast          = vars.blurContrast,
            brightness        = vars.blurBrightness,
        },

        shadow = {
            enabled        = vars.shadowEnabled,
            range          = vars.shadowRange,
            render_power   = vars.shadowRenderPower,
            offset         = vars.shadowOffset,
            color          = vars.shadowColour,
            color_inactive = vars.shadowColourInactive,
        },
    },
})
