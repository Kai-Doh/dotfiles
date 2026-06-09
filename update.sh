#!/bin/bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOCAL="$HOME/.dotfiles.local"

# ── Load machine-specific values saved by install.sh ─────────────────────────
if [[ ! -f "$LOCAL" ]]; then
    echo "ERROR: ~/.dotfiles.local not found — run ./install.sh first."
    exit 1
fi
source "$LOCAL"

# ── Pull latest changes ───────────────────────────────────────────────────────
echo "==> Pulling latest dotfiles..."
cd "$DOTFILES"
git pull

# ── Re-link everything (ln -sf is idempotent; picks up new dirs too) ──────────
echo "==> Re-linking configs..."

link_file() {
    local src="$DOTFILES/$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
}

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

# ── Re-generate hyprpaper.conf from template ─────────────────────────────────
echo "==> Regenerating hyprpaper.conf..."
sed \
    -e "s|__HOME__|$HOME|g" \
    -e "s|__MONITOR__|$MONITOR|g" \
    "$DOTFILES/config/hypr/hyprpaper.conf.template" \
    > "$HOME/.config/hypr/hyprpaper.conf"

# ── Reload live services if running under Hyprland ───────────────────────────
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "==> Reloading services..."
    systemctl --user daemon-reload
    systemctl --user restart waybar.service 2>/dev/null || true
fi

echo ""
echo "✓ Dotfiles updated."
