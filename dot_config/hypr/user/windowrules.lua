-- Ignore maximize requests from all apps
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- pavucontrol popup
hl.window_rule({
    name  = "pavucontrol-popup",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
    size  = "600 400",
    move  = "100%-620 40",
    pin   = true,
})

-- hyprland-run floating terminal
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- keybind viewer popup (SUPER+K)
hl.window_rule({
    name        = "keybinds-viewer",
    match       = { class = "io.local.keybindsviewer" },
    float       = true,
    center      = true,
    size        = "740 500",
    decorate    = false,
    border_size = 0,
})

-- cava companion on special:magic
hl.window_rule({
    name      = "cava-special-magic",
    match     = { title = "^cava$" },
    workspace = "special:magic silent",
})
