#!/bin/bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

# ── 1. Install packages ────────────────────────────────────────────────────────
echo "==> Installing packages..."
if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm - < "$DOTFILES/packages.txt"
elif command -v pacman &>/dev/null; then
    echo "WARNING: yay not found — falling back to pacman (AUR packages will be skipped)"
    grep -v '^#' "$DOTFILES/packages.txt" | pacman -S --needed --noconfirm - 2>/dev/null || true
else
    echo "WARNING: No package manager found. Install packages manually from packages.txt"
fi

# Verify critical commands
MISSING=()
for cmd in hyprctl matugen waybar kitty tmux nvim rofi dunst swww playerctl brightnessctl; do
    command -v "$cmd" &>/dev/null || MISSING+=("$cmd")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "WARNING: Missing commands after install: ${MISSING[*]}"
    echo "         Some features may not work. Install them manually and re-run."
fi

# ── 2. Collect machine-specific values ────────────────────────────────────────
echo ""
echo "==> Machine configuration"
echo "    (Press Enter to accept defaults)"
echo ""

read -rp "  Monitor name for hyprpaper [eDP-1]: " MONITOR
MONITOR="${MONITOR:-eDP-1}"

read -rp "  Backlight device (ls /sys/class/backlight/) [intel_backlight]: " BACKLIGHT
BACKLIGHT="${BACKLIGHT:-intel_backlight}"

read -rp "  Timezone [Europe/Zurich]: " TIMEZONE
TIMEZONE="${TIMEZONE:-Europe/Zurich}"

# Auto-detect Firefox profile
FIREFOX_PROFILE=$(ls -d "$HOME"/.mozilla/firefox/*.default-release 2>/dev/null \
    | head -1 | xargs basename 2>/dev/null || true)
if [[ -z "$FIREFOX_PROFILE" ]]; then
    read -rp "  Firefox profile dir name (e.g. ae74tywg.default-release): " FIREFOX_PROFILE
else
    echo "  Firefox profile detected: $FIREFOX_PROFILE"
fi

# ── 3. Symlink helper ─────────────────────────────────────────────────────────
link_file() {
    local src="$DOTFILES/$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mkdir -p "$BACKUP"
        mv "$dst" "$BACKUP/"
        echo "  backed up: $dst"
    fi
    ln -sf "$src" "$dst"
}

# ── 4. Symlink configs ────────────────────────────────────────────────────────
echo ""
echo "==> Symlinking configs..."

link_file "home/.bashrc"                     "$HOME/.bashrc"
link_file "home/.bash_profile"               "$HOME/.bash_profile"
link_file "config/autostart"                 "$HOME/.config/autostart"
link_file "config/cava"                      "$HOME/.config/cava"
link_file "config/dunst"                     "$HOME/.config/dunst"
link_file "config/git"                       "$HOME/.config/git"
link_file "config/hypr"                      "$HOME/.config/hypr"
link_file "config/keybinds-viewer"           "$HOME/.config/keybinds-viewer"
link_file "config/kitty"                     "$HOME/.config/kitty"
link_file "config/matugen"                   "$HOME/.config/matugen"
link_file "config/mimeapps.list"             "$HOME/.config/mimeapps.list"
link_file "config/mpv"                       "$HOME/.config/mpv"
link_file "config/networkmanager-dmenu"      "$HOME/.config/networkmanager-dmenu"
link_file "config/nvim"                      "$HOME/.config/nvim"
link_file "config/rofi"                      "$HOME/.config/rofi"
link_file "config/subtui/config.toml"        "$HOME/.config/subtui/config.toml"
link_file "config/systemd/user"              "$HOME/.config/systemd/user"
link_file "config/tmux/tmux.conf"            "$HOME/.config/tmux/tmux.conf"
link_file "config/waybar"                    "$HOME/.config/waybar"
link_file "config/yazi"                      "$HOME/.config/yazi"

mkdir -p "$HOME/.local/bin"
for s in wallpaper restore-wallpaper tmux-safe-save tmux-validate-save; do
    link_file "local/bin/$s" "$HOME/.local/bin/$s"
    chmod +x "$DOTFILES/local/bin/$s"
done

# ── 5. Generate hyprpaper.conf from template ──────────────────────────────────
echo "==> Generating hyprpaper.conf..."
sed \
    -e "s|__HOME__|$HOME|g" \
    -e "s|__MONITOR__|$MONITOR|g" \
    "$DOTFILES/config/hypr/hyprpaper.conf.template" \
    > "$HOME/.config/hypr/hyprpaper.conf"

# ── 6. Patch machine-specific values into symlinked files ─────────────────────
echo "==> Patching machine-specific values..."

# Firefox profile in matugen config (patches repo file via symlink)
if [[ -n "$FIREFOX_PROFILE" ]]; then
    sed -i "s|__FIREFOX_PROFILE__|$FIREFOX_PROFILE|g" \
        "$HOME/.config/matugen/config.toml"
fi

# Waybar backlight and timezone
sed -i "s|intel_backlight|$BACKLIGHT|g" \
    "$HOME/.config/waybar/config.jsonc"
sed -i "s|Europe/Zurich|$TIMEZONE|g" \
    "$HOME/.config/waybar/config.jsonc"

# ── 7. Bootstrap tmux plugin manager ─────────────────────────────────────────
TPM="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM" ]]; then
    echo "==> Cloning tpm..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
fi
mkdir -p "$HOME/.cache/tmux"

# ── 8. Subtui credentials ─────────────────────────────────────────────────────
CREDS="$HOME/.config/subtui/credentials.toml"
if [[ ! -f "$CREDS" ]]; then
    mkdir -p "$HOME/.config/subtui"
    cp "$DOTFILES/config/subtui/credentials.toml.example" "$CREDS"
    echo "==> Created $CREDS — edit it with your Navidrome credentials."
fi

# ── 9. Enable systemd user services ──────────────────────────────────────────
echo "==> Enabling systemd user services..."
systemctl --user daemon-reload
systemctl --user enable --now waybar.service tmux.service

# ── 10. First wallpaper run ───────────────────────────────────────────────────
DEFAULT_WALL="$HOME/Pictures/Wallpapers/nebula.jpg"
if [[ -f "$DEFAULT_WALL" ]]; then
    echo "==> Running wallpaper to generate initial color theme..."
    "$HOME/.local/bin/wallpaper" "$DEFAULT_WALL"
else
    echo ""
    echo "NOTE: Put a wallpaper image at $DEFAULT_WALL"
    echo "      then run:  wallpaper <path-to-image>"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ Done! Next steps:"
echo "  1. Log into Hyprland"
echo "  2. Run:  nvim +Lazy sync        (install neovim plugins)"
echo "  3. Run:  tmux  then prefix+I    (install tmux plugins)"
[[ ! -f "$CREDS" ]] || grep -q "your_password" "$CREDS" && \
    echo "  4. Edit: ~/.config/subtui/credentials.toml"
