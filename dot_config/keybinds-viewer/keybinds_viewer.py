#!/usr/bin/env python3
"""Keybind viewer — SUPER+K popup for Hyprland/Tmux/Neovim."""
import warnings
warnings.filterwarnings("ignore")
import re
import os
import sys
import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gdk, GLib, Pango

COLORS_PATH = os.path.expanduser("~/.config/rofi/colors.rasi")
APP_ID = "io.local.keybindsviewer"

TABS = ["All", "Hyprland", "Tmux", "Neovim", "SubTUI", "Vimium", "Yazi"]

KEYBINDS = {
    "Hyprland": [
        ("SUPER + T",           "Open terminal"),
        ("SUPER + F",           "Open Firefox"),
        ("SUPER + E",           "Open file manager"),
        ("SUPER + R",           "App launcher (rofi)"),
        ("SUPER + C",           "Clipboard history"),
        ("SUPER + K",           "Keybind viewer"),
        ("SUPER + Q",           "Close window"),
        ("SUPER + V",           "Toggle float"),
        ("SUPER + D",           "Toggle pseudo tiling"),
        ("SUPER + J",           "Toggle split direction"),
        ("SUPER + ↑↓←→",        "Move focus"),
        ("SUPER+SHIFT + ↑↓←→",  "Resize window"),
        ("SUPER + 1–9",         "Switch workspace"),
        ("SUPER+SHIFT + 1–9",   "Move window to workspace"),
        ("SUPER + S",           "Toggle scratchpad"),
        ("SUPER+SHIFT + S",     "Move to scratchpad"),
        ("SUPER + L",           "Lock screen"),
        ("SUPER + M",           "Exit / shutdown"),
        ("SUPER + P",           "Screenshot (active window)"),
        ("SUPER+SHIFT + P",     "Screenshot (region select)"),
    ],
    "Tmux": [
        ("Ctrl+S",              "Prefix key"),
        ("PREFIX + h",          "Focus pane left"),
        ("PREFIX + j",          "Focus pane down"),
        ("PREFIX + k",          "Focus pane up"),
        ("PREFIX + l",          "Focus pane right"),
        ('PREFIX + "',          "Split pane horizontal"),
        ("PREFIX + %",          "Split pane vertical"),
        ("PREFIX + z",          "Zoom / unzoom pane"),
        ("PREFIX + x",          "Kill pane"),
        ("PREFIX + c",          "New window"),
        ("PREFIX + n",          "Next window"),
        ("PREFIX + p",          "Previous window"),
        ("PREFIX + ,",          "Rename window"),
        ("PREFIX + d",          "Detach session"),
        ("PREFIX + r",          "Reload config"),
        ("PREFIX + [",          "Enter copy mode"),
        ("PREFIX + ]",          "Paste buffer"),
    ],
    "Neovim": [
        ("Space",               "Leader key"),
        ("Ctrl+H/J/K/L",        "Navigate windows"),
        ("Ctrl+N",              "Toggle Neo-tree sidebar"),
        ("Ctrl+P",              "Find files (Telescope)"),
        ("Space + fg",          "Live grep (Telescope)"),
        ("gd",                  "Go to definition"),
        ("gr",                  "Go to references"),
        ("gi",                  "Go to implementation"),
        ("K",                   "Hover docs (LSP)"),
        ("Space + rn",          "Rename symbol"),
        ("Space + ca",          "Code action"),
        ("gcc",                 "Toggle line comment"),
        ("gc",                  "Toggle comment (visual)"),
        ("[d / ]d",             "Prev / next diagnostic"),
        ("Space + e",           "Show diagnostic float"),
    ],
    "SubTUI": [
        ("Tab / Shift+Tab",     "Cycle focus next / prev"),
        ("Backspace / Esc",     "Back"),
        ("?",                   "Help"),
        ("q",                   "Quit"),
        ("Ctrl+C",              "Hard quit"),
        ("j / k / ↑↓",          "Navigate down / up"),
        ("gg / G",              "Jump to top / bottom"),
        ("Enter",               "Select"),
        ("x",                   "Toggle selection"),
        ("Alt+Enter",           "Play shuffled"),
        ("Ctrl+U / Ctrl+D",     "Half page up / down"),
        ("/",                   "Focus search"),
        ("Ctrl+N / Ctrl+B",     "Next / prev filter result"),
        ("A",                   "Add to playlist"),
        ("R",                   "Add rating"),
        ("ga / gr",             "Go to album / artist"),
        ("0–5",                 "Rate track (0–5 stars)"),
        ("p",                   "Play / pause"),
        ("n / b",               "Next / previous track"),
        ("S",                   "Shuffle"),
        ("L",                   "Loop"),
        ("w",                   "Restart track"),
        (", / ;",               "Rewind / forward"),
        ("v / V",               "Volume up / down"),
        ("m",                   "Toggle media player"),
        ("Q",                   "Toggle queue view"),
        ("N",                   "Add to queue next"),
        ("a",                   "Add to queue last"),
        ("d / D",               "Remove from / clear queue"),
        ("K / J",               "Move queue item up / down"),
        ("f / F",               "Toggle / view favorites"),
        ("s",                   "Toggle notifications"),
        ("Ctrl+S",              "Create share link"),
    ],
    "Yazi": [
        ("h / l",               "Go to parent / enter directory"),
        ("j / k",               "Move down / up"),
        ("gg / G",              "Jump to top / bottom"),
        ("Enter",               "Open file"),
        ("o",                   "Open with default app"),
        ("Space",               "Toggle selection"),
        ("v",                   "Visual select mode"),
        ("y",                   "Yank (copy)"),
        ("x",                   "Cut"),
        ("p",                   "Paste"),
        ("d",                   "Trash"),
        ("D",                   "Delete permanently"),
        ("r",                   "Rename"),
        ("a",                   "Create file/directory"),
        ("/",                   "Search"),
        ("f",                   "Filter"),
        ("s",                   "Sort"),
        ("zh",                  "Toggle hidden files"),
        ("~",                   "Go to home directory"),
        ("-",                   "Go to previous directory"),
        ("z",                   "Jump with zoxide"),
        ("q",                   "Quit"),
    ],
    "Vimium": [
        ("?",                   "Show help / keybind list"),
        ("f",                   "Open link in current tab (hints)"),
        ("F",                   "Open link in new tab (hints)"),
        ("j / k",               "Scroll down / up"),
        ("h / l",               "Scroll left / right"),
        ("d / u",               "Scroll half page down / up"),
        ("gg / G",              "Scroll to top / bottom"),
        ("H / L",               "Back / forward in history"),
        ("r",                   "Reload page"),
        ("yy",                  "Copy current URL"),
        ("yf",                  "Copy link URL (hints)"),
        ("o / O",               "Open URL / in new tab (omnibar)"),
        ("b / B",               "Open bookmark / in new tab"),
        ("t",                   "New tab"),
        ("x / X",               "Close tab / restore closed tab"),
        ("J / K",               "Previous / next tab"),
        ("g0 / g$",             "First / last tab"),
        ("/",                   "Find in page"),
        ("n / N",               "Next / previous search match"),
        ("gi",                  "Focus first text input"),
        ("v",                   "Enter visual mode"),
        ("V",                   "Visual line mode"),
        ("p / P",               "Open clipboard URL (tab / new tab)"),
        ("Esc",                 "Exit input / hint mode"),
    ],
}


