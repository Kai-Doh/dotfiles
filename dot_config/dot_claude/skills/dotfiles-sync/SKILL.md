---
name: dotfiles-sync
description: Use when the user wants to sync, update, or push changes to their dotfiles repo after customizing their setup (new matugen templates, new app configs, new packages, install.sh changes, etc.).
---

## Context

Dotfiles are managed with **chezmoi**. The source repo is at `github.com/Kai-Doh/dotfiles` (public).

- Chezmoi's local source dir: `~/.local/share/chezmoi/`
- Applied configs live at their normal locations (`~/.config/`, `~/.bashrc`, etc.)
- Machine-specific values (monitor, backlight, timezone, Firefox profile) live in `~/.config/chezmoi/chezmoi.toml` — set once at install, never committed.

## What to do when syncing

### 1. Check what changed

```bash
chezmoi status
```

Output codes:
- `M` — file modified in `~/.config/` vs chezmoi source (user edited the applied file)
- `A` — new file added via `chezmoi add` but not yet committed
- nothing — already up to date, tell the user

To see the actual diff:
```bash
chezmoi diff
```

### 2. Re-sync applied changes back to source

If the user edited a config directly (e.g. `~/.config/waybar/style.css`), pull that change into the chezmoi source:
```bash
chezmoi re-add ~/.config/waybar/style.css
```
Or re-add everything that changed at once:
```bash
chezmoi re-add
```

### 3. Handle a new app config

If the user installed and configured a new app:
```bash
chezmoi add ~/.config/newapp
```
Chezmoi moves the dir into its source and manages it from that point on.

If the new app needs a package, add it to `packages.txt` manually:
```bash
echo "newpackage" >> ~/.local/share/chezmoi/packages.txt
```

### 4. Handle new matugen templates

If a new template was added to `~/.config/matugen/templates/`, re-add the templates dir:
```bash
chezmoi re-add ~/.config/matugen/templates/
```
Also re-add `~/.config/matugen/config.toml` if a new `[templates.xxx]` entry was added.

### 5. Commit and push

```bash
chezmoi cd   # enters ~/.local/share/chezmoi/
git add .
git commit -m "<descriptive message>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push
```

Good commit message examples:
- `add wezterm config and package`
- `add subtui theme template to matugen`
- `update waybar style`
- `add rofi-emoji plugin and config`

### Never commit

- `~/.config/chezmoi/chezmoi.toml` — machine-specific values, stays local
- `~/.config/subtui/credentials.toml` — plaintext password
- `~/.config/sunshine/credentials/` — private keys
- Browser profiles (mozilla, zen)
- App state (Notion, Obsidian, vesktop, dconf)

Chezmoi's `.chezmoiignore` handles most of this automatically.

## Updating from GitHub (pulling changes on this machine)

```bash
chezmoi update   # git pull + apply in one step
```

This is what `update-dot` runs.
