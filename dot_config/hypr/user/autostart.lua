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

    -- (cava now runs as the desktop background visualizer via quickshell —
    -- see ~/.config/quickshell/Visualizer.qml — so it no longer lives here.)
end)

-- (Status bar is now the Quickshell bar launched by `qs` above; it reads
-- Hyprland workspaces natively, so no manual refresh hooks are needed.)
