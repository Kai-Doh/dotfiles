import QtQuick
import Quickshell

// Center clock. Left-click drops a calendar popout; right-click toggles the
// date/time format inline.
Item {
    id: root
    property var colors
    implicitWidth: label.implicitWidth + 16
    implicitHeight: 26
    property bool showDate: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.showDate
              ? "󰃭 " + Qt.formatDateTime(clock.date, "dd/MM/yyyy")
              : "󰃭 " + Qt.formatDateTime(clock.date, "ddd dd  HH:mm")
        font.family: "CaskaydiaMono Nerd Font"
        font.pixelSize: 15
        color: root.colors.primary
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (m) {
            if (m.button === Qt.RightButton) root.showDate = !root.showDate;
            else cal.open = !cal.open;
        }
    }

    BarPopout {
        id: cal
        anchorItem: root
        colors: root.colors
        panelWidth: 248
        panelHeight: 230

        // Build a month grid from the current date.
        readonly property var now: clock.date
        readonly property int year: now.getFullYear()
        readonly property int month: now.getMonth()
        readonly property int today: now.getDate()
        readonly property int firstDow: new Date(year, month, 1).getDay() // 0=Sun
        readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

        Column {
            anchors.fill: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(cal.now, "MMMM yyyy")
                color: root.colors.primary
                font.pixelSize: 14
                font.bold: true
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                // Weekday headers (Mon-first to match locale habits here).
                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    delegate: Item {
                        width: 30; height: 22
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.colors.outline
                            font.pixelSize: 11
                            font.family: "CaskaydiaMono Nerd Font"
                        }
                    }
                }

                // Leading blanks before the 1st.
                Repeater {
                    model: cal.firstDow
                    delegate: Item { width: 30; height: 24 }
                }

                // Day cells.
                Repeater {
                    model: cal.daysInMonth
                    delegate: Rectangle {
                        required property int index
                        readonly property int day: index + 1
                        readonly property bool isToday: day === cal.today
                        width: 30; height: 24
                        radius: 0
                        color: isToday ? root.colors.primary : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.day
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 12
                            color: parent.isToday ? root.colors.primaryFg : root.colors.fg
                        }
                    }
                }
            }
        }
    }
}
