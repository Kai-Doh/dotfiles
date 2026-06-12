#!/bin/bash
# Clickable workspace buttons for waybar under Lua-configured Hyprland.
# Native hyprland/workspaces clicks send "dispatch workspace N", which this
# Hyprland evaluates as Lua and rejects. So we render one custom button per
# workspace and switch via the Lua dispatcher instead.
#
#   workspaces.sh status <N>   -> JSON for button N (hidden when empty)
#   workspaces.sh go <N>       -> focus workspace N, refresh the bar

cmd="$1"
n="$2"

case "$cmd" in
    go)
        hyprctl dispatch "hl.dsp.focus({workspace=$n})" >/dev/null 2>&1
        pkill -RTMIN+10 waybar
        ;;
    status)
        active=$(hyprctl activeworkspace 2>/dev/null | head -1 | grep -oP 'workspace ID \K-?[0-9]+')
        existing=$(hyprctl workspaces 2>/dev/null | grep -oP 'workspace ID \K-?[0-9]+')
        if [ "$n" = "$active" ]; then
            printf '{"text":"%s","class":"active"}\n' "$n"
        elif grep -qx "$n" <<<"$existing"; then
            printf '{"text":"%s","class":"occupied"}\n' "$n"
        else
            printf '{"text":""}\n'
        fi
        ;;
esac
