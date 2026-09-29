# Title bar content for kitty windows (see float.py). Only floats get one:
# an empty result hides the title bar, so ordinary panes stay bare.

from kitty.fast_data_types import get_boss

VAR = "kitty_float"
STASH = "__float_stash_"


def draw_window_title(data):
    boss = get_boss()
    w = boss.window_id_map.get(data.window_id)
    if w is None or w.user_vars.get(VAR) != "1":
        return ""
    tab = w.tabref()
    tm = tab.tab_manager_ref() if tab is not None else None
    if tm is None:
        return ""
    stack = [x for x in tab if x.user_vars.get(VAR) == "1"]
    stash = next((t for t in tm if t.name == f"{STASH}{tab.id}"), None)
    if stash is not None:
        stack += list(stash)
    stack.sort(key=lambda x: x.id)
    pos = stack.index(w) + 1 if w in stack else 1
    return f" float {pos}/{len(stack)} │ {data.title}"
