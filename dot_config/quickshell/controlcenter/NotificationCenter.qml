import QtQuick
import QtQuick.Controls

// The notification list shown inside the control center. Backed by NotifService.
Item {
    id: root
    property var colors
    property var svc            // NotifService

    property double now: Date.now()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

    function relTime(ms) {
        const d = Math.max(0, root.now - ms);
        const m = Math.floor(d / 60000);
        if (m < 1) return "now";
        if (m < 60) return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }

    readonly property int count: svc && svc.list ? svc.list.values.length : 0
    implicitHeight: header.height + 6 + listHolder.height

    // Header: count + DND chip + clear-all.
    Row {
        id: header
        width: parent.width
        height: 26
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰂚"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 14
            color: root.colors.primary
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 14 - clearLbl.width - 24
            text: root.count === 0 ? "No notifications"
                  : root.count + (root.count === 1 ? " notification" : " notifications")
            color: root.colors.fg
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
        }
        Text {
            id: clearLbl
            anchors.verticalCenter: parent.verticalCenter
            visible: root.count > 0
            text: "󰎟 clear"
            font.family: "CaskaydiaMono Nerd Font"
            font.pixelSize: 12
            color: root.colors.primary
            MouseArea {
                anchors.fill: parent; anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.svc.dismissAll()
            }
        }
    }

    Item {
        id: listHolder
        anchors { left: parent.left; right: parent.right; top: header.bottom; topMargin: 6 }
        height: root.count === 0 ? 0 : Math.min(list.contentHeight, 320)

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            spacing: 6
            model: root.svc ? root.svc.list : null
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: NotificationItem {
                required property var modelData
                width: ListView.view.width
                colors: root.colors
                notif: modelData
                timeText: root.relTime(root.svc.timeOf(modelData))
                onClosed: modelData.dismiss()
            }
        }
    }
}
