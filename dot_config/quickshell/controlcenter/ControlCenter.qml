import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Networking
import Quickshell.Bluetooth
import "../"
import "../bar"

// Right-edge control center content. Square corners + matugen, matching the
// bar and Claude sidebar. Hosts: header (uptime + power), brightness/volume
// sliders, quick toggles (Wi-Fi / Bluetooth / DND) with inline dialogs, the
// notification list, and a calendar.
Rectangle {
    id: root
    property var notifs            // NotifService (from shell.qml)
    property string openDialog: "" // "", "wifi", "bluetooth"

    color: c.background
    border.width: 2
    border.color: c.primary
    radius: 0

    Colors { id: c }
    readonly property var colors: c

    // --- Fire-and-forget launcher (lock / power) -----------------------
    Process { id: launcher }
    function launch(cmd) { launcher.command = cmd; launcher.running = true; }

    // --- Uptime --------------------------------------------------------
    property string uptime: ""
    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.uptime = text.trim().replace(/^up /, "") }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: uptimeProc.running = true }

    // --- Brightness (brightnessctl) ------------------------------------
    property int bright: 50
    Process {
        id: brReader
        command: ["brightnessctl", "-m", "-d", "intel_backlight"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split(",");
                if (p.length >= 4) { var v = parseInt(p[3]); if (!isNaN(v)) root.bright = v; }
            }
        }
    }
    Process { id: brSetter }
    function setBright(p) {
        p = Math.max(1, Math.min(100, Math.round(p)));
        root.bright = p;
        brSetter.command = ["brightnessctl", "-d", "intel_backlight", "set", p + "%"];
        brSetter.running = true;
    }

    // --- Volume (Pipewire) ---------------------------------------------
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property bool sinkReady: sink && sink.audio
    function setVol(v) { if (sinkReady) sink.audio.volume = Math.max(0, Math.min(1.5, v)); }

    // --- Wi-Fi state (native toggle + nmcli for connected name) --------
    property string wifiSsid: ""
    Process {
        id: wifiName
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | head -1 | cut -d: -f2"]
        stdout: StdioCollector { onStreamFinished: root.wifiSsid = text.trim() }
    }
    function refreshWifi() { wifiName.running = false; wifiName.running = true; }
    Component.onCompleted: refreshWifi()

    // --- Bluetooth status helper ---------------------------------------
    readonly property var btAdapter: Bluetooth.defaultAdapter
    function btStatus() {
        if (!btAdapter || !btAdapter.enabled) return "Off";
        var ds = Bluetooth.devices ? Bluetooth.devices.values : [];
        for (var i = 0; i < ds.length; i++)
            if (ds[i].connected) return ds[i].name || ds[i].deviceName || "Connected";
        return "On";
    }

    // Calendar is pinned to the bottom; the rest scrolls above it.
    CcCalendar {
        id: cal
        anchors {
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 12; rightMargin: 12; bottomMargin: 14
        }
        colors: c
    }
    Rectangle {
        id: calSep
        anchors {
            left: parent.left; right: parent.right; bottom: cal.top
            leftMargin: 12; rightMargin: 12; bottomMargin: 10
        }
        height: 1
        color: c.surfaceHigh
    }

    Flickable {
        id: flick
        anchors {
            top: parent.top; left: parent.left; right: parent.right; bottom: calSep.top
            topMargin: 12; leftMargin: 12; rightMargin: 12; bottomMargin: 10
        }
        contentWidth: width
        contentHeight: colMain.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: colMain
            width: flick.width
            spacing: 12

            // --- Header: uptime + power buttons ------------------------
            Row {
                width: parent.width
                height: 30
                Column {
                    width: parent.width - hdrBtns.width
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "Control Center"
                        color: root.colors.primary
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        text: root.uptime.length ? "up " + root.uptime : ""
                        color: root.colors.outline
                        font.pixelSize: 11
                    }
                }
                Row {
                    id: hdrBtns
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    IconButton { colors: c; icon: "󰌾"; onClicked: root.launch(["hyprlock"]) }
                    IconButton { colors: c; icon: "󰐥"; onClicked: root.launch(["wlogout"]) }
                }
            }

            // --- Now playing -------------------------------------------
            MediaPlayer { width: parent.width; colors: c }

            // --- Brightness slider -------------------------------------
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        text: "Brightness"; color: root.colors.fg; font.pixelSize: 12
                        width: parent.width - brVal.width
                    }
                    Text { id: brVal; text: root.bright + "%"; color: root.colors.primary; font.pixelSize: 12 }
                }
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃟"; font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 16
                        color: root.colors.primary
                    }
                    BarSlider {
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                        colors: c
                        value: root.bright / 100
                        onMoved: function (v) { root.setBright(v * 100); }
                    }
                }
            }

            // --- Volume slider -----------------------------------------
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        text: "Volume"; color: root.colors.fg; font.pixelSize: 12
                        width: parent.width - volVal.width
                    }
                    Text {
                        id: volVal
                        text: root.sinkReady ? Math.round(root.sink.audio.volume * 100) + "%" : "—"
                        color: root.colors.primary; font.pixelSize: 12
                    }
                }
                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.sinkReady && root.sink.audio.muted) ? "󰝟" : "󰕾"
                        font.family: "CaskaydiaMono Nerd Font"; font.pixelSize: 16
                        color: root.colors.primary
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.sinkReady) root.sink.audio.muted = !root.sink.audio.muted
                        }
                    }
                    BarSlider {
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                        colors: c
                        value: root.sinkReady ? root.sink.audio.volume : 0
                        onMoved: function (v) { root.setVol(v); }
                    }
                }
            }

            // --- Quick toggles -----------------------------------------
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    spacing: 8
                    ToggleButton {
                        width: (parent.width - 8) / 2
                        colors: c
                        icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
                        label: "Wi-Fi"
                        status: Networking.wifiEnabled ? (root.wifiSsid.length ? root.wifiSsid : "On") : "Off"
                        toggled: Networking.wifiEnabled
                        expandable: true
                        dialogOpen: root.openDialog === "wifi"
                        onToggleClicked: { Networking.wifiEnabled = !Networking.wifiEnabled; root.refreshWifi(); }
                        onExpandClicked: root.openDialog = (root.openDialog === "wifi" ? "" : "wifi")
                    }
                    ToggleButton {
                        width: (parent.width - 8) / 2
                        colors: c
                        icon: (root.btAdapter && root.btAdapter.enabled) ? "󰂯" : "󰂲"
                        label: "Bluetooth"
                        status: root.btStatus()
                        toggled: root.btAdapter ? root.btAdapter.enabled : false
                        expandable: true
                        dialogOpen: root.openDialog === "bluetooth"
                        onToggleClicked: if (root.btAdapter) root.btAdapter.enabled = !root.btAdapter.enabled
                        onExpandClicked: root.openDialog = (root.openDialog === "bluetooth" ? "" : "bluetooth")
                    }
                }

                // Inline dialog area (Wi-Fi / Bluetooth).
                Loader {
                    width: parent.width
                    active: root.openDialog === "wifi"
                    visible: active
                    sourceComponent: WifiDialog { width: parent ? parent.width : 0; colors: c; active: true }
                }
                Loader {
                    width: parent.width
                    active: root.openDialog === "bluetooth"
                    visible: active
                    sourceComponent: BluetoothDialog { width: parent ? parent.width : 0; colors: c; active: true }
                }

                ToggleButton {
                    width: parent.width
                    colors: c
                    icon: root.notifs && root.notifs.dnd ? "󰂛" : "󰂚"
                    label: "Do Not Disturb"
                    status: root.notifs && root.notifs.dnd ? "Notifications silenced" : "Notifications on"
                    toggled: root.notifs ? root.notifs.dnd : false
                    onToggleClicked: if (root.notifs) root.notifs.dnd = !root.notifs.dnd
                }
            }

            Rectangle { width: parent.width; height: 1; color: root.colors.surfaceHigh }

            // --- Notifications -----------------------------------------
            NotificationCenter {
                width: parent.width
                colors: c
                svc: root.notifs
            }
        }
    }
}
