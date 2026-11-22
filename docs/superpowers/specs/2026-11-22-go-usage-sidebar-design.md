# Go usage + cache status in the TUI sidebar — design

Date: 2026-11-22
Status: approved approach A, pending design approval
Owner: tobias (via planner session)

## Intent

While working in the OpenCode TUI, tobias wants to see at a glance how much of
his OpenCode Go subscription allowance he has consumed (5-hour, weekly,
monthly meters) and whether the current session's prompt cache is hot or cold,
including how long it will stay hot. The right sidebar today carries little
information; this panel fills it with the two things he actually monitors.

## Goals

- Show the three Go meters in the session sidebar: percent used, a small bar,
  and when each resets. Highlight when a meter is exhausted (`limited`).
- Show prompt-cache state for the current session: HOT with an estimated
  countdown, or COLD with time since last use; plus the last request's cache
  hit share (how much of its input came from cache).
- Theme-aware rendering (uses the TUI's semantic theme tokens, matches the
  sidebar's look).
- Graceful degradation: if usage data is unavailable (endpoint change, no
  subscription, server unreachable), the panel shows a quiet "unavailable"
  state and never breaks the TUI.

## Non-goals

- No cache warming control. OpenCode's built-in `warming` feature stays off;
  the panel only reports state. (Enabling warming is a separate one-line
  config decision, not part of this work.)
- No Console budgets display (the workspace has none today); no usage history
  or charts; no per-model allowance breakdown.
- No OpenCode Desktop (GUI) part; TUI only.
- No nix/home-manager integration of the plugin for now. `~/.config/opencode`
  is plain files on this machine; reproducibility across machines is a
  possible later change.
- No modification of OpenCode itself.

## Anti-goals

- Anything that sends extra model requests (the panel must not consume Go
  allowance itself).
- Aggressive polling or timers that keep running while the panel is not
  visible.
- Handling, storing, or displaying API keys or tokens in the plugin.
- A panel that crashes or spams errors when the experimental endpoint changes
  shape in a future OpenCode release.

## Constraints / verified facts

- OpenCode 2.3.0, nixpkgs-unstable binary. V2 TUI plugin API:
  `import { Plugin } from "@opencode/plugin/tui"` — OpenCode resolves the
  import at runtime; no npm install needed for the plugin SDK. (The stale
  `@opencode-ai/plugin@1.17.7` in `~/.config/opencode/node_modules` is a V1
  leftover and must NOT be used.)
- Local plugins are auto-discovered at
  `~/.config/opencode/plugins/<name>/tui.tsx` (global config dir).
- Sidebar slots exist: `sidebar.content` and `sidebar.footer`; render receives
  `{ sessionID }`. Placement verbs: prepend/append/before/after/replace.
- The server already serves the meters: `GET /api/experimental/usage/limits`.
  Verified live response:
  `{ location, data: { workspace: {id, name, usageURL}, go: { rolling, weekly,
  monthly }, budgets: [] } }` where each meter is
  `{ percent: number, limited: boolean, resetsAt: number /* ms epoch */ }`.
  `go` may be absent when there is no Go subscription.
- The generated client exposes it: `client.experimental.usage.limits({
  location })` — verified present in the 2.3.0 binary. The TUI data layer also
  has an internal `usageLimits` domain (list/sync/invalidate, cache key
  `location.usageLimits:<dir>`) that may be exposed as
  `context.data.location.usageLimits`; prefer it if available, else call the
  client directly. Verify at runtime in the first implementation task.
- Assistant messages (`Session.Message.Assistant`) carry
  `tokens: { input, output, reasoning, cache: { read, write } }`,
  `time: { created, firstToken?, streamed?, completed? }`, and a `model` ref.
  The TUI exposes them via `context.data.session.message.list(sessionID)`
  (reactive; sync/invalidate available).
- Cache TTL: OpenCode sends no lifetime by default; providers use their own
  (Go's default is the 5-minute flavor — its billing distinguishes
  `cache_write_5m` / `cache_write_1h`). A configured
  `providers.opencode-go.settings.cache.ttl` (or per-model
  `models.<id>.settings.cache.ttl`) overrides, duration strings like `"5m"`,
  `"1h"`. Nothing is configured on this machine today.
- Per OpenCode's warming docs, a provider's cache lifetime starts when the
  request reaches it — so countdowns anchor on request send time
  (`time.created`), not response completion.
- Plugin options can be passed via `cli.json`'s object form
  `{ "package": "./plugins/go-usage", "options": { ... } }`; auto-discovery
  loads with defaults.

## Approaches considered

- **A — TUI-only plugin (chosen by tobias).** One `tui.tsx`, auto-discovered;
  reads meters via the built-in client, computes cache state from session
  messages, renders into `sidebar.content`. Smallest surface, no secrets, no
  server code. Trade-off: depends on an experimental endpoint; mitigated by
  defensive parsing + quiet unavailable state.
- **B — Server + TUI plugin with custom RPC.** Server part fetches the
  documented public Go usage API (`https://opencode.ai/inference/go/v1/usage`)
  using resolved Console credentials; TUI part renders. Sturdier data source,
  but three files + credential handling for identical output. Kept as the
  fallback if the experimental endpoint proves unstable.
- Rejected: patching OpenCode (nix binary; slots exist for this), external
  widgets (tmux bar etc. — user wants it inside the TUI).

## Agreed behavior

Panel sketch (append to `sidebar.content`, session view):

```
Go usage
  5h     10%  ▓░░░░░░░░░   resets 01:38
  week    7%  ▓░░░░░░░░░   resets Mon 00:00
  month   3%  ░░░░░░░░░░   resets Dec 22

Cache · qwen4-max
  HOT   ~3m 12s left (5m ttl)
  last request: 96% of input from cache
```

- Meters: percent + bar + reset time (local time; compact format). When
  `limited` is true, render in the theme's error/warning color and make the
  reset time prominent.
- Cache state for the slot's session:
  - Find the newest assistant message with `cache.read > 0` or
    `cache.write > 0`. Anchor = its `time.created`.
  - Effective TTL = model `settings.cache.ttl` ?? provider
    `settings.cache.ttl` ?? plugin option `cacheTtl` (default `"5m"`).
  - HOT when `now - anchor < TTL`; countdown = `TTL - (now - anchor)`,
    displayed as an estimate (`~`, `(5m ttl)`). Each newer cache-touching
    message moves the anchor (sliding refresh).
  - COLD otherwise: show time since last cache use. No cache-touching message
    yet → "cold — no requests yet".
  - Model switch: if the session's current model differs from the anchor
    message's model, treat as COLD (prefix cache invalidated).
  - Hit share = `cache.read / (input + cache.read + cache.write)` of the
    newest assistant message that has token data (not only cache-touching
    ones), shown as a percent.
- Known limitation (documented in the plugin README): if `warming` is ever
  enabled, warming requests keep the cache hot but do not appear in session
  history, so the countdown reads pessimistic. Acceptable for v1.

## Left to the builder

- Exact refresh mechanics: limits refresh on mount + on relevant events
  (e.g. usage/message events) + a slow timer (~60s); countdown ticks locally
  (~1s). All timers live inside the slot component's lifecycle so nothing
  runs while the sidebar is hidden.
- Whether to use `context.data.location.usageLimits` (if exposed) or
  `client.experimental.usage.limits` directly; verify in task 1.
- Reading configured TTLs from the plugin context's config access (verify
  accessor name at runtime).
- Bar glyphs, spacing, reset-time formatting, color thresholds (e.g. warning
  ≥ 80%), all via semantic theme tokens.
- Defensive parsing of the endpoint response; quiet unavailable state; log
  details via the plugin's normal logging, never throw into the render path.
- A short README next to the plugin: what it shows, the TTL assumption, the
  `cacheTtl` option, the warming caveat.

## Verification

- Load the TUI in a session; panel appears in the right sidebar with live
  numbers matching `opencode api get /api/experimental/usage/limits`.
- Send a prompt; cache section flips to HOT with a countdown near the TTL;
  hit share updates after the response.
- Wait past TTL (or temporarily set `cacheTtl` to a few seconds via options)
  → COLD with elapsed time.
- Simulate endpoint failure (e.g. temporary rename of the method in a test
  harness or invalid response injection) → quiet unavailable state, TUI
  unaffected.
- No new model requests are generated by the panel (observe session message
  count / Go usage while idle).
