import QtQuick
import QtQuick.Controls
import Quickshell.Bluetooth

// Inline Bluetooth device list backed by the native Quickshell.Bluetooth
// service. Toggles scanning while open; click a device to connect/disconnect.
Item {
    id: root
    property var colors
    property bool active: false

    readonly property var adapter: Bluetooth.defaultAdapter

    implicitHeight: col.implicitHeight

    // Scan only while the dialog is open and the adapter is on.
    onActiveChanged: setDiscovery()
    Component.onCompleted: setDiscovery()  // initial value won't fire onActiveChanged
    function setDiscovery() {
        if (adapter) adapter.discovering = root.active && adapter.enabled;
    }

    Column {
        id: col
        width: parent.width
        spacing: 4

        Row {
            width: parent.width
            Text {
                text: "Devices"
                color: root.colors.outline
                font.pixelSize: 11
                width: parent.width - scanLbl.width
                verticalAlignment: Text.AlignVCenter
                height: scanLbl.height
            }
            Text {
                id: scanLbl
                text: (root.adapter && root.adapter.discovering) ? "󰂲 scanning…" : "󰂯 scan"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 11
                color: root.colors.primary
                MouseArea {
                    anchors.fill: parent; anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.adapter) root.adapter.discovering = !root.adapter.discovering
                }
            }
        }

        Text {
            visible: !root.adapter || !root.adapter.enabled
            text: "Bluetooth is off"
            color: root.colors.outline
            font.pixelSize: 12
        }

        ListView {
            width: parent.width
            height: Math.min(contentHeight, 168)
            visible: root.adapter && root.adapter.enabled
            clip: true
            model: Bluetooth.devices
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 30
                color: ma.containsMouse ? root.colors.surfaceHigh : "transparent"
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂰")
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 14
                        color: modelData.connected ? root.colors.primary : root.colors.fg
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        Text {
                            width: parent.width
                            text: modelData.name || modelData.deviceName || modelData.address
                            color: modelData.connected ? root.colors.primary : root.colors.fg
                            font.pixelSize: 12
                            font.bold: modelData.connected
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            visible: modelData.connected || modelData.pairing
                            text: modelData.pairing ? "pairing…"
                                  : (modelData.batteryAvailable ? "connected · " + Math.round(modelData.battery * 100) + "%"
                                                                 : "connected")
                            color: root.colors.outline
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.connected) modelData.disconnect();
                        else if (modelData.paired) modelData.connect();
                        else modelData.pair();
                    }
                }
            }
        }
    }
}
