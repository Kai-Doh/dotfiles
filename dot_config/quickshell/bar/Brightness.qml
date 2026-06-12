import QtQuick
import Quickshell.Io

// Screen brightness via brightnessctl (no native backlight service in QS).
// Scroll to adjust, click for a slider popout. Replaces brightness-menu.sh.
Item {
    id: root
    property var colors
    property string device: "intel_backlight"
    property int pct: 50

    // Read current brightness percentage.
    Process {
        id: reader
        command: ["brightnessctl", "-m", "-d", root.device]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // format: device,class,current,NN%,max
                var parts = text.trim().split(",");
                if (parts.length >= 4) {
                    var p = parseInt(parts[3]);
                    if (!isNaN(p)) root.pct = p;
                }
            }
        }
    }
    function refresh() { reader.running = true; }

    Process { id: setter }
    function setPct(p) {
        p = Math.max(1, Math.min(100, Math.round(p)));
        root.pct = p;
        setter.command = ["brightnessctl", "-d", root.device, "set", p + "%"];
        setter.running = true;
    }

    readonly property var icons: ["󰃞", "󰃟", "󰃠"]
    function icon() { return icons[Math.min(2, Math.floor(pct / 34))]; }

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            text: root.icon()
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            color: root.colors.primary
        }
        Text {
            text: root.pct + "%"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            color: root.colors.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: pop.open = !pop.open
        onWheel: function (w) { root.setPct(root.pct + (w.angleDelta.y > 0 ? 5 : -5)); }
    }

    BarPopout {
        id: pop
        anchorItem: root
        colors: root.colors
        panelWidth: 240
        panelHeight: 78

        Column {
            anchors.fill: parent
            spacing: 10
            Row {
                width: parent.width
                Text {
                    text: "Brightness"
                    color: root.colors.fg
                    font.pixelSize: 13
                    width: parent.width - bval.width
                }
                Text {
                    id: bval
                    text: "󰃠 " + root.pct + "%"
                    font.family: "CaskaydiaMono Nerd Font"
                    color: root.colors.primary
                    font.pixelSize: 13
                }
            }
            BarSlider {
                width: parent.width
                colors: root.colors
                value: root.pct / 100
                onMoved: function (v) { root.setPct(v * 100); }
            }
        }
    }
}