def parse_colors():
    c = {
        "base":     "#1e1e2e",
        "text":     "#cdd6f4",
        "surface0": "#313244",
        "surface1": "#45475a",
        "overlay0": "#6c7086",
        "blue":     "#89b4fa",
        "subtext0": "#a6adc8",
    }
    try:
        content = open(COLORS_PATH).read()
        for k in list(c.keys()):
            m = re.search(rf"\b{re.escape(k)}\s*:\s*(#[0-9a-fA-F]{{6}})", content)
            if m:
                c[k] = m.group(1)
    except Exception:
        pass
    return c


def make_css(c):
    return f"""
window,
window.background {{
    background-color: transparent;
}}

/* Root — straight corners, no rounding */
.kb-root {{
    background-color: {c['base']};
    border-radius: 0;
    border: 1px solid {c['overlay0']};
}}

/* ── Search bar ───────────────────────────────────── */
entry.kb-search,
entry.kb-search > text,
entry.kb-search:focus,
entry.kb-search:focus > text {{
    background-color: {c['surface0']};
    background-image: none;
    color: {c['text']};
    caret-color: {c['blue']};
    border: 1px solid {c['overlay0']};
    border-radius: 6px;
    box-shadow: none;
    outline: none;
    outline-width: 0;
    font-size: 14px;
    padding: 6px 10px;
    min-height: 0;
}}

/* ── Tab tray ─────────────────────────────────────── */
.kb-tabbar {{
    background-color: {c['surface1']};
    padding: 0;
}}

/* ── Tabs — set_has_frame(False) already kills border;
   just set colors and layout here.                    */
.kb-tab {{
    background-color: transparent;
    color: {c['subtext0']};
    border-radius: 0;
    padding: 9px 20px;
    font-size: 13px;
}}
.kb-tab:hover {{
    color: {c['text']};
    background-color: {c['surface0']}60;
}}
.kb-tab:focus,
.kb-tab:focus-visible,
.kb-tab:focus-within {{
    color: {c['text']};
    outline: 2px solid {c['blue']};
    outline-offset: -3px;
}}
/* Active: content-matching bg + 2px accent at top */
.kb-tab.active {{
    background-color: {c['base']};
    color: {c['text']};
    box-shadow: inset 0 2px 0 0 {c['blue']};
}}

/* ── Scroll area — kill all overscroll visuals ───── */
scrolledwindow {{
    background-color: transparent;
}}
scrolledwindow undershoot,
scrolledwindow undershoot.top,
scrolledwindow undershoot.bottom,
scrolledwindow overshoot,
scrolledwindow overshoot.top,
scrolledwindow overshoot.bottom {{
    background: none;
    background-color: transparent;
    box-shadow: none;
    min-height: 0;
}}

/* ── List ─────────────────────────────────────────── */
.kb-list {{
    background-color: transparent;
}}
.kb-list > row {{
    background: transparent;
    padding: 0;
    border-radius: 0;
}}
.kb-list > row:hover {{
    background-color: {c['surface0']};
}}
.kb-list > row:focus,
.kb-list > row:focus-visible,
.kb-list > row:focus-within {{
    background-color: {c['surface0']};
    outline: 2px solid {c['blue']};
    outline-offset: -2px;
}}
.kb-row {{
    padding: 7px 16px;
}}
.kb-key {{
    color: {c['blue']};
    font-family: monospace;
    font-size: 13px;
    font-weight: bold;
}}
.kb-desc {{
    color: {c['text']};
    font-size: 13px;
}}
"""


