import QtQuick
import Quickshell

// A panel that drops below a bar module. Square corners, 2px primary border,
// matugen background — matches the sidebar styling. Toggle via `open`.
// Put content as children; they're laid into a 10px-margin body area.
PopupWindow {
    id: pop
    property Item anchorItem
    property var colors
    property int panelWidth: 260
    property int panelHeight: 130
    property bool open: false
    default property alias content: body.data

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: panelWidth
    implicitHeight: panelHeight
    visible: open
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: pop.colors.background
        border.width: 2
        border.color: pop.colors.primary
        radius: 0

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: 10
        }
    }
}
