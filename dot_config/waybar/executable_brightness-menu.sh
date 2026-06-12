#!/bin/bash
# Themed brightness picker: hyprwat preset menu -> brightnessctl
# Left-click target for the waybar backlight module.

# Current brightness percent (e.g. "53")
cur=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
cur=${cur:-100}

levels=(10 25 50 75 100)

# Mark the preset nearest the current level as preselected (trailing '*')
nearest=100
best=999
for l in "${levels[@]}"; do
    diff=$(( cur > l ? cur - l : l - cur ))
    if (( diff < best )); then best=$diff; nearest=$l; fi
done

items=()
for l in "${levels[@]}"; do
    label="${l}:${l}%"
    [ "$l" -eq "$nearest" ] && label="${label}*"
    items+=("$label")
done

sel=$(hyprwat "${items[@]}")
[ -n "$sel" ] && brightnessctl set "${sel}%"
