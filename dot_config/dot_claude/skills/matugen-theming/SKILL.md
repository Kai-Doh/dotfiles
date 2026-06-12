---
name: matugen-theming
description: Use when the user mentions matugen, wants to regenerate/apply color themes, or asks to edit files under ~/.config/matugen (templates or config.toml).
---

## Golden rule: never call `matugen` directly

This system has a wrapper script, `wallpaper <path-to-image>` (at `~/.local/bin/wallpaper`), that must be used instead of running `matugen image ...` by hand. It does more than generate a palette:

- Runs matugen with the project's chosen flags (`--prefer saturation --type scheme-fidelity --lightness-dark 0.15`)
- Sets the wallpaper itself via `awww`
- Patches `hyprlock.conf` with the new wallpaper path, reapplies Hyprland border colors via `hyprctl`
- Sets the GTK theme/color-scheme, recolors nm-applet icons
- Reloads kitty, yazi, dunst, and tmux so every themed app picks up the new colors (the Quickshell bar/sidebar hot-reload themselves on `Colors.qml` change)

Calling `matugen` directly regenerates the palette but skips all of this — the desktop ends up half-themed. Always tell the user to run `wallpaper <image>`, or run it yourself if asked to apply/test a change. If no new image is given, reuse the path stored in `~/.config/hypr/.wallpaper`.

## Editing how a themed app looks

Matugen output files are generated — don't hand-edit them, the next `wallpaper` run overwrites them. Edit the source **template** instead, under `~/.config/matugen/templates/`. The mapping (from `~/.config/matugen/config.toml`) is:

| Template | Output |
|---|---|
| quickshell.qml | ~/.config/quickshell/Colors.qml |
| kitty.conf | ~/.config/kitty/colors.conf |
| rofi.rasi | ~/.config/rofi/colors.rasi |
| hyprland.lua | ~/.config/hypr/user/colors.lua |
| hyprlock.conf | ~/.config/hypr/hyprlock.conf |
| gtk3.css / gtk4.css | ~/.config/gtk-3.0/gtk.css / ~/.config/gtk-4.0/gtk.css |
| nvim_palette.lua | ~/.config/nvim/lua/matugen_palette.lua |
| yazi.toml | ~/.config/yazi/theme.toml |
| firefox.css | ~/.config/mozilla/firefox/.../theme-material-blue.css |
| dunst.conf | ~/.config/dunst/dunstrc |
| tmux.conf | ~/.cache/tmux/tmux_colors.conf |

To add theming for a new app: add a template file plus a `[templates.<name>]` entry in `config.toml`, then run `wallpaper <image>` to generate and apply it.

## Testing changes

After editing a template or `config.toml`, run `wallpaper <image>` to regenerate and apply — there's no lighter-weight preview path; this is the canonical way to test matugen changes here.

## Caveat

Firefox/Zen need a manual browser restart to pick up a regenerated `userChrome.css`/theme file — matugen + `wallpaper` won't refresh an already-running browser.
