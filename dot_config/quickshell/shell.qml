import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "bar"
import "controlcenter"

// Entry point. Hosts:
//  - a top bar (one per monitor), replacing waybar
//  - a left-edge Claude sidebar overlay toggled via: qs ipc call sidebar toggle
//  - a right-edge control center toggled via: qs ipc call controlcenter toggle
//  - the system notification server + on-screen toasts (replacing dunst)
ShellRoot {
    // Shared notification backend (server + DND state) for the control center
    // list and the on-screen toasts. Suppress toasts while the control center
    // is open — the notification already shows in its list there.
    NotifService { id: notifs; suppressPopups: ccPanel.visible }

    // Top bar on every screen.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // On-screen notification toasts (dunst replacement).
    NotificationPopups { notifs: notifs }

    PanelWindow {
        id: panel
        visible: false

        // Anchor to the left edge, full height...
        anchors { left: true; top: true; bottom: true }
        // Width = content (440) + 2×16 shadow inset.
        implicitWidth: 472
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

        OverlayShadow {
            anchors.fill: parent
            ChatSidebar {
                id: sidebar
                anchors.fill: parent
                onCloseRequested: panel.visible = false
            }
        }
    }

    // Right-edge control center: quick toggles, sliders, notifications, calendar.
    PanelWindow {
        id: ccPanel
        visible: false

        anchors { right: true; top: true; bottom: true }
        // Width = content (400) + 2×16 shadow inset.
        implicitWidth: 432
        margins { right: 10; top: 10; bottom: 10 }

        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:controlcenter"
        // On-demand: don't hijack the keyboard on open; the Wi-Fi password
        // field grabs focus when clicked.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        color: "transparent"

        OverlayShadow {
            anchors.fill: parent
            ControlCenter {
                anchors.fill: parent
                notifs: notifs
            }
        }
    }

    // Hyprland keybind calls into these.
    IpcHandler {
        target: "sidebar"
        function toggle(): void { panel.visible = !panel.visible; }
        function show(): void   { panel.visible = true; }
        function hide(): void   { panel.visible = false; }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { ccPanel.visible = !ccPanel.visible; }
        function hide(): void   { ccPanel.visible = false; }
    }
}
