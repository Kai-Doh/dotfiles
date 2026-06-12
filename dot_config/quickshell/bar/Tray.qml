import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// System tray (StatusNotifier). Icons render from SNI; clicking opens the app's
// menu rendered by us (themed) via QsMenuOpener, so menu-driven applets like
// nm-applet work on a plain left-click. Right-click also opens the menu;
// middle-click is secondary activate.
//
// Left-click behaviour: if the item has a menu, show it (most tray applets are
// menu-driven); otherwise call activate(). The menu supports submenu descent
// (a QsMenuEntry is itself a menu handle) with a back row.
Row {
    id: root
    property var colors
    property var barWindow
    spacing: 8

    // Shared menu state.
    QsMenuOpener { id: opener }
    property var navStack: []          // handles for "back" navigation
    property Item activeCell: null

    function openMenuFor(cell, handle) {
        root.navStack = [];
        root.activeCell = cell;
        opener.menu = handle;
        menu.open = true;
    }
    function descend(entry) {
        root.navStack = root.navStack.concat([opener.menu]);
        opener.menu = entry;
    }
    function back() {
        if (root.navStack.length === 0) { menu.open = false; return; }
        var prev = root.navStack[root.navStack.length - 1];
        root.navStack = root.navStack.slice(0, -1);
        opener.menu = prev;
    }

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: cell
            required property var modelData
            width: 20
            height: 26

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: cell.modelData.icon
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function (m) {
                    // Toggle closed if this item's menu is already showing.
                    if (menu.open && root.activeCell === cell) { menu.open = false; return; }

                    if (m.button === Qt.MiddleButton) {
                        cell.modelData.secondaryActivate();
                    } else if (cell.modelData.hasMenu) {
                        root.openMenuFor(cell, cell.modelData.menu);
                    } else {
                        cell.modelData.activate();
                    }
                }
            }
        }
    }

    // --- Themed menu popout -------------------------------------------------
    readonly property int rowH: 28
    readonly property int entryCount: opener.children ? opener.children.values.length : 0

    BarPopout {
        id: menu
        anchorItem: root.activeCell
        colors: root.colors
        panelWidth: 240
        panelHeight: Math.min(440, 16 + (root.navStack.length > 0 ? root.rowH : 0)
                                       + root.entryCount * root.rowH)

        Column {
            anchors.fill: parent
            spacing: 0

            // Back row when inside a submenu.
            Rectangle {
                visible: root.navStack.length > 0
                width: parent.width
                height: root.rowH
                color: "transparent"
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Text { text: "󰅁"; font.family: "CaskaydiaMono Nerd Font"
                           font.pixelSize: 13; color: root.colors.primary }
                    Text { text: "Back"; font.pixelSize: 12; color: root.colors.primary }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.back() }
            }

            Repeater {
                model: opener.children

                delegate: Item {
                    id: entry
                    required property var modelData
                    width: parent ? parent.width : 0
                    height: modelData.isSeparator ? 7 : root.rowH

                    // Separator line.
                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: 1
                        color: root.colors.outline
                    }

                    // Normal entry.
                    Rectangle {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        color: hover.hovered ? root.colors.surfaceHigh : "transparent"

                        Row {
                            anchors {
                                left: parent.left; leftMargin: 6
                                right: parent.right; rightMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 6

                            // Check/radio indicator.
                            Text {
                                text: entry.modelData.checkState === Qt.Checked ? "󰄬" : ""
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 12
                                color: root.colors.primary
                                width: entry.modelData.checkState === Qt.Checked ? implicitWidth : 0
                            }
                            Text {
                                text: entry.modelData.text
                                font.pixelSize: 12
                                color: entry.modelData.enabled ? root.colors.fg : root.colors.outline
                                elide: Text.ElideRight
                                width: parent.width - (chev.visible ? chev.width + 6 : 0)
                                        - (entry.modelData.checkState === Qt.Checked ? 18 : 0)
                            }
                            // Submenu chevron.
                            Text {
                                id: chev
                                visible: entry.modelData.hasChildren
                                text: "󰅂"
                                font.family: "CaskaydiaMono Nerd Font"
                                font.pixelSize: 12
                                color: root.colors.outline
                            }
                        }

                        HoverHandler { id: hover }
                        MouseArea {
                            anchors.fill: parent
                            enabled: entry.modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (entry.modelData.hasChildren) {
                                    root.descend(entry.modelData);
                                } else {
                                    entry.modelData.triggered();
                                    menu.open = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
