import QtQuick
import QtQuick.Controls
import Quickshell.Io

// Inline Wi-Fi network browser. Radio on/off is handled by the parent via the
// native Networking service; listing + connecting uses nmcli (reliable, and it
// reuses saved credentials for known networks).
Item {
    id: root
    property var colors
    property bool active: false   // panel visible — drives (re)scan

    implicitHeight: col.implicitHeight

    ListModel { id: nets }
    property string pwSsid: ""    // ssid whose inline connect/password row is open

    // SSIDs that already have a saved NetworkManager profile (password stored).
    property var knownSet: ({})

    // Triggers a real over-the-air rescan, shows cached results immediately,
    // then re-lists once the fresh scan lands (the empty-guard below covers the
    // mid-scan window). Runs automatically whenever the dropdown opens.
    function rescan() {
        known.running = false; known.running = true;
        otaRescan.running = false; otaRescan.running = true; // force OTA scan
        scan.running = false; scan.running = true;           // cached now
        relist.restart();                                    // fresh shortly after
    }
    onActiveChanged: if (active) rescan()
    Component.onCompleted: if (active) rescan()  // initial value won't fire onActiveChanged

    // `rescan` errors if called too soon after the last scan — harmless, ignored.
    Process { id: otaRescan; command: ["nmcli", "dev", "wifi", "rescan"] }
    Timer { id: relist; interval: 2200; onTriggered: { scan.running = false; scan.running = true; } }

    // Saved wifi connection profiles → knownSet (profile NAME is the SSID).
    Process {
        id: known
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var s = {};
                const lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    const p = lines[i].split("\\:").join(root.sentinel).split(":");
                    if ((p[1] || "").indexOf("wireless") >= 0) s[root.unesc(p[0])] = true;
                }
                root.knownSet = s;
            }
        }
    }
    function isKnown(ssid) { return !!root.knownSet[ssid]; }

    // nmcli -t escapes ':' inside a field as '\:'. Avoid regex lookbehind (the
    // QML V4 engine lacks it): swap escaped colons to a text sentinel, split on
    // ':', then restore.
    readonly property string sentinel: "ESCCOLON"
    function unesc(s) { return (s === undefined ? "" : s).split(sentinel).join(":"); }

    Process {
        id: scan
        running: true   // run once on creation (dialog is recreated each open)
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const rows = [];
                const lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;
                    const p = lines[i].split("\\:").join(root.sentinel).split(":");
                    const ssid = root.unesc(p[1]);
                    if (!ssid || seen[ssid]) continue;
                    seen[ssid] = true;
                    rows.push({
                        active: root.unesc(p[0]) === "yes",
                        ssid: ssid,
                        signal: parseInt(root.unesc(p[2])) || 0,
                        secured: root.unesc(p[3]).trim().length > 0
                    });
                }
                // NetworkManager returns an empty list while a scan is in
                // progress — keep the previous results and retry rather than
                // blanking the list.
                if (rows.length === 0) { retry.restart(); return; }
                nets.clear();
                for (var j = 0; j < rows.length; j++) nets.append(rows[j]);
            }
        }
    }
    Timer { id: retry; interval: 1500; onTriggered: { scan.running = false; scan.running = true; } }

    Process { id: connector }
    function connect(ssid, pw) {
        connector.command = pw && pw.length
            ? ["nmcli", "dev", "wifi", "connect", ssid, "password", pw]
            : ["nmcli", "dev", "wifi", "connect", ssid];
        connector.running = false;
        connector.running = true;
        root.pwSsid = "";
        rescanLater.restart();
    }
    Process { id: disconnector }
    function disconnectSsid(ssid) {
        disconnector.command = ["nmcli", "connection", "down", "id", ssid];
        disconnector.running = false; disconnector.running = true;
        rescanLater.restart();
    }
    Timer { id: rescanLater; interval: 2500; onTriggered: root.rescan() }

    function bars(sig) {
        if (sig >= 75) return "󰤨";
        if (sig >= 50) return "󰤥";
        if (sig >= 25) return "󰤢";
        if (sig > 0)   return "󰤟";
        return "󰤯";
    }

    Column {
        id: col
        width: parent.width
        spacing: 4

        Row {
            width: parent.width
            Text {
                text: "Networks"
                color: root.colors.outline
                font.pixelSize: 11
                width: parent.width - rescanBtn.width
                verticalAlignment: Text.AlignVCenter
                height: rescanBtn.height
            }
            Text {
                id: rescanBtn
                text: "󰑐 scan"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 11
                color: root.colors.primary
                MouseArea {
                    anchors.fill: parent; anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.rescan()
                }
            }
        }

        // Scrollable list capped in height.
        ListView {
            width: parent.width
            height: Math.min(contentHeight, 168)
            clip: true
            model: nets
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Column {
                id: netRow
                width: ListView.view.width
                // Network already has a saved profile → no password needed.
                readonly property bool known: !!root.knownSet[model.ssid]

                Rectangle {
                    width: parent.width
                    height: 30
                    color: ma.containsMouse ? root.colors.surfaceHigh : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.bars(model.signal)
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 14
                            color: model.active ? root.colors.primary : root.colors.fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70
                            text: model.ssid
                            color: model.active ? root.colors.primary : root.colors.fg
                            font.pixelSize: 12
                            font.bold: model.active
                            elide: Text.ElideRight
                        }
                        // Lock for secured networks; a check for saved ones.
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: model.secured
                            text: netRow.known ? "󰁦" : "󰌾"
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 11
                            color: root.colors.outline
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.active) { root.disconnectSsid(model.ssid); return; }
                            // Open: secured network → reveal connect/password row;
                            // open network → just connect.
                            if (model.secured) root.pwSsid = (root.pwSsid === model.ssid ? "" : model.ssid);
                            else root.connect(model.ssid, "");
                        }
                    }
                }

                // Inline row revealed on click for secured networks.
                Rectangle {
                    width: parent.width
                    height: visible ? 32 : 0
                    visible: root.pwSsid === model.ssid
                    color: root.colors.surface

                    // Saved network: just a Connect button (uses stored password).
                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        visible: netRow.known
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰌘 Connect"
                            font.family: "CaskaydiaMono Nerd Font"
                            color: root.colors.primary
                            font.pixelSize: 13
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.connect(model.ssid, "")
                            }
                        }
                    }

                    // New network: password field + connect.
                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6
                        visible: !netRow.known
                        TextField {
                            id: pwField
                            width: parent.width - 56
                            anchors.verticalCenter: parent.verticalCenter
                            echoMode: TextInput.Password
                            placeholderText: "password"
                            placeholderTextColor: root.colors.outline
                            color: root.colors.fg
                            font.pixelSize: 12
                            background: Rectangle { color: root.colors.background; radius: 0 }
                            onAccepted: root.connect(model.ssid, text)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "connect"
                            color: root.colors.primary
                            font.pixelSize: 12
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.connect(model.ssid, pwField.text)
                            }
                        }
                    }
                }
            }
        }
    }
}
