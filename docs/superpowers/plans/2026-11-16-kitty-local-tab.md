# Kitty Local Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** alt+t opens a local tab even inside a `kitten ssh` tab; alt+shift+t keeps today's same-context behavior.

**Architecture:** Two kitty keybindings in the Home Manager kitty module. No kitten code.

**Tech Stack:** NixOS flake + Home Manager, kitty 0.49.1.

**Spec:** `docs/superpowers/specs/2026-11-16-kitty-local-tab-design.md`

## Global Constraints

- alt+d, alt+shift+d, alt+n, alt+f, alt+shift+f bindings stay unchanged.
- Verified in kitty 0.49.1 source (`kitty/window.py`, `CwdRequest.modify_argv_for_launch_with_cwd`): `--cwd=root` clones the ssh session only when the root shell is in the foreground (`window.root_in_foreground_processes`); in a kitten ssh window the foreground is `kitten ssh`, so the launch stays local and uses the local shell's cwd (`get_cwd_of_root_child`).

## Review Focus

1. alt+t in an ssh tab → local tab in the directory where `ssh` was typed (manual check, Task 1 Step 4).
2. alt+shift+t in an ssh tab → remote tab in the remote cwd (manual check, Task 1 Step 4).
3. alt+t in a local tab at the prompt → local tab in the shell's current cwd (manual check, Task 1 Step 4).
4. alt+t on a focused float inside an ssh tab → local tab (same mechanism as 1; manual check, Task 1 Step 4).
5. Generated `kitty.conf` contains exactly one `map alt+t` and one `map alt+shift+t` (Task 1 Step 2).

---

### Task 1: Rebind alt+t / alt+shift+t

**Files:**
- Modify: `modules/home-manager/kitty.nix` (keybindings block: the comment above `keybindings = {` and the `"alt+t"` line)

- [ ] **Step 1: Edit bindings**

Set `"alt+t" = "launch --type=tab --cwd=root";` and add `"alt+shift+t" = "launch --type=tab --cwd=current";` next to it, with a one-line comment that alt+t is always local and alt+shift+t follows kitten ssh. Update the block comment ("`--cwd=current` on every launch also makes new windows inside `kitten ssh` open on the remote host") so it no longer claims *every* launch follows ssh.

- [ ] **Step 2: Build and inspect generated config**

Run: `nix build .#nixosConfigurations.galileo.config.home-manager.users.tobias.xdg.configFile.\"kitty/kitty.conf\".source --no-link --print-out-paths | xargs grep -E 'map alt\+(shift\+)?t '`
Expected: exactly
```
map alt+t launch --type=tab --cwd=root
map alt+shift+t launch --type=tab --cwd=current
```
(If that attribute path doesn't resolve, build the full system with `nixos-rebuild build --flake .#galileo` and grep `result`'s home-files kitty.conf instead.)

- [ ] **Step 3: Apply** (user's call: needs sudo)

Run: `sudo nixos-rebuild switch --flake .#galileo`, then reload kitty config (ctrl+shift+f5) or open a new kitty.

- [ ] **Step 4: Manual check of Review Focus 1–4**

In kitty: `cd /tmp && ssh <host>`, then alt+t → `hostname` prints the local host and `pwd` prints `/tmp`; alt+shift+t → remote host, remote cwd. In a local tab after `cd ~/nixos`, alt+t → `pwd` is `~/nixos`. Open a float with alt+f in the ssh tab, alt+t → local.

- [ ] **Step 5: Commit** (only when the user asks)

```bash
git add modules/home-manager/kitty.nix docs/superpowers/specs/2026-11-16-kitty-local-tab-design.md docs/superpowers/plans/2026-11-16-kitty-local-tab.md
git commit -m "kitty: alt+t opens a local tab, alt+shift+t follows ssh"
```
