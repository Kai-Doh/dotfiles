import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

// Top bar — one per monitor (instantiated by Variants in shell.qml).
// Flush to the top edge, full width, 2px bottom border: matches the old waybar.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    exclusiveZone: 30
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    color: "transparent"

    Colors { id: c }

    // Fire-and-forget launcher for lock / power.
    Process { id: launcher }
    function launch(cmd) { launcher.command = cmd; launcher.running = true; }

    Rectangle {
        anchors.fill: parent
        color: c.background
        opacity: 0.85
    }
    // Bottom border drawn separately so it stays opaque over the 0.85 bg.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 2
        color: c.surfaceHigh
    }

    // --- Left: workspaces ----------------------------------------------
    Workspaces {
        id: workspaces
        colors: c
        monitorName: bar.screen ? bar.screen.name : ""
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
    }

    // --- Center: clock -------------------------------------------------
    Clock {
        colors: c
        anchors.centerIn: parent
    }

    // --- Right: modules (filled in incrementally) ----------------------
    Row {
        id: right
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 8

        Music { colors: c }
        Volume { colors: c }
        Brightness { colors: c }
        Battery { colors: c }
        Updates { colors: c }
        Tray { colors: c; barWindow: bar }
        IconButton { colors: c; icon: "󰌾"; onClicked: bar.launch(["hyprlock"]) }
        IconButton { colors: c; icon: "󰐥"; onClicked: bar.launch(["wlogout"]) }
    }
}
