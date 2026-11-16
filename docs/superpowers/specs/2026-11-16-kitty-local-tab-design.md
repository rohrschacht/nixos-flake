# Kitty: local new tab vs. same-context new tab

## Why

alt+t inside a `kitten ssh` tab always reopens the ssh session (`--cwd=current`
follows kitten ssh). Often a local tab is wanted instead.

## Goals

- alt+t always opens a **local** tab.
- alt+shift+t opens a tab in the **same context**: remote when over ssh, local
  otherwise (today's alt+t).

## Non-goals

- Splits and floats are unchanged: alt+d, alt+shift+d, alt+n, alt+f keep
  following ssh.

## Approaches

1. **Two shortcuts** (chosen): alt+t local, alt+shift+t same context. No
   interruption, mirrors the alt+d / alt+shift+d pairing.
2. **Prompt only over ssh**: alt+t asks remote/local when the tab is a kitten
   ssh session, no prompt otherwise. Rejected: one extra keypress on every
   alt+t over ssh.

## Design

- `"alt+t" = "kitten float.py local_tab";` — new `local_tab` action in
  `configs/kitty/float.py`: if the focused window is inside kitten ssh
  (`w.ssh_kitten_cmdline()`), launch a tab with the literal local cwd of the
  window's root process (`w.child.current_cwd`, fallback `~`); a literal path
  never triggers kitty's ssh cloning. Otherwise `--cwd=current`.
- `"alt+shift+t" = "launch --type=tab --cwd=current";`
- Update the comment above the keybindings, which says every launch follows ssh.

First attempt was plain `launch --type=tab --cwd=root`. Rejected in review:
kitty (0.49.1, `window.py:184`) clones the ssh session for `root` whenever the
window's root process is in the foreground, which is always true in windows
kitty itself cloned over ssh (floats, splits, alt+shift+t tabs), so alt+t
would have gone remote from those.

## Left to verify live

alt+t from an ssh tab, from a float/split inside it, and from a local tab.
