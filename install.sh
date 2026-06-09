#!/bin/bash
set -euo pipefail

REPO="https://github.com/Kai-Doh/dotfiles.git"
DOTFILES="$HOME/dotfiles"

# ── 1. Install chezmoi ────────────────────────────────────────────────────────
if ! command -v chezmoi &>/dev/null; then
    echo "==> Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# ── 2. Clone repo if not already present ─────────────────────────────────────
if [[ ! -d "$DOTFILES/.git" ]]; then
    echo "==> Cloning dotfiles..."
    git clone "$REPO" "$DOTFILES"
fi

# ── 3. Install packages ───────────────────────────────────────────────────────
echo "==> Installing packages..."
if command -v yay &>/dev/null; then
    grep -v '^#' "$DOTFILES/packages.txt" | grep -v '^$' | \
        yay -S --needed --noconfirm -
elif command -v pacman &>/dev/null; then
    echo "WARNING: yay not found — falling back to pacman (AUR packages skipped)"
    grep -v '^#' "$DOTFILES/packages.txt" | grep -v '^$' | \
        sudo pacman -S --needed --noconfirm - 2>/dev/null || true
else
    echo "WARNING: No package manager found. Install packages manually from packages.txt"
fi

# Verify critical commands
MISSING=()
for cmd in hyprctl matugen waybar kitty tmux nvim rofi dunst awww playerctl brightnessctl; do
    command -v "$cmd" &>/dev/null || MISSING+=("$cmd")
done
[[ ${#MISSING[@]} -gt 0 ]] && \
    echo "WARNING: Missing after install: ${MISSING[*]}"

# ── 4. Apply dotfiles via chezmoi ─────────────────────────────────────────────
# Prompts for monitor, backlight, timezone, Firefox profile (once — saved to
# ~/.config/chezmoi/chezmoi.toml for future runs)
echo "==> Applying dotfiles..."
chezmoi init --apply --source "$DOTFILES"

# ── 5. Bootstrap tpm ─────────────────────────────────────────────────────────
TPM="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM" ]]; then
    echo "==> Cloning tpm..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
fi
mkdir -p "$HOME/.cache/tmux"

# ── 6. Subtui credentials ─────────────────────────────────────────────────────
CREDS="$HOME/.config/subtui/credentials.toml"
if [[ ! -f "$CREDS" ]]; then
    mkdir -p "$HOME/.config/subtui"
    cp "$HOME/.config/subtui/credentials.toml.example" "$CREDS"
    echo "==> Created $CREDS — edit it with your Navidrome credentials."
fi

# ── 7. Systemd user services ──────────────────────────────────────────────────
echo "==> Enabling systemd user services..."
systemctl --user daemon-reload
systemctl --user enable --now waybar.service tmux.service

# ── 8. First wallpaper run ────────────────────────────────────────────────────
WALL="$HOME/Pictures/Wallpapers/nebula.jpg"
if [[ -f "$WALL" ]]; then
    echo "==> Generating initial color theme..."
    wallpaper "$WALL"
else
    echo "NOTE: Add a wallpaper at $WALL then run: wallpaper <path>"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ Done! Next steps:"
echo "  1. Log into Hyprland"
echo "  2. nvim +Lazy sync        — install neovim plugins"
echo "  3. tmux → prefix+I        — install tmux plugins"
grep -q "your_password" "$CREDS" 2>/dev/null && \
    echo "  4. Edit ~/.config/subtui/credentials.toml"
