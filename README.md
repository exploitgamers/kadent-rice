# macOSxCaelestia

A macOS-style Hyprland desktop in one file: a top bar with floating pills, a permanent dock,
Spotlight, desktop widgets, Mission-Control-style Overview, title bars with traffic lights,
frosted glass. Built on Hyprland (Lua config), the Caelestia shell and Quickshell.

## Install (5-10 minutes)

Download `macOSxCaelestia.run` from the [latest release](https://github.com/exploitgamers/macOSxCaelestia/releases/latest), then:

```sh
chmod +x macOSxCaelestia.run
./macOSxCaelestia.run            # shows the plan, asks once
```

Then log out and pick **Hyprland** on the login screen. KDE Plasma stays the way it was, and
you can switch back to it at the login screen whenever you like.

| Option | What it does |
|---|---|
| `--yes` | don't ask |
| `--dry-run` | print every step, change nothing |
| `--uninstall` | remove the installed config files and put your old ones back (packages stay) |

**Requirements:** CachyOS (recommended) or Arch Linux, x86-64, a normal user with sudo,
an internet connection. On any other system the file offers to download the latest CachyOS ISO,
check its sha256 checksum and write it to a USB stick you choose. Install CachyOS with
**KDE Plasma**, then run the file again.

## What it changes

- `sudo pacman -Syu --needed …`: Hyprland, foot, fish, Firefox, Thunar, fonts (Inter,
  JetBrains Mono Nerd), PipeWire tools and the other packages the desktop uses. This also
  updates your system.
- `sudo pacman -U …`: AUR packages bundled inside the file, so nothing gets compiled (Caelestia shell
  and CLI, HyprMod, qtengine, Darkly, WhiteSur icons and cursors…).
- Your home folder: `~/.config/{hypr,caelestia,quickshell,foot,fish,fuzzel,gtk-3.0,gtk-4.0,nwg-look,Thunar,qtengine,btop}`,
  Thunar's `xfce4/xfconf/…/thunar.xml`, `~/.gtkrc-2.0`, `~/.config/starship.toml`, hidden menu entries for the
  settings apps Desktop Settings > More opens, the `rice-*` helpers in `~/.local/bin`, Quickshell in
  `~/.local/opt/quickshell-local`, the title-bar plugin in `~/.local/lib/hyprland/plugins`,
  a wallpaper in `~/Pictures/Wallpapers`, and a userChrome.css in Firefox's default-release profile.
- Before any of your files is replaced, it is copied to `~/.local/state/macOSxCaelestia-backup-<date>/`.
  Running it again keeps your edits to installed files in `macOSxCaelestia-replaced-<date>/`.
  `--uninstall` puts those copies back.

Nothing is changed system-wide: theme variables live in Hyprland's own config. Plasma does share a few of
the files above: the GTK theme (`~/.config/gtk-3.0`, `gtk-4.0`, `~/.gtkrc-2.0` and the `org.gnome.desktop.interface`
gsettings, so GTK apps in Plasma get the WhiteSur look too), Thunar's preferences and the fish, foot, starship and
btop configs. System Settings, the Thunar/AppImage/GTK settings apps and Background Services (uuctl) are hidden from
app menus, Plasma's included; they open from Desktop Settings > More. `--uninstall` puts your old ones back.

## After logging in

- `rice-doctor`: health check (Quickshell/Qt match, title-bar plugin, shells running).
- Super+Space opens Spotlight, Super+I opens Desktop Settings, and Super alone opens the app launcher.
- Weather uses your IP location. To set a city, put it in `widgets.weatherLocation` in `~/.config/caelestia/macos.json`.

## Updating

On another machine, the release `macOSxCaelestia.run` is still the installer: it carries the bundled packages,
so download the newest one and run it again (your edits to installed files are kept aside, see above).
This git repository is for history and diffs (`git log -p payload/` shows how the configs changed); it leaves
out `dist/` and the repacked packages in `payload/pkgs/`, so a clone alone can't install anything.

## Known limits

- **Qt drift:** Quickshell is a build for Qt 6.12. If your Qt is newer, the installer warns
  and switches to the repo `quickshell` when that one matches your Qt. Otherwise Quickshell
  needs to be rebuilt from source.
- **Hyprland drift:** the title-bar plugin only loads into the exact Hyprland it was built for. If yours
  differs, the installer rebuilds it (installs cmake/ninja, takes about a minute). If that build fails,
  windows have no title bars and everything else still works.
- **Python drift:** caelestia-cli and HyprMod were packed for Python 3.14.
- Repacked AUR packages carry the versions of the build date. Update them from the AUR later if you like.
