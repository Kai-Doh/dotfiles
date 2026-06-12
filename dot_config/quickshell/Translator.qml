import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

// Translate tab: posts to Google's free gtx endpoint via curl. No API key.
Item {
    id: page
    property var colors
    signal closeRequested()

    property var langs: [
        { code: "auto", name: "Detect" },
        { code: "en", name: "English" },
        { code: "fr", name: "French" },
        { code: "de", name: "German" },
        { code: "es", name: "Spanish" },
        { code: "it", name: "Italian" },
        { code: "pt", name: "Portuguese" },
        { code: "nl", name: "Dutch" },
        { code: "ru", name: "Russian" },
        { code: "ja", name: "Japanese" },
        { code: "ko", name: "Korean" },
        { code: "zh-CN", name: "Chinese" },
        { code: "ar", name: "Arabic" }
    ]
    property int sourceIndex: 0   // Detect
    property int targetIndex: 1   // English
    property string output: ""
    property bool busy: false

    function focusInput() { input.forceActiveFocus(); }

    function translate() {
        var text = input.text;
        if (text.trim().length === 0) { page.output = ""; return; }
        page.busy = true;
        proc.command = ["curl", "-sG",
            "--data-urlencode", "q=" + text,
            "https://translate.googleapis.com/translate_a/single?client=gtx"
                + "&sl=" + page.langs[page.sourceIndex].code
                + "&tl=" + page.langs[page.targetIndex].code
                + "&dt=t"];
        proc.running = true;
    }

    function swap() {
        if (page.sourceIndex === 0) return; // can't put "Detect" as target
        var s = page.sourceIndex;
        page.sourceIndex = page.targetIndex;
        page.targetIndex = s;
        if (page.output.length > 0) { input.text = page.output; translate(); }
    }

    Process {
        id: proc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                page.busy = false;
                try {
                    var data = JSON.parse(text);
                    var out = "";
                    for (var i = 0; i < data[0].length; i++)
                        if (data[0][i][0]) out += data[0][i][0];
                    page.output = out;
                } catch (e) {
                    page.output = "⚠ translation failed";
                }
            }
        }
    }

    // Minimal styled language selector.
    component LangSelector: ComboBox {
        property var colors
        implicitHeight: 34
        font.pixelSize: 13
        background: Rectangle {
            color: colors.surface
            border.width: 1
            border.color: colors.outline
            radius: 0
        }
        contentItem: Text {
            text: parent.displayText
            color: colors.fg
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            LangSelector {
                id: srcBox
                colors: page.colors
                Layout.fillWidth: true
                model: page.langs.map(function (l) { return l.name; })
                currentIndex: page.sourceIndex
                onActivated: page.sourceIndex = currentIndex
            }
            Text {
                text: "⇄"
                color: page.colors.primary
                font.pixelSize: 18
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.swap()
                }
            }
            LangSelector {
                id: tgtBox
                colors: page.colors
                Layout.fillWidth: true
                model: page.langs.slice(1).map(function (l) { return l.name; })
                currentIndex: page.targetIndex - 1
                onActivated: page.targetIndex = currentIndex + 1
            }
        }

        // Input
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 0
            color: page.colors.surface
            border.width: 1
            border.color: page.colors.outline
            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                TextArea {
                    id: input
                    placeholderText: "Enter text…  (Enter to translate)"
                    placeholderTextColor: page.colors.outline
                    color: page.colors.fg
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 14
                    background: null
                    Keys.onPressed: function (event) {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && !(event.modifiers & Qt.ShiftModifier)) {
                            event.accepted = true;
                            page.translate();
                        } else if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            page.closeRequested();
                        }
                    }
                }
            }
        }

        // Output
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 0
            color: page.colors.surfaceHigh
            border.width: 1
            border.color: page.colors.outline
            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                TextArea {
                    text: page.busy ? "…" : page.output
                    color: page.colors.fg
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 14
                    readOnly: true
                    selectByMouse: true
                    background: null
                }
            }
        }
    }
}
