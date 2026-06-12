import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

// Native Hyprland workspaces — replaces the 10 custom/ws shell-script buttons.
// Shows existing workspaces on this bar's monitor, highlights the active one,
// click to switch, scroll over the row to move between them.
RowLayout {
    id: root
    property var colors
    property string monitorName: ""
    spacing: 2

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: ws
            required property var modelData
            // Hide special/scratchpad workspaces (negative id); only show
            // workspaces belonging to this monitor (guard nulls).
            visible: modelData.id > 0
                     && (root.monitorName.length === 0
                         || !modelData.monitor
                         || modelData.monitor.name === root.monitorName)
            readonly property bool active: modelData.active

            implicitWidth: visible ? Math.max(28, label.implicitWidth + 16) : 0
            implicitHeight: 26
            color: active ? root.colors.surfaceHigh : "transparent"
            radius: 0

            Text {
                id: label
                anchors.centerIn: parent
                text: ws.modelData.name
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 15
                font.bold: ws.active
                color: root.colors.primary
            }

            // active underline
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 2
                color: ws.active ? root.colors.primary : "transparent"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + ws.modelData.id)
            }
        }
    }

    // Scroll anywhere on the row to cycle workspaces.
    WheelHandler {
        onWheel: function (e) {
            Hyprland.dispatch(e.angleDelta.y < 0 ? "workspace e+1" : "workspace e-1");
        }
    }
}
