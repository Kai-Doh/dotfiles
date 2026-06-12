import QtQuick
import Quickshell.Io

// Renders assistant text, splitting fenced ```code``` blocks into styled
// monospace panels with their own copy button. Prose renders as markdown.
Column {
    id: mc
    property var colors
    property string text: ""
    property color textColor: colors.fg
    spacing: 6

    readonly property var segments: parseSegments(text)

    function parseSegments(s) {
        var segs = [];
        var re = /```([^\n`]*)\n?([\s\S]*?)```/g;
        var last = 0, m;
        while ((m = re.exec(s)) !== null) {
            if (m.index > last)
                segs.push({ type: "text", content: s.substring(last, m.index) });
            segs.push({ type: "code", lang: m[1].trim(), content: m[2] });
            last = re.lastIndex;
        }
        if (last < s.length)
            segs.push({ type: "text", content: s.substring(last) });
        if (segs.length === 0)
            segs.push({ type: "text", content: s });
        return segs;
    }

    Process { id: copier; running: false }
    function copy(t) { copier.command = ["wl-copy", t]; copier.running = true; }

    Repeater {
        model: mc.segments

        delegate: Column {
            width: mc.width
            spacing: 0

            // --- prose ---
            TextEdit {
                visible: modelData.type === "text" && modelData.content.trim().length > 0
                width: parent.width
                text: modelData.content.trim()
                textFormat: TextEdit.MarkdownText
                color: mc.textColor
                font.pixelSize: 14
                wrapMode: TextEdit.Wrap
                readOnly: true
                selectByMouse: true
            }

            // --- code block ---
            Rectangle {
                visible: modelData.type === "code"
                width: parent.width
                implicitHeight: codeCol.implicitHeight
                color: mc.colors.background
                border.width: 1
                border.color: mc.colors.outline
                radius: 0

                Column {
                    id: codeCol
                    width: parent.width

                    Rectangle { // header: lang + copy
                        width: parent.width
                        height: 24
                        color: mc.colors.surface
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            text: modelData.lang.length > 0 ? modelData.lang : "code"
                            color: mc.colors.outline
                            font.pixelSize: 11
                            font.family: "CaskaydiaMono Nerd Font"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            text: "copy"
                            color: mc.colors.primary
                            font.pixelSize: 11
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mc.copy(modelData.content.replace(/\n$/, ""))
                            }
                        }
                    }

                    TextEdit {
                        width: parent.width
                        text: modelData.content.replace(/\n$/, "")
                        color: mc.textColor
                        font.family: "CaskaydiaMono Nerd Font"
                        font.pixelSize: 13
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                        leftPadding: 8; rightPadding: 8; topPadding: 6; bottomPadding: 8
                    }
                }
            }
        }
    }
}
