import QtQuick

// Minimal square-cornered slider matching the matugen theme.
// Drag or click anywhere on the track; emits moved(value) with 0..1.
Item {
    id: s
    property var colors
    property real value: 0
    signal moved(real v)
    implicitHeight: 18

    Rectangle {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 6
        radius: 0
        color: s.colors.surfaceHigh

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, s.value))
            height: parent.height
            radius: 0
            color: s.colors.primary
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function pick(x) { s.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: function (m) { pick(m.x); }
        onPositionChanged: function (m) { if (ma.pressed) pick(m.x); }
    }
}
