hl.on("hyprland.start", function()
    -- XDG Desktop Portal
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Authentication Agent
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- cliphist & wl-clipboard
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- wallpaper
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("/home/kai/.local/bin/restore-wallpaper")

    -- Network status is shown natively in the quickshell bar (Network.qml),
    -- replacing the nm-applet tray icon.

    -- Claude sidebar (quickshell); toggle with Super+A
    hl.exec_cmd("qs")

    -- subtui in the special "magic" workspace
    hl.exec_cmd("kitty --title subtui -e subtui", { workspace = "special:magic silent" })

    -- cava below subtui (window rule handles workspace routing)
    hl.exec_cmd("sh -c 'sleep 1 && hyprctl dispatch focuswindow title:subtui && hyprctl dispatch layoutmsg \"preselect d\" && kitty --title cava -e cava'")

    -- once cava is open, set its split to 25% (briefly toggle workspace to apply)
    hl.exec_cmd("sh -c 'sleep 3 && hyprctl dispatch togglespecialworkspace magic && sleep 0.1 && hyprctl dispatch focuswindow title:cava && hyprctl dispatch splitratio exact 0.25 && hyprctl dispatch togglespecialworkspace magic'")
end)

-- (Status bar is now the Quickshell bar launched by `qs` above; it reads
-- Hyprland workspaces natively, so no manual refresh hooks are needed.)
