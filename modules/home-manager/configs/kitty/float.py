# Zellij-style floating panes for kitty, which can't float windows on GNOME.
#
# A "float" is a window tagged with the user var kitty_float=1. At most one
# float per tab is visible, as a short split along the bottom (the "drawer").
# The others wait in a per-tab stash tab named __float_stash_<tab id>, which
# tab_bar_filter hides; goto_tab/next_tab skip filtered tabs.
#
#   kitten float.py toggle         show/hide the drawer, or create a float
#   kitten float.py new [DIR]      add a float to the tab's stack and show it
#   kitten float.py new_or_split   new float if a float is focused, else split
#   kitten float.py cycle [-1]     show the next (or previous) float
#   kitten float.py focus DIR      zellij's MoveFocusOrTab: focus the pane in
#                                  DIR (left/right/up/down), else switch tabs;
#                                  on a focused float, left/right cycle instead
#
# Also loaded as a watcher (kitty.conf `watcher float.py`): closing the
# visible float brings up the next one, a tab's stash is closed together with
# the tab, and only floats get a window title bar (see on_load).

from kittens.tui.handler import result_handler
from kitty.fast_data_types import add_timer, attach_window

VAR = "kitty_float"
STASH = "__float_stash_"
DRAWER_PERCENT = 30


def main(args):
    pass


def is_float(w):
    return w.user_vars.get(VAR) == "1"


def find_stash(tm, tab):
    name = f"{STASH}{tab.id}"
    return next((t for t in tm if t.name == name), None)


def close_orphan_stashes(boss, tm):
    # A stash outlives its tab when that tab is closed; its floats go with it.
    ids = {str(t.id) for t in tm}
    for t in list(tm):
        if t.name.startswith(STASH) and t.name[len(STASH):] not in ids:
            boss.close_tab_no_confirm(t)


def on_load(boss, data):
    # window_title_bar_min_windows turns title bars on for every window in the
    # tab, and an empty title (window_title_bar.py) only skips drawing it: the
    # row stays reserved, leaving an empty strip atop the main pane. Keep the
    # title bar on floats only. Guarded, so a changed kitty just loses this.
    from kitty.window import Window

    orig = getattr(Window, "set_geometry", None)
    if orig is None or getattr(orig, "_float_patched", False):
        return

    def set_geometry(self, new_geometry):
        if not is_float(self):
            self.show_title_bar = False
        return orig(self, new_geometry)

    set_geometry._float_patched = True
    Window.set_geometry = set_geometry


def on_close(boss, window, data):
    tab = window.tabref()
    reveal = (
        is_float(window) and tab is not None and not tab.name.startswith(STASH)
    )
    tab_id, closed_id = (tab.id if tab else None), window.id

    # the window (and possibly its tab) is only removed afterwards, so act
    # once kitty is done with it
    def after_close(timer_id):
        for tm in list(boss.os_window_map.values()):
            close_orphan_stashes(boss, tm)
        if not reveal:
            return
        tab = boss.tab_for_id(tab_id)
        tm = tab.tab_manager_ref() if tab is not None else None
        if tm is None or any(is_float(w) for w in tab):
            return
        stash = find_stash(tm, tab)
        hidden = sorted(stash, key=lambda w: w.id) if stash is not None else []
        if hidden:
            nxt = next((w for w in hidden if w.id > closed_id), hidden[0])
            with boss.suppress_focus_change_events():
                show(boss, tab, nxt)
            tab.update_window_title_bars()

    add_timer(after_close, 0, False)


def hide(boss, tm, tab, w):
    if all(is_float(x) for x in tab):
        return  # detaching would leave the tab empty and close it
    stash = find_stash(tm, tab)
    if stash is None:
        stash = tm.new_tab(empty_tab=True)
        stash.set_title(f"{STASH}{tab.id}")
    stash.attach_windows(tab.detach_window(w))
    tm.set_active_tab(tab)


def show(boss, tab, w):
    src = w.tabref()
    anchor = next((x for x in tab if not is_float(x)), None)
    if tab.active_window is not None and not is_float(tab.active_window):
        anchor = tab.active_window
    group = src.detach_window(w)
    boss._cleanup_tab_after_window_removal(src)
    overlay_for = None
    for x in group:
        x.change_tab(tab)
        attach_window(tab.os_window_id, tab.id, x.id)
        if overlay_for is None:
            tab._add_window(x, location="hsplit", bias=DRAWER_PERCENT, next_to=anchor)
        else:
            tab._add_window(x, overlay_for=overlay_for)
        overlay_for = x.id
    tab.set_active_window(w)


def new_float(boss, cwd="current"):
    # --cwd=current follows kitten ssh, so floats open on the remote host too
    boss.launch(
        "--location=hsplit", f"--bias={DRAWER_PERCENT}",
        f"--cwd={cwd}", "--var", f"{VAR}=1",
    )
    # the var is set after the first layout, so redo it for the title bar
    if boss.active_tab is not None:
        boss.active_tab.relayout()


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    action = args[1]
    tab = boss.active_tab
    tm = boss.active_tab_manager
    if tab is None or tm is None or tab.name.startswith(STASH):
        return

    close_orphan_stashes(boss, tm)
    visible = [w for w in tab if is_float(w)]
    stash = find_stash(tm, tab)
    hidden = list(stash) if stash is not None else []

    if action == "focus":
        which = args[2]
        active = tab.active_window
        if active is not None and is_float(active) and which in ("left", "right"):
            action, args = "cycle", [args[0], "cycle", "-1" if which == "left" else "1"]
        else:
            # layouts name the edges top/bottom; the map action translates too
            neighbor = tab.neighboring_group_id(
                {"up": "top", "down": "bottom"}.get(which, which)
            )
            if neighbor:
                tab.windows.set_active_group(neighbor)
            elif which == "left":
                boss.previous_tab()
            elif which == "right":
                boss.next_tab()
            return

    if action == "new_or_split":
        active = tab.active_window
        if active is None or not is_float(active):
            boss.launch("--location=split", "--cwd=current")
            return
        action = "new"

    with boss.suppress_focus_change_events():
        if action == "toggle":
            if visible:
                for w in visible:
                    hide(boss, tm, tab, w)
            elif hidden:
                show(boss, tab, hidden[-1])  # the most recently hidden one
            else:
                new_float(boss)
        elif action == "new":
            for w in visible:
                hide(boss, tm, tab, w)
            new_float(boss, *args[2:3])
        elif action == "cycle":
            step = int(args[2]) if len(args) > 2 else 1
            stack = sorted(visible + hidden, key=lambda w: w.id)
            if not visible:
                if hidden:
                    show(boss, tab, hidden[-1])
            elif len(stack) > 1:
                cur = visible[0]
                nxt = stack[(stack.index(cur) + step) % len(stack)]
                hide(boss, tm, tab, cur)
                show(boss, tab, nxt)

    tab.update_window_title_bars()
