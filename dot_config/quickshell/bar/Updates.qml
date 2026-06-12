import QtQuick
import Quickshell.Io

// Pending update count (pacman + AUR). Refreshes hourly; click opens a terminal
// running the upgrade, then refreshes. Hidden when there are no updates.
Item {
    id: root
    property var colors
    property int count: 0

    Process {
        id: checker
        command: ["bash", "-c",
            "echo $(( $(checkupdates 2>/dev/null | wc -l) + $(yay -Qua 2>/dev/null | wc -l) ))"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt(text.trim());
                root.count = isNaN(n) ? 0 : n;
            }
        }
    }
    function refresh() { checker.running = true; }

    Timer { interval: 3600000; running: true; repeat: true; onTriggered: root.refresh() }

    Process { id: upgrader }

    visible: count > 0
    implicitWidth: visible ? row.implicitWidth + 12 : 0
    implicitHeight: 26

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            text: "󰚰"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            color: root.colors.primary
        }
        Text {
            text: root.count
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            color: root.colors.fg
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            upgrader.command = ["kitty", "-e", "bash", "-c", "yay -Syu; read -p 'Done. Press enter…'"];
            upgrader.running = true;
        }
    }
}
