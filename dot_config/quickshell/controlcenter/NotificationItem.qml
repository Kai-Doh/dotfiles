import QtQuick
import Quickshell.Services.Notifications

// One notification card — shared by the sidebar list and the toast popups.
// Square corners + matugen. Shows app/image, summary, body, actions, close.
Rectangle {
    id: root
    property var colors
    property var notif          // Quickshell Notification
    property string timeText: ""

    signal closed()

    implicitHeight: body.implicitHeight + 16
    color: colors.surface
    border.width: notif && notif.urgency === NotificationUrgency.Critical ? 2 : 0
    border.color: colors.error
    radius: 0

    Column {
        id: body
        anchors {
            left: parent.left; right: parent.right; top: parent.top
            margins: 8
        }
        spacing: 4

        // Header: icon/image · app name · time · close
        Row {
            width: parent.width
            spacing: 8

            Item {
                width: 22; height: 22
                anchors.verticalCenter: undefined
                Image {
                    id: img
                    anchors.fill: parent
                    source: root.notif && root.notif.image ? root.notif.image : ""
                    visible: source != "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                }
                Text {
                    anchors.centerIn: parent
                    visible: !img.visible
                    text: "󰂚"
                    font.family: "CaskaydiaMono Nerd Font"
                    font.pixelSize: 15
                    color: root.colors.primary
                }
            }

            Text {
                width: parent.width - 22 - 8 - timeLbl.width - closeLbl.width - 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.notif ? (root.notif.appName || "Notification") : ""
                color: root.colors.primary
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                id: timeLbl
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeText
                color: root.colors.outline
                font.pixelSize: 10
            }
            Text {
                id: closeLbl
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅖"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 13
                color: root.colors.outline
                MouseArea {
                    anchors.fill: parent; anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closed()
                }
            }
        }

        Text {
            width: parent.width
            visible: text.length > 0
            text: root.notif ? root.notif.summary : ""
            color: root.colors.fg
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.notif ? root.notif.body : ""
            color: root.colors.fg
            font.pixelSize: 12
            textFormat: Text.MarkdownText
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        // Action buttons.
        Row {
            width: parent.width
            spacing: 6
            visible: root.notif && root.notif.actions && root.notif.actions.length > 0
            Repeater {
                model: root.notif ? root.notif.actions : []
                delegate: Rectangle {
                    required property var modelData
                    height: 24
                    width: actText.implicitWidth + 16
                    color: actMa.containsMouse ? root.colors.primary : root.colors.surfaceHigh
                    radius: 0
                    Text {
                        id: actText
                        anchors.centerIn: parent
                        text: modelData.text
                        color: actMa.containsMouse ? root.colors.primaryFg : root.colors.fg
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: actMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { modelData.invoke(); root.closed(); }
                    }
                }
            }
        }
    }
}
