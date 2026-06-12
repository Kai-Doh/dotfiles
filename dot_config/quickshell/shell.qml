import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "bar"

// Entry point. Hosts:
//  - a top bar (one per monitor), replacing waybar
//  - a left-edge Claude sidebar overlay toggled via: qs ipc call sidebar toggle
ShellRoot {
    // Top bar on every screen.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    PanelWindow {
        id: panel
        visible: false

        // Anchor to the left edge, full height...
        anchors { left: true; top: true; bottom: true }
        implicitWidth: 440
        // ...but inset by the Hyprland gap (gaps_out = 10) so it floats like a window.
        margins { left: 10; top: 10; bottom: 10 }

        // Overlay: draw above windows, don't reserve screen space.
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:claude"
        // Grab the keyboard when the panel opens so you can type immediately.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        color: "transparent"

        // When the panel opens, drop the cursor straight into the active input.
        onVisibleChanged: if (visible) Qt.callLater(sidebar.focusActive)

        ChatSidebar {
            id: sidebar
            anchors.fill: parent
            onCloseRequested: panel.visible = false
        }
    }

    // Hyprland keybind calls into these.
    IpcHandler {
        target: "sidebar"
        function toggle(): void { panel.visible = !panel.visible; }
        function show(): void   { panel.visible = true; }
        function hide(): void   { panel.visible = false; }
    }
}
