hl.config({
    input = {
        kb_layout     = "us",
        kb_variant    = "",
        kb_model      = "",
        kb_options    = "",
        kb_rules      = "",
        follow_mouse  = 1,
        sensitivity   = 0,
        accel_profile = "custom 200 0 0.15 0.42 0.70 0.90 1.0",
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({ name = "epic-mouse-v1",         sensitivity    = -0.5 })
hl.device({ name = "tpps/2-ibm-trackpoint", accel_profile  = "adaptive", sensitivity = -0.3 })
hl.device({ name = "synaptics-tm3625-010",  accel_profile  = "adaptive", sensitivity = 0.3 })
