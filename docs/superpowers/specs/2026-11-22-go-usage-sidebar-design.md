# Go usage + cache status in the TUI sidebar — design

Date: 2026-11-22 (rev 2 — architect findings folded in)
Status: approach A chosen; design pending user approval
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
  countdown, COLD with time since last use, or UNKNOWN when state can't be
  determined; plus the last completed model call's cache hit share.
- Theme-aware rendering (semantic theme tokens, matches the sidebar's look).
- Graceful, per-section degradation: unavailable usage data never breaks the
  TUI or disables the cache section, and vice versa.

## Non-goals

- No cache warming control. OpenCode's built-in `warming` stays off; the panel
  only reports state.
- No Console budgets display (workspace has none today); no usage history or
  charts; no per-model allowance breakdown.
- No OpenCode Desktop (GUI) part; TUI only.
- No nix/home-manager integration of the plugin for now.
- No modification of OpenCode itself.

## Anti-goals

- Anything that sends extra model requests (the panel must not consume Go
  allowance itself).
- Unbounded background work: no polling loops that survive plugin disposal;
  while mounted, work is bounded (one local countdown tick per second, at
  most one limits fetch per ~60s, debounced event triggers). Whether mounted
  slots keep running while the sidebar is *visually hidden* depends on the
  visibility probe in task 1 (see Open question).
- Handling, storing, or displaying API keys or tokens in the plugin; logging
  whole config/provider/context objects, responses, requests, or headers.
- A panel that crashes or spams errors when the experimental endpoint changes
  shape in a future OpenCode release.

## Constraints / verified facts

- OpenCode 2.3.0, nixpkgs-unstable binary. V2 TUI plugin API:
  `import { Plugin } from "@opencode/plugin/tui"` — resolved at runtime; no
  npm install needed. The stale `@opencode-ai/plugin@1.17.7` in
  `~/.config/opencode/node_modules` is a V1 leftover and must NOT be used.
- **Loading (corrected):** the V2 docs say a package with only a TUI part
  goes in `cli.json`. An explicit entry is mandatory:
  `~/.config/opencode/cli.json` →
  `"plugins": [{ "package": "./plugins/go-usage", "options": { "cacheTtl": "5m" } }]`,
  preserving the existing `theme` setting. Plugin files live at
  `~/.config/opencode/plugins/go-usage/`. Global-config auto-discovery may
  also fire; task 1 must verify exactly one slot instance mounts (no
  duplicate registration). No dummy server part.
- Sidebar slots: `sidebar.content` / `sidebar.footer`; render receives
  `{ sessionID }`. Placement verbs: prepend/append/before/after/replace.
  The slot API documents no visibility signal; the sidebar can auto-hide on
  narrow terminals without disposing plugin components (cli.json schema).
- The server serves the meters: `GET /api/experimental/usage/limits`.
  Verified live: `{ location, data: { workspace: {id,name,usageURL},
  go: {rolling,weekly,monthly}, budgets: [] } }`, each meter
  `{ percent: number, limited: boolean, resetsAt: number /* ms epoch */ }`.
  `go` may be absent (no Go subscription).
- Generated client method verified in the 2.3.0 binary:
  `client.experimental.usage.limits({ location })`. This documented-client
  path is the baseline. The internal TUI `usageLimits` data domain exists but
  is undocumented on the plugin surface — do not depend on it.
- Assistant messages carry `tokens: {input,output,reasoning,cache:{read,write}}`,
  `time: {created,firstToken?,streamed?,completed?}`, `model` ref, `finish`,
  `error`, `retry`. TUI access: `context.data.session.message.list(sessionID)`
  plus `sync`/`invalidate`. V2 event subscriptions are live-only: call
  `message.sync` on mount and after `server.connected`.
- Cache TTL: OpenCode sends no lifetime by default; provider default applies.
  Go's default is the 5-minute flavor (billing splits `cache_write_5m` /
  `cache_write_1h`). Configured `settings.cache.ttl` overrides; per V2 model
  options, precedence is **selected variant > model > provider**. Duration
  strings (`"5m"`, `"1h"`). Nothing configured on this machine today.
  TTL config is read via the documented location-scoped catalogs
  (`context.data.location.provider/model` list/sync), NOT raw config files
  (which would miss project/system precedence).
- Provider cache lifetime starts when the request reaches it (warming docs):
  countdowns anchor on `time.created`, not completion. Warming requests and
  (possibly) compaction do not appear as normal assistant history.

## Approaches considered

- **A — TUI-only plugin (chosen by tobias).** One plugin dir, explicit
  `cli.json` entry; meters via the built-in client; cache state from session
  messages; renders into `sidebar.content`. Smallest surface, no secrets, no
  server code. Trade-off: experimental endpoint; mitigated by defensive
  parsing + quiet per-section unavailable states.
- **B — Server + TUI plugin with custom RPC** against the documented public
  Go usage API. Sturdier source, three files + credential handling for
  identical output. Fallback if the experimental endpoint proves unstable.
- Rejected: patching OpenCode (nix binary; slots exist for this); external
  widgets (user wants it inside the TUI).

## Agreed behavior

Panel sketch (append to `sidebar.content`, session view):

```
Go usage
  5h     10%  ▓░░░░░░░░░   resets 01:38
  week    7%  ▓░░░░░░░░░   resets Mon 00:00
  month   3%  ░░░░░░░░░░   resets Dec 22

Cache · qwen4-max
  HOT   ~3m 12s left (5m ttl)
  last call: 96% of input from cache
```

### Meters

