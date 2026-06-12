import QtQuick
import Quickshell
import Quickshell.Io

// Non-visual backend: drives the `claude` CLI (Claude Code) in stream-json mode
// and exposes a chat history model. One ClaudeService == one conversation.
Item {
    id: root

    // Chat transcript. Each entry: { role: "user"|"assistant"|"system", text, streaming }
    property ListModel messages: ListModel {}

    // Resume token from the CLI so follow-up turns keep context.
    property string sessionId: ""

    // True while a turn is in flight (request sent, result not yet received).
    property bool busy: false

    // Model alias passed to `claude --model` (opus | sonnet | haiku).
    property string model: "opus"

    // Chat mode (default): no tools, plain-assistant prompt — Claude cannot read
    // files, run commands, or touch the system. Turn off for full Claude Code.
    property bool chatMode: true
    readonly property string chatSystemPrompt:
        "You are Claude, a helpful and friendly AI assistant in a desktop chat "
        + "sidebar. Answer questions conversationally and concisely. You do not "
        + "have access to the user's files, terminal, or system."

    signal errored(string message)

    // Index of the assistant bubble we're currently appending tokens to.
    property int _activeIndex: -1

    function send(text) {
        if (busy || text.trim().length === 0)
            return;
        messages.append({ role: "user", text: text, streaming: false });
        _start(text);
    }

    // Re-ask the most recent user message (drops the trailing assistant reply).
    function regenerate() {
        if (busy)
            return;
        while (messages.count > 0
               && messages.get(messages.count - 1).role === "assistant")
            messages.remove(messages.count - 1);
        var lastUser = "";
        for (var i = messages.count - 1; i >= 0; i--) {
            if (messages.get(i).role === "user") { lastUser = messages.get(i).text; break; }
        }
        if (lastUser.length > 0)
            _start(lastUser);
    }

    // Add a local, non-AI notice line (used by slash commands).
    function addSystem(text) {
        messages.append({ role: "system", text: text, streaming: false });
    }

    // Wipe the conversation and forget the session so the next turn starts fresh.
    function reset() {
        if (busy)
            proc.running = false;
        messages.clear();
        sessionId = "";
        busy = false;
        _activeIndex = -1;
    }

    function _start(promptText) {
        messages.append({ role: "assistant", text: "", streaming: true });
        _activeIndex = messages.count - 1;
        busy = true;

        var cmd = ["claude", "-p", promptText, "--model", model,
                   "--output-format", "stream-json", "--verbose"];
        if (chatMode)
            cmd = cmd.concat(["--tools", "", "--system-prompt", chatSystemPrompt]);
        if (sessionId.length > 0)
            cmd = cmd.concat(["--resume", sessionId]);

        proc.command = cmd;
        proc.running = true;
    }

    function _appendToActive(chunk) {
        if (_activeIndex < 0)
            return;
        var cur = messages.get(_activeIndex).text;
        messages.setProperty(_activeIndex, "text", cur + chunk);
    }

    function _handleEvent(obj) {
        switch (obj.type) {
        case "system":
            if (obj.subtype === "init" && obj.session_id)
                sessionId = obj.session_id;
            break;
        case "assistant":
            if (obj.message && obj.message.content) {
                for (var i = 0; i < obj.message.content.length; i++) {
                    var block = obj.message.content[i];
                    if (block.type === "text")
                        _appendToActive(block.text);
                }
            }
            break;
        case "result":
            if (obj.session_id)
                sessionId = obj.session_id;
            if (_activeIndex >= 0 && messages.get(_activeIndex).text.length === 0
                    && obj.result)
                _appendToActive(obj.result);
            break;
        }
    }

    Process {
        id: proc
        running: false

        stdout: SplitParser {
            onRead: function (line) {
                if (line.trim().length === 0)
                    return;
                try {
                    root._handleEvent(JSON.parse(line));
                } catch (e) {
                    // Non-JSON noise on stdout; ignore.
                }
            }
        }

        stderr: SplitParser {
            onRead: function (line) {
                if (line.trim().length > 0)
                    console.warn("[claude]", line);
            }
        }

        onExited: function (exitCode, exitStatus) {
            root.busy = false;
            if (root._activeIndex >= 0)
                root.messages.setProperty(root._activeIndex, "streaming", false);
            if (exitCode !== 0) {
                var msg = "claude exited with code " + exitCode;
                if (root._activeIndex >= 0
                        && root.messages.get(root._activeIndex).text.length === 0)
                    root.messages.setProperty(root._activeIndex, "text", "⚠ " + msg);
                root.errored(msg);
            }
            root._activeIndex = -1;
        }
    }
}
