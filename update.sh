#!/bin/bash
set -euo pipefail

# Pull latest changes from GitHub and re-apply dotfiles
chezmoi update --source ~/dotfiles

# Reload live services if inside Hyprland
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    systemctl --user daemon-reload
    systemctl --user restart waybar.service 2>/dev/null || true
fi

echo "✓ Dotfiles updated."
