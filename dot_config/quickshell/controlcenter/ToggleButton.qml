import QtQuick

// A quick-settings toggle pill: icon tile on the left, label + status on the
// right. Square-cornered + matugen, matching the bar/sidebar. When `toggled`
// the whole tile fills with the primary colour.
//
// Click the icon tile  -> toggleClicked()  (flip the radio/state)
// Click the body/chevron (expandable only) -> expandClicked() (open a dialog)
// Non-expandable tiles toggle from anywhere.
Item {
    id: root
    property var colors
    property string icon: ""
    property string label: ""
    property string status: ""
    property bool toggled: false
    property bool expandable: false
    property bool dialogOpen: false

    signal toggleClicked()
    signal expandClicked()

    implicitHeight: 52

    readonly property color bg: toggled ? colors.primary : colors.surfaceHigh
    readonly property color fgCol: toggled ? colors.primaryFg : colors.fg
    readonly property color dim: toggled ? colors.primaryFg : colors.outline

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.bg

        Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 10
            spacing: 10

            // Icon tile — clicking it always performs the main toggle.
            Item {
                width: 36
                height: parent.height
                Rectangle {
                    anchors.centerIn: parent
                    width: 36; height: 36
                    radius: 0
                    color: root.toggled ? root.colors.primaryFg : root.colors.surface
                    Text {
                        anchors.centerIn: parent
                        text: root.icon
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 18
                        color: root.toggled ? root.colors.primary : root.colors.primary
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleClicked()
                }
            }

            // Label + status.
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 36 - (root.expandable ? 24 : 0) - 20
                spacing: 0
                Text {
                    width: parent.width
                    text: root.label
                    color: root.fgCol
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: root.status.length > 0
                    text: root.status
                    color: root.dim
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            // Chevron for expandable tiles.
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.expandable
                text: root.dialogOpen ? "󰅃" : "󰅀"
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 16
                color: root.dim
            }
        }

        // Body click: opens the dialog for expandable tiles, otherwise toggles.
        // (The icon tile's own MouseArea sits above this and wins on the left.)
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandable ? root.expandClicked() : root.toggleClicked()
            z: -1
        }
    }
}
