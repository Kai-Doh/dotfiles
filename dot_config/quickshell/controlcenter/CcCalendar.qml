import QtQuick
import Quickshell

// Month grid calendar (today highlighted). Lifted from the bar clock popout.
Item {
    id: root
    property var colors
    implicitHeight: col.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property var now: clock.date
    readonly property int year: now.getFullYear()
    readonly property int month: now.getMonth()
    readonly property int today: now.getDate()
    readonly property int firstDow: new Date(year, month, 1).getDay()
    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    // Cells scale to fill the panel width across 7 columns.
    readonly property real cellW: Math.max(28, Math.floor((width - 6 * 3) / 7))
    readonly property real cellH: 34

    Column {
        id: col
        width: parent.width
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "MMMM yyyy")
            color: root.colors.primary
            font.pixelSize: 17
            font.bold: true
        }

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 7
            rowSpacing: 3
            columnSpacing: 3

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Item {
                    width: root.cellW; height: 24
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: root.colors.outline
                        font.pixelSize: 12
                        font.family: "CaskaydiaMono Nerd Font"
                    }
                }
            }
            Repeater {
                model: root.firstDow
                delegate: Item { width: root.cellW; height: root.cellH }
            }
            Repeater {
                model: root.daysInMonth
                delegate: Rectangle {
                    required property int index
                    readonly property int day: index + 1
                    readonly property bool isToday: day === root.today
                    width: root.cellW; height: root.cellH
                    radius: 0
                    color: isToday ? root.colors.primary : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: parent.day
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 14
                        color: parent.isToday ? root.colors.primaryFg : root.colors.fg
                    }
                }
            }
        }
    }
}
