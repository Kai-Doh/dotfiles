import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

// Anime tab: a booru image browser. Queries Moebooru-style JSON APIs
// (yande.re / konachan) via curl, shows a thumbnail grid, opens full images
// in the default viewer. Tag search + page number + NSFW toggle.
Item {
    id: page
    property var colors
    signal closeRequested()

    property var providers: [
        { name: "yande.re",  url: "https://yande.re/post.json" },
        { name: "konachan",  url: "https://konachan.com/post.json" }
    ]
    property int providerIndex: 0
    property bool allowNsfw: false
    property int pageNum: 1
    property var posts: []
    property bool busy: false
    property string lastTags: ""

    function focusInput() { tagInput.forceActiveFocus(); }

    function search(rawText) {
        var text = rawText.trim();
        var parts = text.length > 0 ? text.split(/\s+/) : [];
        var tags = [];
        page.pageNum = 1;
        for (var i = 0; i < parts.length; i++) {
            if (/^\d+$/.test(parts[i])) page.pageNum = parseInt(parts[i]);
            else tags.push(parts[i]);
        }
        page.lastTags = tags.join(" ");
        runRequest();
    }

    function nextPage() {
        page.pageNum += 1;
        runRequest();
    }

    function runRequest() {
        page.busy = true;
        var tagStr = page.lastTags;
        if (!page.allowNsfw) tagStr += " rating:s";
        proc.command = ["curl", "-s", "-G",
            "--data-urlencode", "tags=" + tagStr.trim(),
            "--data-urlencode", "limit=30",
            "--data-urlencode", "page=" + page.pageNum,
            page.providers[page.providerIndex].url];
        proc.running = true;
    }

    Process {
        id: proc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                page.busy = false;
                try {
                    var arr = JSON.parse(text);
                    page.posts = (page.pageNum > 1) ? page.posts.concat(arr) : arr;
                } catch (e) {
                    page.posts = [];
                }
            }
        }
    }

    Process { id: opener; running: false }
    function openImage(url) {
        opener.command = ["xdg-open", url];
        opener.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // --- Controls ---------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle { // provider switch
                implicitHeight: 30
                implicitWidth: provText.implicitWidth + 18
                color: page.colors.surface
                border.width: 1; border.color: page.colors.outline
                Text {
                    id: provText
                    anchors.centerIn: parent
                    text: page.providers[page.providerIndex].name
                    color: page.colors.fg
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        page.providerIndex = (page.providerIndex + 1) % page.providers.length;
                        if (page.lastTags.length > 0) page.search(page.lastTags);
                    }
                }
            }

            Rectangle { // nsfw toggle
                implicitHeight: 30
                implicitWidth: nsfwText.implicitWidth + 18
                color: page.allowNsfw ? page.colors.primary : page.colors.surface
                border.width: 1; border.color: page.colors.outline
                Text {
                    id: nsfwText
                    anchors.centerIn: parent
                    text: page.allowNsfw ? "NSFW on" : "NSFW off"
                    color: page.allowNsfw ? page.colors.primaryFg : page.colors.outline
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        page.allowNsfw = !page.allowNsfw;
                        if (page.lastTags.length > 0 || page.posts.length > 0) page.search(page.lastTags);
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: page.posts.length > 0
                text: page.posts.length + " · p" + page.pageNum
                color: page.colors.outline
                font.pixelSize: 11
            }
        }

        // --- Image grid -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: page.colors.surfaceHigh
            border.width: 1; border.color: page.colors.outline
            radius: 0
            clip: true

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: 3
                cellWidth: Math.floor(width / 2)
                cellHeight: cellWidth
                model: page.posts
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                // Load next page when scrolled near the end.
                onContentYChanged: {
                    if (!page.busy && atYEnd && page.posts.length > 0)
                        page.nextPage();
                }

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: page.colors.surface
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: modelData.preview_url ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.openImage(modelData.file_url ?? modelData.sample_url ?? modelData.preview_url)
                        }
                    }
                }
            }

            Text { // placeholder
                anchors.centerIn: parent
                visible: page.posts.length === 0 && !page.busy
                text: "󰋑  Search anime boorus\nType tags below, e.g.  landscape scenery"
                horizontalAlignment: Text.AlignHCenter
                font.family: "CaskaydiaMono Nerd Font"
                font.pixelSize: 13
                color: page.colors.outline
            }
            BusyIndicator {
                anchors.centerIn: parent
                running: page.busy
                visible: page.busy
            }
        }

        // --- Tag input --------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            radius: 0
            color: page.colors.surface
            border.width: 1
            border.color: page.colors.outline
            implicitHeight: 44

            TextField {
                id: tagInput
                anchors.fill: parent
                anchors.margins: 4
                placeholderText: "Tags…  (Enter to search, append a number for page)"
                placeholderTextColor: page.colors.outline
                color: page.colors.fg
                font.pixelSize: 14
                background: null
                onAccepted: page.search(text)
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        page.closeRequested();
                    }
                }
            }
        }
    }
}