- Percent + bar + reset time (local time, compact). Fractional percents round
  to whole numbers for display; `percent > 100` keeps the numeric value but
  clamps only the bar. `limited=true` is trusted independently of percent:
  error/warning color, prominent reset time.
- Invalid/past `resetsAt` → "reset unknown" + backed-off refresh; never
  render negative reset times.
- `go` absent → "no Go subscription" in the usage section only; cache section
  unaffected. Malformed individual meter → that meter shows unavailable,
  valid meters still render. Transport failure → quiet "usage unavailable".

### Cache state (per slot sessionID — never aggregate subagent sessions)

Identify the **last completed model call**: newest assistant message in this
session that is completed, non-error, with valid usage. In-progress, failed,
or aborted attempts never move the anchor. A tool loop is many model calls;
the newest completed one wins. Retries may share an older `time.created`,
making the countdown pessimistic — documented, not "fixed".

Classify from that call (newer evidence always overrides older anchors):

- **HOT** — it touched the cache (`read>0` or `write>0`) and
  `now - time.created < TTL`. Countdown = `TTL - elapsed`, shown as estimate
  (`~`, `(5m ttl)`). Each newer cache-touching completed call moves the
  anchor (sliding refresh).
- **COLD** — anchor touched the cache but elapsed ≥ TTL (show time since
  last use); or the current model/variant differs from the anchor call's
  (cache no longer applicable to the selection — not "destroyed"); or the
  last completed call reports zero cache tokens ("no cache on last call").
- **UNKNOWN** — calls exist but none report usable cache telemetry (provider
  doesn't report, or tokens missing/invalid); or a compaction happened after
  the anchor with no newer cache-touching call (prefix changed; wait for
  fresh evidence). Never claim HOT from stale evidence.
- Empty session → "no requests yet" (distinct from UNKNOWN).

Hit share = `cache.read / (input + cache.read + cache.write)` of the same
last completed model call; denominator must be finite and > 0, else show `—`.

### TTL resolution

`selected variant settings.cache.ttl > model > provider > plugin fallback`.
Use the anchor call's model/variant where available; a variant change that
affects cache settings must not reuse the old TTL. The `"5m"` fallback
(plugin option `cacheTtl`) applies **only to opencode-go**; for other
providers without an explicit TTL show UNKNOWN — no fabricated countdown.
Changing TTL config does not retroactively change an existing provider-side
cache entry (README note).

### Refresh mechanics

- Limits: fetch on mount, on terminal execution/usage events (not every
  streaming message update), on `server.connected`, and when a `resetsAt`
  passes. Debounce triggers; one in-flight request per location; ignore stale
  async completions after session/location changes; back off after failures.
  Limits state is shared across mounted slots (module-level), not per-slot
  polling.
- Messages: `message.sync(sessionID)` on mount and after reconnect; reactive
  list reads thereafter.
- Countdown: local ~1s tick, pure computation, no network.
- All timers, subscriptions, and pending work registered in the component's
  lifecycle with `onCleanup`. Task 1 probes hide/show, narrow-terminal
  auto-hide, route changes, and background tabs for a visibility signal; if
  one exists, pause work while hidden.

### Logging

Sanitized only: error name/code + operation. Never whole context/config/
provider objects, responses, requests, or headers (resolved credentials can
live there).

## Open question (for tobias)

If task 1 finds no reliable sidebar-visibility signal: is **"timers run only
while the slot is mounted, including while visually hidden"** acceptable?
Cost while hidden: one local computation per second + at most one small
local-server GET per minute; zero Go allowance. Recommendation: accept.

## Left to the builder

- Bar glyphs, spacing, reset-time formatting, color thresholds (e.g. warning
  ≥ 80%), via semantic theme tokens.
- Exact event names for terminal execution/usage triggers (from the V2 event
  schema); compaction detection from message history/events.
- Code layout that keeps classification/TTL/formatting as pure functions so
  they are unit-testable with a fake clock.
- README next to the plugin: what it shows, TTL assumption + precedence,
  `cacheTtl` option, limitations (warming invisible to history; provider
  eviction; system/tool/agent/prefix changes invalidate; retries pessimistic;
  TTL config not retroactive).

## Task 1 — runtime spike (de-risks everything else)

On the actual 2.3.0 TUI, verify: cli.json loading with options arriving;
exactly one slot mounted (auto-discovery duplicate check); direct
`client.experimental.usage.limits` call works from plugin context;
`message.sync/list` shape incl. tokens/time/model; catalog TTL shape via
`context.data.location.provider/model`; current model/variant access; slot
visibility behavior (hide/show, narrow terminal, route change, background
tab); behavior against a remote server. Findings feed back into this design
before further tasks.

## Verification

- Deterministic unit tests (fake clock) for: TTL precedence incl. variant;
  HOT boundary equality; zero denominator; write-only first request; latest
  zero-cache call overriding older anchor; failed/in-progress calls ignored;
  retries; multi-step tool loops; model/variant switch; compaction → UNKNOWN;
  empty session; malformed limits; absent `go`; fractional/>100 percents;
  invalid/past resetsAt; cleanup/reconnect resync.
- Runtime smoke: panel matches `opencode api get /api/experimental/usage/limits`;
  prompt → HOT with countdown near TTL; expired TTL (or tiny `cacheTtl`
  option) → COLD; injected endpoint failure → quiet unavailable state.
- No allowance consumption: spy network/model calls and assert no new
  session messages while idle (usage percents may legitimately drift from
  other clients or rolling-window decay — do not assert they stay constant).
