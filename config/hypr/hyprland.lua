-- Hyprland main config (Lua)
-- Split into system/ and user/ for easier management

-- SYSTEM
require("system.monitors")
require("system.environment")
require("system.input")

-- USER
require("user.programs")
require("user.autostart")
require("user.colors")
require("user.theme")
require("user.keybindings")
require("user.windowrules")
