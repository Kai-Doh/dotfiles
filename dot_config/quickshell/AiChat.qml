import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

// AI tab: Claude chat driven by the claude CLI (Claude Code) via ClaudeService.
Item {
    id: page
    property var colors
    signal closeRequested()

    ClaudeService { id: claude }

    function focusInput() { input.forceActiveFocus(); }

    Process { id: copier; running: false }
    function copyText(t) { copier.command = ["wl-copy", t]; copier.running = true; }

    readonly property var commands: [
        { name: "/clear",  desc: "Start a new conversation" },
        { name: "/model",  desc: "Switch model: opus | sonnet | haiku" },
        { name: "/chat",   desc: "Plain chat — no file/system access (default)" },
        { name: "/agent",  desc: "Claude Code — full tools & file access" },
        { name: "/help",   desc: "Show available commands" }
    ]

    function setMode(chat) {
        claude.chatMode = chat;
        claude.reset();
        claude.addSystem(chat ? "Chat mode — no file or system access"
                              : "Agent mode — Claude Code with full tools");
    }

    function sendCurrent() {
        var raw = input.text;
        if (raw.trim().length === 0 || claude.busy)
            return;
        if (raw.trim().startsWith("/")) {
            handleCommand(raw.trim());
            input.clear();
            return;
        }
        claude.send(raw);
        input.clear();
    }

    function handleCommand(cmd) {
        var parts = cmd.slice(1).split(/\s+/);
        var name = parts[0], arg = parts[1];
        if (name === "clear") {
            claude.reset();
        } else if (name === "model") {
            if (["opus", "sonnet", "haiku"].indexOf(arg) >= 0) {
                claude.model = arg;
                claude.addSystem("Model set to " + arg);
            } else {
                claude.addSystem("Usage: /model opus | sonnet | haiku");
            }
        } else if (name === "chat") {
            page.setMode(true);
        } else if (name === "agent") {
            page.setMode(false);
        } else if (name === "help") {
            claude.addSystem("Commands:  /clear   /model opus|sonnet|haiku   /chat   /agent   /help");
        } else {
            claude.addSystem("Unknown command: /" + name);
        }
    }

    function cycleModel() {
        var order = ["opus", "sonnet", "haiku"];
        claude.model = order[(order.indexOf(claude.model) + 1) % order.length];
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // --- Action row -------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: claude.sessionId.length > 0 ? "Claude · session active" : "Claude"
                color: page.colors.outline
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Text {
                text: "＋ New chat"
                color: page.colors.outline
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: claude.reset()
                }
            }
        }

        // --- Messages ---------------------------------------------------
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: claude.messages
            spacing: 8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: positionViewAtEnd()
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Item {
                id: del
                width: list.width
                implicitHeight: col.implicitHeight
                readonly property bool isLast: index === list.count - 1
                readonly property bool isUser: model.role === "user"
                readonly property bool isSystem: model.role === "system"

                Column {
                    id: col
                    width: parent.width
                    spacing: 3

                    // system notice
                    Text {
                        visible: del.isSystem
                        width: parent.width
                        text: model.text
                        horizontalAlignment: Text.AlignHCenter
                        color: page.colors.outline
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }

                    // user / assistant bubble
                    Item {
                        visible: !del.isSystem
                        width: parent.width
                        implicitHeight: bubble.height

                        Rectangle {
                            id: bubble
                            width: del.isUser
                                   ? Math.min(parent.width * 0.92, userText.implicitWidth + 22)
                                   : parent.width * 0.97
                            height: (del.isUser ? userText.implicitHeight
                                                : asstContent.implicitHeight) + 18
                            radius: 0
                            color: del.isUser ? page.colors.primary : page.colors.surfaceHigh
                            anchors.right: del.isUser ? parent.right : undefined
                            anchors.left: del.isUser ? undefined : parent.left

                            TextEdit {
                                id: userText
                                visible: del.isUser
                                anchors { fill: parent; margins: 9 }
                                text: model.text
                                color: page.colors.primaryFg
                                font.pixelSize: 14
                                wrapMode: TextEdit.Wrap
                                readOnly: true
                                selectByMouse: true
                            }

                            MessageContent {
                                id: asstContent
                                visible: !del.isUser
                                anchors { left: parent.left; right: parent.right;
                                          top: parent.top; margins: 9 }
                                colors: page.colors
                                text: model.text.length > 0
                                      ? model.text
                                      : (model.streaming ? "…" : "")
                            }
                        }
                    }

                    // hover actions
                    Row {
                        visible: !del.isSystem && delHover.hovered && model.text.length > 0
                        spacing: 10
                        anchors.right: del.isUser ? parent.right : undefined

                        Text {
                            text: "copy"
                            color: page.colors.outline
                            font.pixelSize: 11
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.copyText(model.text)
                            }
                        }
                        Text {
                            visible: !del.isUser && del.isLast && !claude.busy
                            text: "regenerate"
                            color: page.colors.outline
                            font.pixelSize: 11
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: claude.regenerate()
                            }
                        }
                    }
                }

                HoverHandler { id: delHover }
            }
        }

        // --- Slash command hints ---------------------------------------
        Column {
            Layout.fillWidth: true
            spacing: 2
            visible: input.text.startsWith("/")
            Repeater {
                model: page.commands.filter(function (cmd) {
                    return cmd.name.startsWith(input.text.split(/\s+/)[0]);
                })
                delegate: Rectangle {
                    width: parent.width
                    height: 26
                    color: page.colors.surface
                    border.width: 1; border.color: page.colors.outline
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        spacing: 8
                        Text { text: modelData.name; color: page.colors.primary; font.pixelSize: 12 }
                        Text { text: modelData.desc; color: page.colors.outline; font.pixelSize: 11 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            input.text = modelData.name + " ";
                            input.cursorPosition = input.text.length;
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // --- Input ------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            radius: 0
            color: page.colors.surface
            border.width: 1
            border.color: page.colors.outline
            implicitHeight: Math.min(120, Math.max(44, input.implicitHeight + 16))

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                TextArea {
                    id: input
                    placeholderText: claude.busy ? "Claude is thinking…"
                                                 : "Message Claude…  (\"/\" for commands)"
                    placeholderTextColor: page.colors.outline
                    color: page.colors.fg
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 14
                    background: null
                    enabled: !claude.busy

                    Keys.onPressed: function (event) {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && !(event.modifiers & Qt.ShiftModifier)) {
                            event.accepted = true;
                            page.sendCurrent();
                        } else if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            page.closeRequested();
                        }
                    }
                }
            }
        }

        // --- Bottom bar: model chip + commands hint --------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle { // mode toggle
                implicitHeight: 26
                implicitWidth: modeText.implicitWidth + 20
                color: claude.chatMode ? page.colors.surface : page.colors.primary
                border.width: 1; border.color: page.colors.outline
                Text {
                    id: modeText
                    anchors.centerIn: parent
                    text: claude.chatMode ? "󰍢 Chat" : "󰚩 Agent"
                    font.family: "CaskaydiaMono Nerd Font"
                    color: claude.chatMode ? page.colors.fg : page.colors.primaryFg
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.setMode(!claude.chatMode)
                }
            }

            Rectangle { // model
                implicitHeight: 26
                implicitWidth: modelText.implicitWidth + 20
                color: page.colors.surface
                border.width: 1; border.color: page.colors.outline
                Text {
                    id: modelText
                    anchors.centerIn: parent
                    text: "✦ " + claude.model
                    color: page.colors.fg
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.cycleModel()
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "\"/\" for commands"
                color: page.colors.outline
                font.pixelSize: 11
            }
        }
    }
}
