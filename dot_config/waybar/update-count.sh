#!/bin/bash
pac=$(checkupdates 2>/dev/null | wc -l)
aur=$(yay -Qua 2>/dev/null | wc -l)
count=$((pac + aur))
[ "$count" -gt 0 ] && echo "$count" || exit 1
