import QtQuick

// A clickable Nerd Font glyph sized for the bar.
Item {
    id: b
    property var colors
    property string icon: ""
    property color iconColor: colors ? colors.primary : "white"
    property int size: 15
    signal clicked()

    implicitWidth: t.implicitWidth + 12
    implicitHeight: 26

    Text {
        id: t
        anchors.centerIn: parent
        text: b.icon
        font.family: "CaskaydiaMono Nerd Font"
        font.pixelSize: b.size
        color: b.iconColor
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
