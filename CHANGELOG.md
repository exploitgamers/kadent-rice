# Changelog

What changed in each release of the installer, newest first. Every release is named after the day
it was published (`vYYYY.MM.DD`) and can be downloaded from the GitHub releases page.

## Unreleased

## v2026.10.19

- First public release: one file that installs the whole macOS-style desktop (Hyprland, the Caelestia
  top bar, the dock, launcher, Spotlight, widgets and title bars with traffic lights) on a fresh
  CachyOS + KDE Plasma system in 5-10 minutes. Plasma stays as it was and remains available at the login screen.
- One-command install: paste a single `curl … && bash …` line into a terminal (see the README).
- The README now has screenshots of the desktop.
- Releases publish automatically: the installer is rebuilt and uploaded whenever the desktop or its
  packages change, so the download link always gives you the current version.
- The project is now called **macOSxCaelestia**, and so is the installer: download and run
  `macOSxCaelestia.run` (the one-command install in the README uses the new name).
- The installer keeps its notes and backups in `~/.local/state/macOSxCaelestia*` folders, matching the new name.
- Each release now comes with this changelog; its notes on GitHub show what changed.

<!-- auto: rewritten on every publish -->
- Built for Hyprland 0.56.2-4.1, Qt 6.12.0 and Python 3.14.