class KeybindsViewer(Gtk.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID)
        self._win = None
        self._query = ""
        self._row_data = {}   # Gtk.ListBoxRow -> (key_lower, desc_lower)
        self._lists = {}      # tab -> Gtk.ListBox
        self._tab_btns = {}   # tab -> Gtk.Button
        self._stack = None

    def do_activate(self):
        if self._win:
            self._win.present()
            return

        provider = Gtk.CssProvider()
        css = make_css(parse_colors())
        try:
            provider.load_from_string(css)
        except AttributeError:
            provider.load_from_data(css.encode())

        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )

        win = Gtk.ApplicationWindow(application=self)
        win.set_decorated(False)
        win.set_default_size(740, 500)
        win.set_resizable(False)
        win.remove_css_class("background")  # prevents GTK default white bleed
        self._win = win
        win.connect("destroy", lambda _: setattr(self, "_win", None))

        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
        key_ctrl.connect("key-pressed", self._on_key_pressed)
        win.add_controller(key_ctrl)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root.add_css_class("kb-root")
        win.set_child(root)

        search = Gtk.Entry()
        search.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "system-search-symbolic")
        search.set_placeholder_text("Search keybinds…")
        search.set_hexpand(True)
        search.add_css_class("kb-search")
        self._search = search
        search.set_margin_top(10)
        search.set_margin_bottom(8)
        search.set_margin_start(12)
        search.set_margin_end(12)
        root.append(search)

        # Tab bar
        tabbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        tabbar.add_css_class("kb-tabbar")
        root.append(tabbar)

        # Stack
        stack = Gtk.Stack()
        stack.set_vexpand(True)
        stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        stack.set_transition_duration(80)
        root.append(stack)
        self._stack = stack

        # Build each tab's list
        for tab in TABS:
            scr = Gtk.ScrolledWindow()
            scr.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            scr.set_vexpand(True)
            scr.set_has_frame(False)
            scr.set_kinetic_scrolling(False)
            # Take over ALL scroll events — GTK never sees them, zero animation
            _esc = Gtk.EventControllerScroll.new(
                Gtk.EventControllerScrollFlags.VERTICAL
            )
            _esc.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
            def _plain_scroll(ctrl, _dx, dy, s=scr):
                a   = s.get_vadjustment()
                lo  = a.get_lower()
                hi  = a.get_upper() - a.get_page_size()
                if hi <= lo:
                    return True
                val = a.get_value() + dy * 18.0
                a.set_value(max(lo, min(val, hi)))
                return True   # always consume — GTK gets nothing
            _esc.connect("scroll", _plain_scroll)
            scr.add_controller(_esc)

            lb = Gtk.ListBox()
            lb.add_css_class("kb-list")
            lb.set_selection_mode(Gtk.SelectionMode.NONE)
            lb.set_filter_func(self._filter_row)

            entries = (
                [(k, d) for kvs in KEYBINDS.values() for k, d in kvs]
                if tab == "All"
                else KEYBINDS.get(tab, [])
            )

            for key, desc in entries:
                row = Gtk.ListBoxRow()
                box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
                box.add_css_class("kb-row")

                key_lbl = Gtk.Label(label=key)
                key_lbl.add_css_class("kb-key")
                key_lbl.set_xalign(0)
                key_lbl.set_width_chars(24)
                key_lbl.set_ellipsize(Pango.EllipsizeMode.END)

                desc_lbl = Gtk.Label(label=desc)
                desc_lbl.add_css_class("kb-desc")
                desc_lbl.set_xalign(0)
                desc_lbl.set_hexpand(True)

                box.append(key_lbl)
                box.append(desc_lbl)
                row.set_child(box)
                lb.append(row)
                self._row_data[row] = (key.lower(), desc.lower())

                click = Gtk.GestureClick.new()
                click.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
                click.connect("pressed", lambda *_a, r=row: r.grab_focus())
                row.add_controller(click)

            self._lists[tab] = lb
            scr.set_child(lb)
            stack.add_named(scr, tab)

        # Tab buttons — set_has_frame(False) removes GTK's button border/shadow
        for i, tab in enumerate(TABS):
            btn = Gtk.Button(label=tab)
            btn.set_has_frame(False)
            btn.add_css_class("kb-tab")
            if i == 0:
                btn.add_css_class("active")
            btn.connect("clicked", self._on_tab_click, tab)
            self._tab_btns[tab] = btn
            tabbar.append(btn)

        stack.set_visible_child_name("All")
        search.connect("changed", self._on_search)

        win.present()
        GLib.idle_add(lambda: (search.grab_focus(), GLib.SOURCE_REMOVE)[1])

    ZONES = ("search", "tabs", "list")

    def _zone_of(self, widget):
        if widget is None:
            return None
        if widget is self._search or isinstance(widget, Gtk.Text):
            return "search"
        if widget in self._tab_btns.values():
            return "tabs"
        if isinstance(widget, Gtk.ListBoxRow):
            return "list"
        return None

    def _cycle_zone(self, current, backward=False):
        idx = self.ZONES.index(current) if current in self.ZONES else -1
        idx = (idx - 1) % len(self.ZONES) if backward else (idx + 1) % len(self.ZONES)
        self._focus_zone(self.ZONES[idx])

    def _focus_zone(self, zone):
        tab = self._stack.get_visible_child_name()
        if zone == "search":
            self._search.grab_focus()
        elif zone == "tabs":
            self._tab_btns[tab].grab_focus()
        elif zone == "list":
            row = self._lists[tab].get_row_at_index(0)
            if row:
                row.grab_focus()
                self._scroll_row_into_view(row)

    def _move_tab_focus(self, delta):
        focus = self._win.get_focus()
        cur = next((t for t, b in self._tab_btns.items() if b is focus), None)
        if cur is None:
            cur = self._stack.get_visible_child_name()
        idx = (TABS.index(cur) + delta) % len(TABS)
        tab = TABS[idx]
        btn = self._tab_btns[tab]
        btn.grab_focus()
        self._on_tab_click(btn, tab)

    def _move_list_focus(self, delta):
        lb = self._lists[self._stack.get_visible_child_name()]
        focus = self._win.get_focus()
        row = focus if isinstance(focus, Gtk.ListBoxRow) else lb.get_row_at_index(0)
        if row is None:
            return
        i = row.get_index() + delta
        while True:
            cand = lb.get_row_at_index(i)
            if cand is None:
                return
            if cand.get_child_visible():
                cand.grab_focus()
                self._scroll_row_into_view(cand)
                return
            i += delta

    def _scroll_row_into_view(self, row):
        scr = row.get_ancestor(Gtk.ScrolledWindow)
        lb = row.get_parent()
        if scr is None or lb is None:
            return
        ok, bounds = row.compute_bounds(lb)
        if not ok:
            return
        adj = scr.get_vadjustment()
        top = bounds.get_y()
        bottom = top + bounds.get_height()
        val = adj.get_value()
        page = adj.get_page_size()
        if top < val:
            adj.set_value(top)
        elif bottom > val + page:
            adj.set_value(bottom - page)

    def _on_key_pressed(self, _ctrl, keyval, _keycode, state):
        win = self._win
        name = Gdk.keyval_name(keyval) or ""

        if name == "Escape":
            win.close()
            return True

        zone = self._zone_of(win.get_focus())

        if name in ("Tab", "ISO_Left_Tab"):
            backward = name == "ISO_Left_Tab" or bool(state & Gdk.ModifierType.SHIFT_MASK)
            self._cycle_zone(zone, backward)
            return True

        if zone == "tabs":
            if name == "h":
                self._move_tab_focus(-1)
                return True
            if name == "l":
                self._move_tab_focus(1)
                return True
        elif zone == "list":
            if name == "j":
                self._move_list_focus(1)
                return True
            if name == "k":
                self._move_list_focus(-1)
                return True

        return False

    def _on_tab_click(self, _btn, tab):
        for t, b in self._tab_btns.items():
            if t == tab:
                b.add_css_class("active")
            else:
                b.remove_css_class("active")
        self._stack.set_visible_child_name(tab)
        self._lists[tab].invalidate_filter()

    def _on_search(self, entry):
        self._query = entry.get_text().strip().lower()
        for lb in self._lists.values():
            lb.invalidate_filter()

    def _filter_row(self, row, *_args):
        if not self._query:
            return True
        key, desc = self._row_data.get(row, ("", ""))
        return self._query in key or self._query in desc


if __name__ == "__main__":
    app = KeybindsViewer()
    app.run(sys.argv)
