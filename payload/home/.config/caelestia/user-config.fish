# Legibility overrides for the dynamic Caelestia terminal palette. Runs after
# ~/.local/state/caelestia/sequences.txt. The black/bright-black/blue slots come
# from the wallpaper scheme with a guaranteed minimum contrast, regenerated on
# every wallpaper/scheme change by ~/.local/bin/rice-term-colors (cli.json postHook).
if status is-interactive
    set -l legible ~/.local/state/caelestia/theme/term-legible.seq
    if test -f $legible
        cat $legible
    else # fallback: fixed values tuned for dark backgrounds
        printf '\e]4;0;#7b8a88\e\\'
        printf '\e]4;8;#a7b4b2\e\\'
        printf '\e]4;4;#82c4ff\e\\'
        printf '\e]4;12;#b0dcff\e\\'
    end
end

