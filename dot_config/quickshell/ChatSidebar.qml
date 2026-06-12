import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Sidebar container: a top tab bar (AI / Translate / Anime) over a stack of
// pages. Styled to match Hyprland: straight corners, matugen colors, 2px border.
Rectangle {
    id: root

    Colors { id: c }
    signal closeRequested()

    color: c.background
    radius: 0
    border.width: 2
    border.color: c.primary

    property int currentTab: 0
    readonly property var tabs: [
        { icon: "󰧑", label: "AI" },
        { icon: "󰗊", label: "Translate" },
        { icon: "󰋑", label: "Anime" }
    ]

    // Put the cursor straight into the active tab's input.
    function focusActive() {
        var item = stack.children[root.currentTab];
        if (item && item.focusInput)
            item.focusInput();
    }
    onCurrentTabChanged: Qt.callLater(focusActive)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // --- Tab bar ----------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.tabs
                delegate: Rectangle {
                    id: tabBtn
                    required property int index
                    required property var modelData
                    readonly property bool active: root.currentTab === index

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 0
                    color: active ? c.surfaceHigh : "transparent"
                    border.width: active ? 0 : 1
                    border.color: c.outline

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: tabBtn.modelData.icon
                            font.family: "CaskaydiaMono Nerd Font"
                            font.pixelSize: 16
                            color: tabBtn.active ? c.primary : c.outline
                        }
                        Text {
                            text: tabBtn.modelData.label
                            font.pixelSize: 13
                            font.bold: tabBtn.active
                            color: tabBtn.active ? c.fg : c.outline
                        }
                    }

                    Rectangle { // active underline
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 2
                        color: tabBtn.active ? c.primary : "transparent"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = tabBtn.index
                    }
                }
            }

            Rectangle { // close
                implicitWidth: 32; implicitHeight: 40
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"; color: c.outline; font.pixelSize: 15
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // --- Pages ------------------------------------------------------
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            AiChat     { colors: c; onCloseRequested: root.closeRequested() }
            Translator { colors: c; onCloseRequested: root.closeRequested() }
            Anime      { colors: c; onCloseRequested: root.closeRequested() }
        }
    }
}
