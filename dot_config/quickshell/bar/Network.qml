import QtQuick
import Quickshell.Io

// Network indicator (replaces the nm-applet tray icon). Shows an ethernet glyph
// when wired, otherwise a wifi glyph + the connected SSID; dim when offline.
// Updates reactively via `nmcli monitor`. Left-click opens the control center.
Item {
    id: root
    property var colors
    property string kind: "none"   // "ethernet" | "wifi" | "none"
    property string ssid: ""

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26

    // nmcli -t escapes ':' as '\:'; swap to a sentinel before splitting.
    readonly property string sentinel: "ESCCOLON"
    function unesc(s) { return (s === undefined ? "" : s).split(sentinel).join(":"); }

    function refresh() { status.running = false; status.running = true; }
    Component.onCompleted: refresh()

    Process {
        id: status
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }

    function parse(text) {
        var lines = text.trim().split("\n");
        var eth = null, wifi = null;
        for (var i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            var p = lines[i].split("\\:").join(root.sentinel).split(":");
            var type = root.unesc(p[0]);
            var state = root.unesc(p[1]);
            var conn = root.unesc(p[2]);
            if (state !== "connected") continue;          // exact: skips "connected (externally)"
            if (type === "ethernet" && eth === null) eth = conn;
            else if (type === "wifi" && wifi === null) wifi = conn;
        }
        if (eth !== null) { root.kind = "ethernet"; root.ssid = ""; }
        else if (wifi !== null) { root.kind = "wifi"; root.ssid = wifi; }
        else { root.kind = "none"; root.ssid = ""; }
    }

    // React to connect/disconnect without polling.
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: debounce.restart() }
    }
    Timer { id: debounce; interval: 700; onTriggered: root.refresh() }

    function icon() {
        if (kind === "ethernet") return "󰈀";
        if (kind === "wifi") return "󰖩";
        return "󰤭";
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon()
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 15
            color: root.kind === "none" ? root.colors.outline : root.colors.primary
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: text.length > 0
            text: root.kind === "ethernet" ? "Ethernet" : root.ssid
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 13
            color: root.colors.fg
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 140)
        }
    }

    Process { id: opener }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { opener.command = ["qs", "ipc", "call", "controlcenter", "toggle"]; opener.running = true; }
    }
}
