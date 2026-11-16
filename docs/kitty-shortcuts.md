# Kitty shortcuts

Defined in `modules/home-manager/kitty.nix`, modelled on zellij. Floats and
pane focus/movement come from `modules/home-manager/configs/kitty/float.py`.

Everything that opens a window or tab follows `kitten ssh` (the fish `ssh`
wrapper): inside an ssh session it opens on the remote host. alt+t is the
exception.

## Tabs

| Key | Action |
|---|---|
| alt+t | New tab, always local (from an ssh window: in that window's local directory) |
| alt+shift+t | New tab in the same context (remote over ssh) |
| alt+1 … alt+9 | Go to tab N |
| alt+r | Rename tab |

## Splits and windows

| Key | Action |
|---|---|
| alt+n | New split, or a new float when a float is focused |
| alt+d | New split to the right (vertical) |
| alt+shift+d | New split below (horizontal) |
| alt+x | Close window |
| alt+z | Toggle stack layout (zoom the current window) |
| alt+] | Next layout (splits ↔ stack) |

## Floats

The float drawer is a short split along the bottom of the tab. Hidden floats
wait in a stash tab that is not shown in the tab bar.

| Key | Action |
|---|---|
| alt+f | Show or hide the float drawer, or create a float if there is none |
| alt+shift+f | Switch to the next float in the stack |
| alt+n (on a float) | Add another float to the stack |

## Focus and movement

| Key | Action |
|---|---|
| alt+h/j/k/l, alt+arrows | Focus the pane in that direction; at the left/right edge, switch tabs; on a focused float, left/right switch between floats |
| alt+shift+h/j/k/l | Move the window; at the left/right edge, move the whole tab |

## Resize

| Key | Action |
|---|---|
| alt+= / alt+- | Wider / narrower |
| alt+shift+= / alt+shift+- | Taller / shorter |
