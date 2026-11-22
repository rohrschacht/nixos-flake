# Go Usage + Cache Sidebar Panel — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the three OpenCode Go usage meters and the current session's prompt-cache hot/cold state (with countdown) in the TUI's right sidebar.

**Architecture:** A TUI-only OpenCode plugin (`tui.tsx` + pure `logic.ts`) registered in `cli.json`. Meters come from the server's existing `client.experimental.usage.limits()`; cache state is computed from session message token telemetry. All classification/formatting/scheduling lives in pure, unit-tested functions; the TUI layer is thin wiring + rendering. One module-level, reference-counted orchestrator owns ALL timers and fetching, no matter how many slots are mounted.

**Tech Stack:** TypeScript, Solid JSX (OpenTUI), OpenCode V2 TUI plugin API (`@opencode/plugin/tui`, runtime-resolved), `node --test` (Node v24.22.3, native TS type stripping, zero deps).

**Spec:** `docs/superpowers/specs/2026-11-22-go-usage-sidebar-design.md` (in `/home/tobias/nixos`) — read it before starting; it is authoritative where this plan summarizes it.

## Global Constraints

- OpenCode **2.3.0** V2 plugin API only. Import `Plugin`/`usePlugin` from `@opencode/plugin/tui` and Solid from `solid-js` — OpenCode resolves these at runtime. NEVER use the stale `@opencode-ai/plugin@1.17.7` in `~/.config/opencode/node_modules` (V1 leftover).
- Plugin code lives in `~/.config/opencode/plugins/go-usage/` — its **own git repo** (initialized in Task 1). All code commits happen there. The nixos repo (`/home/tobias/nixos`) only holds spec/plan. No worktree needed: the plugin repo is brand new and isolated. **Every commit must leave the plugin loadable** (keep the temporary `spikeProbe` export until Task 4 removes its import).
- `~/.config/opencode/cli.json` must keep its existing `$schema` and `"theme": {"name": "opencode"}`; only add the `plugins` entry.
- The plugin must NEVER send model requests. Its only server call is `experimental.usage.limits`. Never handle/store/display/log API keys or tokens; never log whole options/config/provider/context objects, responses, requests, or headers. Logs: sanitized markers only — error name/code + operation, fetch count + reason, refcount.
- Pure logic (`logic.ts`): no OpenCode imports, no I/O, no global clock — `now` is always an explicit parameter. Tests: `TZ=UTC node --test logic.test.ts && TZ=America/New_York node --test logic.local.test.ts`; relative imports carry the `.ts` extension.
- **One orchestrator:** a module-level, location-aware, acquire/release reference-counted owner of all subscriptions and timers. First mounted slot starts them; last disposal stops them and invalidates pending generations. Steady state ≤ 1 limits fetch per 60s, event triggers debounced, one 1s tick — regardless of mounted slot count. Components only read shared state and own session-specific evidence. Hidden-but-mounted ticking is user-accepted (spec, Resolved question).
- The `"5m"` TTL fallback applies ONLY to provider `opencode-go`. Other providers without explicit TTL → UNKNOWN, never a fabricated countdown.
- Exact UI copy: headers `Go usage` and `Cache · <model id>`; states `no requests yet`, `reset unknown`, `no Go subscription`, `usage unavailable`, `no cache on last call`, `last call: N% of input from cache`.

## Review Focus

1. **A future OpenCode update changes the experimental endpoint shape** → panel shows quiet `usage unavailable`, TUI never crashes. (Task 2 garbage-input tests; Task 4 `debugFailLimits` smoke; Task 6 per-section degradation prompt test.)
2. **Streaming/in-flight calls during a tool loop** → unfinished calls never anchor the countdown; newest completed call with valid usage wins; no HOT claimed from stale evidence. (Task 3 in-progress/tool-loop/zero-cache/telemetry-skip tests.)
3. **Server restart/reconnect while the TUI stays open** → limits AND messages resync; no permanently stale panel. (Task 1 probe; Task 4 reconnect smoke; Task 5 reconnect smoke.)
4. **Narrow terminal / sidebar auto-hide / plugin reload / multiple session tabs** → exactly one fetch/tick schedule via refcounted orchestrator, timers cleaned up on last disposal, no duplicates. (Task 1 mount probes; Task 4 two-tab + reload smokes.)
5. **Non-Go provider or no Go subscription** → no fabricated countdown; each section degrades independently with the exact copy above. (Task 2 TTL/subscription tests; Task 3 ttl-undefined test.)

---

### Task 1: Runtime spike + scaffold

De-risks every unverified assumption on the actual 2.3.0 TUI before logic work starts. Deliverable: minimal plugin visibly mounted in the sidebar, probe evidence recorded, repo initialized.

**Files:**
- Create: `~/.config/opencode/plugins/go-usage/tui.tsx` (spike version)
- Create: `~/.config/opencode/plugins/go-usage/logic.ts` (stub: `export const spikeProbe = (): string => "logic-import-ok"`)
- Create: `~/.config/opencode/plugins/go-usage/SPIKE.md` (probe evidence)
- Modify: `~/.config/opencode/cli.json`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: repo + loading path proven; `SPIKE.md` records the real shapes Tasks 2–5 wire against: exact limits response envelope, message fields, catalog `settings.cache` paths, `ui.model.current()` shape, visibility behavior, event payload envelopes + session/location fields, relative-import resolution.

- [ ] **Step 1: Create plugin dir, git init, stub files**

```bash
mkdir -p ~/.config/opencode/plugins/go-usage
cd ~/.config/opencode/plugins/go-usage
git init
```

Create `logic.ts` with the stub above. Create `tui.tsx`:

```tsx
import { Plugin } from "@opencode/plugin/tui"
import { spikeProbe } from "./logic.ts"

export default Plugin.define({
  id: "go-usage",
  setup(context) {
    const options = context.options ?? {}
    return context.ui.slot({
      append: "sidebar.content",
      render: ({ sessionID }) => {
        console.log("[go-usage] render", sessionID)
        return (
          <box flexDirection="column">
            <text fg={context.theme.text.base}>go-usage spike · {spikeProbe()}</text>
            <text fg={context.theme.text.base}>cacheTtl={String(options.cacheTtl ?? "unset")}</text>
          </box>
        )
      },
    })
  },
})
```

Do NOT log the options object (it can contain secrets in general); the on-screen `cacheTtl` scalar probes option delivery. If `./logic.ts` fails to resolve at load, try `./logic`; record which worked in `SPIKE.md`. Add a `.gitignore` with `node_modules/`. Commit: `chore: spike scaffold`.

- [ ] **Step 2: Register in cli.json (preserve theme)**

Final content of `~/.config/opencode/cli.json`:

```json
{
  "$schema": "https://opencode.ai/v2/cli.json",
  "theme": { "name": "opencode" },
  "plugins": [{ "package": "./plugins/go-usage", "options": { "cacheTtl": "5m" } }]
}
```

If the relative package path does not load, use `"/home/tobias/.config/opencode/plugins/go-usage"` and record it. Config reloads without restart; open a fresh TUI in any project to be sure.

- [ ] **Step 3: Run the probe checklist in a live TUI session**

Extend the spike render (temporarily) to show each probe result on screen; use `console.log("[go-usage] …")` markers for lifecycle probes (check `~/.local/share/opencode/log/opencode.log`, role=cli, or on-screen counters if logs don't capture them). Record EVERY answer in `SPIKE.md`:

1. Slot visible in the right sidebar of a session? Exactly one instance (no duplicate from auto-discovery)? Options arrive (`cacheTtl=5m` shown)?
2. `await context.client.experimental.usage.limits({ location: context.location ?? context.data.location.default() })` — succeeds? Record the EXACT response envelope: is the resolved value the body `{location, data:{workspace, go, budgets}}` itself, or wrapped (e.g. `{data: body}`)? Paste a redacted copy. Compare with shell ground truth: `opencode api get /api/experimental/usage/limits`.
3. `await context.data.session.message.sync(sessionID)` then `.list(sessionID)` — assistant entries expose `time.created/completed`, `tokens.cache.read/write`, `model.{providerID,id,variant}`, `finish`, `error`? Any `type:"compaction"` entries, and their `status` field?
4. `context.data.location.provider.list(location)` / `.model.list(location)` — where does `settings.cache.ttl` appear (provider settings, model settings, `model.variants[].settings`)? Paste one redacted example (or "absent everywhere" — expected on this machine). Record how to match a model entry by BOTH `providerID` and `id`.
5. `context.ui.model.current()` — exact shape incl. `variant`? What does it return when no model is selected?
6. Visibility: hide the sidebar (narrow the terminal until it auto-hides, and any manual toggle), switch route home↔session, switch session A↔B, open two session tabs, background a tab — do render/setup/cleanup markers show unmount, or does it stay mounted? Is any visibility prop/signal available on the slot input? Does the slot's `sessionID` change while a component stays mounted?
7. Events: for EACH of `session.execution.succeeded`, `session.execution.failed`, `session.execution.interrupted`, `session.usage.updated`, `session.usage.recorded`, and `server.connected` — does `context.data.on(name, cb)` accept it, and what is the payload envelope (exact path to sessionID / location fields)? Fire them with a real prompt and a `opencode service restart` while the TUI is open; record one redacted payload per event. Record how unsubscribe works (returned function).
8. Reload plugin (config save / `/reload`) — old slot cleaned up, exactly one new instance?
9. Remote-server readiness: confirm the plugin uses only `context.client` / `context.location` (no hardcoded `127.0.0.1` or port); note in SPIKE.md that it is remote-compatible by construction (cli.json registration keeps TUI plugins active against remote servers).

- [ ] **Step 4: Gate decision**

STOP and report back (do not improvise) if ANY of these fail: probe 1 (slot/options loading), probe 2 (limits method in plugin context — approach B needs re-approval), probe 3 (message sync/list), probe 5 (current-model access). If terminal execution/usage events or `server.connected` are unavailable (probe 7), STOP and report — an explicit fallback (e.g. timer-only refresh) must be approved before Tasks 4–5. If probe 6 shows a usable visibility signal, note it — Tasks 4–5 must pause work while hidden. Otherwise proceed.

- [ ] **Step 5: Commit evidence**

```bash
git add SPIKE.md tui.tsx logic.ts .gitignore
git commit -m "chore: runtime spike evidence for opencode 2.3.0"
```

---

### Task 2: Pure logic — durations, TTL, meters, reset scheduling

**Files:**
- Create: `~/.config/opencode/plugins/go-usage/logic.ts` (replace stub, but KEEP `export const spikeProbe = (): string => "logic-import-ok"` until Task 4 removes its import — every commit must load)
- Test: `~/.config/opencode/plugins/go-usage/logic.test.ts`
- Test: `~/.config/opencode/plugins/go-usage/logic.local.test.ts` (local-time formatting, run under a non-UTC TZ)

**Interfaces:**
- Consumes: nothing external (pure module).
- Produces (Tasks 3–5 rely on these exact names/types):

```ts
export function parseDuration(text: string): number | undefined
export function resolveTtlMs(a: { providerID: string; variantTtl?: string; modelTtl?: string; providerTtl?: string; fallback: string }): number | undefined
export type MeterView = { valid: true; percent: number; barFraction: number; limited: boolean; resetsAt: number | null } | { valid: false }
export type LimitsView = { kind: "ok"; meters: { rolling: MeterView; weekly: MeterView; monthly: MeterView } } | { kind: "no-subscription" } | { kind: "unavailable" }
export function normalizeLimits(raw: unknown): LimitsView
export function formatReset(resetsAt: number | null, now: number): string
export function resetTimerDelay(resetsAt: number | null, now: number, minDelayMs: number): number | undefined
```

Pinned semantics:
- `parseDuration`: `^(\d+(?:\.\d+)?)(ms|s|m|h|d)$` → ms, else `undefined`.
- `resolveTtlMs`: try variant → model → provider (skip levels whose value is absent or unparseable), then `fallback` ONLY if `providerID === "opencode-go"` (parsed; invalid fallback → `undefined`), else `undefined`.
- `normalizeLimits(raw)`: expects the FULL body envelope `{location?, data:{workspace?, go?, budgets?}}` exactly as recorded in SPIKE.md. Object with `data` object but no `data.go` → `no-subscription`; anything else malformed → `unavailable`. A meter is invalid ONLY if it is not an object or its `percent` is missing/not finite/< 0. Otherwise: `percent: Math.round(percent)` (number kept even when > 100), `barFraction: Math.min(percent,100)/100`, `limited: Boolean(m.limited)` (independent of percent), `resetsAt` kept only if finite > 0, else `null`. One bad meter never sinks the others.
- `formatReset`: `null` or ≤ now → `"reset unknown"`; same LOCAL calendar day as now → `"HH:MM"` (24h); local date within now's date + 6 days → `"Ddd HH:MM"` (e.g. `Mon 00:00`); else `"Mon D"` (e.g. `Dec 22`). Uses local-time `Date` methods (never UTC getters).
- `resetTimerDelay`: `undefined` when `resetsAt` is null or ≤ now (past/invalid resets use the backoff/max-interval path, NEVER an immediate re-arm); else `Math.max(resetsAt - now, minDelayMs)`.

- [ ] **Step 1: Write failing tests**

`logic.test.ts` (node:test + assert/strict, imports from `./logic.ts`):

```ts
test("parseDuration units", () => {
  assert.equal(parseDuration("5m"), 300_000)
  assert.equal(parseDuration("1h"), 3_600_000)
  assert.equal(parseDuration("500ms"), 500)
  assert.equal(parseDuration("1.5m"), 90_000)
  assert.equal(parseDuration("24h"), 86_400_000)
  assert.equal(parseDuration("1d"), 86_400_000)
  assert.equal(parseDuration("bogus"), undefined)
  assert.equal(parseDuration("-5m"), undefined)
})
test("ttl precedence variant>model>provider>fallback", () => {
  const base = { providerID: "opencode-go", fallback: "5m" }
  assert.equal(resolveTtlMs({ ...base, variantTtl: "1h", modelTtl: "10m", providerTtl: "20m" }), 3_600_000)
  assert.equal(resolveTtlMs({ ...base, modelTtl: "10m", providerTtl: "20m" }), 600_000)
  assert.equal(resolveTtlMs({ ...base, providerTtl: "20m" }), 1_200_000)
  assert.equal(resolveTtlMs(base), 300_000)
  assert.equal(resolveTtlMs({ ...base, variantTtl: "junk", modelTtl: "10m" }), 600_000)
  assert.equal(resolveTtlMs({ ...base, variantTtl: "junk", modelTtl: "junk", providerTtl: "junk" }), 300_000)
  assert.equal(resolveTtlMs({ ...base, fallback: "10s" }), 10_000)   // fallback not hardcoded
  assert.equal(resolveTtlMs({ ...base, fallback: "junk" }), undefined)
})
test("5m fallback only for opencode-go", () => {
  assert.equal(resolveTtlMs({ providerID: "anthropic", fallback: "5m" }), undefined)
  assert.equal(resolveTtlMs({ providerID: "anthropic", fallback: "5m", providerTtl: "1h" }), 3_600_000)
})
test("normalizeLimits full envelope fixture", () => {
  const m = { percent: 10.4, limited: false, resetsAt: 1_795_397_925_000 }
  const v = normalizeLimits({ location: { directory: "/x" }, data: { workspace: { id: "w", usageURL: "u" }, go: { rolling: m, weekly: m, monthly: m }, budgets: [] } })
  assert.equal(v.kind, "ok")
  if (v.kind !== "ok") return
  assert.equal(v.meters.rolling.percent, 10)
  assert.equal(v.meters.rolling.barFraction, 0.104)
  assert.equal(v.meters.rolling.resetsAt, 1_795_397_925_000)
})
test("normalizeLimits degradation", () => {
  assert.equal(normalizeLimits({ data: {} }).kind, "no-subscription")
  assert.equal(normalizeLimits(null).kind, "unavailable")
  assert.equal(normalizeLimits({ data: { go: 42 } }).kind, "unavailable")
  assert.equal(normalizeLimits("garbage").kind, "unavailable")
  const v = normalizeLimits({ data: { go: { rolling: { percent: 150, limited: true, resetsAt: -1 }, weekly: { percent: "x" }, monthly: { percent: 3, limited: false, resetsAt: 5 } } } })
  assert.equal(v.kind, "ok")
  if (v.kind !== "ok") return
  assert.equal(v.meters.rolling.percent, 150)      // number kept
  assert.equal(v.meters.rolling.barFraction, 1)    // bar clamped
  assert.equal(v.meters.rolling.limited, true)
  assert.equal(v.meters.rolling.resetsAt, null)    // invalid → null
  assert.equal(v.meters.weekly.valid, false)       // one bad meter doesn't sink others
  assert.equal(v.meters.monthly.valid, true)
})
test("limited is independent of percent", () => {
  const v = normalizeLimits({ data: { go: { rolling: { percent: 1, limited: true, resetsAt: 5 }, weekly: { percent: 99, limited: false, resetsAt: 5 }, monthly: { percent: 0, limited: false, resetsAt: 5 } } } })
  assert.equal(v.kind, "ok")
  if (v.kind !== "ok") return
  assert.equal(v.meters.rolling.limited, true)
  assert.equal(v.meters.weekly.limited, false)
})
test("invalid percents invalidate only that meter", () => {
  for (const bad of [-5, NaN, Infinity]) {
    const v = normalizeLimits({ data: { go: { rolling: { percent: bad, limited: false, resetsAt: 5 }, weekly: { percent: 2, limited: false, resetsAt: 5 }, monthly: { percent: 3, limited: false, resetsAt: 5 } } } })
    assert.equal(v.kind, "ok")
    if (v.kind !== "ok") continue
    assert.equal(v.meters.rolling.valid, false)
    assert.equal(v.meters.weekly.valid, true)
  }
})
test("formatReset rules (TZ=UTC)", () => {
  const now = Date.UTC(2026, 10, 22, 12, 0) // Sun Nov 22 2026 12:00 UTC
  assert.equal(formatReset(null, now), "reset unknown")
  assert.equal(formatReset(now - 1, now), "reset unknown")
  assert.equal(formatReset(now, now), "reset unknown")
  assert.equal(formatReset(Date.UTC(2026, 10, 22, 15, 0), now), "15:00")
  assert.equal(formatReset(Date.UTC(2026, 10, 23, 0, 0), now), "Mon 00:00")
  assert.equal(formatReset(Date.UTC(2026, 10, 28, 12, 0), now), "Sat 12:00")  // +6 days boundary
  assert.equal(formatReset(Date.UTC(2026, 10, 29, 12, 0), now), "Nov 29")    // +7 days
  assert.equal(formatReset(Date.UTC(2026, 11, 22, 12, 43), now), "Dec 22")
})
test("resetTimerDelay never immediate for past/invalid", () => {
  const now = 1_000_000
  assert.equal(resetTimerDelay(null, now, 0), undefined)
  assert.equal(resetTimerDelay(now - 5, now, 0), undefined)
  assert.equal(resetTimerDelay(now, now, 0), undefined)
  assert.equal(resetTimerDelay(now + 60_000, now, 0), 60_000)
  assert.equal(resetTimerDelay(now + 5_000, now, 30_000), 30_000)  // clamped to backoff
})
```

`logic.local.test.ts` — same imports; pins LOCAL-time behavior (run under `TZ=America/New_York`; a UTC-only implementation fails these):

```ts
test("formatReset uses local time", () => {
  const now = Date.UTC(2026, 10, 22, 12, 0)          // 07:00 Nov 22 in NY
  assert.equal(formatReset(Date.UTC(2026, 10, 22, 15, 0), now), "10:00")
  assert.equal(formatReset(Date.UTC(2026, 10, 23, 0, 0), now), "19:00")   // still Nov 22 locally; UTC-only would say Mon 00:00
  assert.equal(formatReset(Date.UTC(2026, 10, 23, 5, 0), now), "Mon 00:00") // Nov 23 00:00 locally
})
```

- [ ] **Step 2: Run to verify failure**

Run: `cd ~/.config/opencode/plugins/go-usage && TZ=UTC node --test logic.test.ts`
Expected: FAIL — the test module fails on missing exports (static imports); that is an acceptable red stage.

- [ ] **Step 3: Implement the seven exports in `logic.ts`**

Signatures and pinned semantics above; bodies are the implementer's. No OpenCode imports, no `Date.now()` inside. Keep the temporary `spikeProbe` export.

- [ ] **Step 4: Run to verify pass**

Run: `TZ=UTC node --test logic.test.ts && TZ=America/New_York node --test logic.local.test.ts`
Expected: PASS, 0 fail in both.

- [ ] **Step 5: Commit**

```bash
git add logic.ts logic.test.ts logic.local.test.ts
git commit -m "feat: pure logic for durations, TTL, meters, and reset scheduling"
```

---

### Task 3: Pure logic — cache classification

**Files:**
- Modify: `~/.config/opencode/plugins/go-usage/logic.ts` (append; keep `spikeProbe`)
- Test: `~/.config/opencode/plugins/go-usage/logic.test.ts` (append)

**Interfaces:**
- Consumes: nothing from Task 2 at runtime (TTL arrives already resolved, as ms).
- Produces:

```ts
export type EvidenceMessage = {
  type: "assistant" | "compaction"
  created: number                 // time.created
  completed: boolean              // assistant: time.completed set, no error, finish !== "error"; compaction: status === "completed"
  running?: boolean               // compaction status === "running"
  failed?: boolean                // compaction status === "failed" → ignored entirely
  tokens?: { input: number; read: number; write: number }  // valid = present and all three finite ≥ 0
  model?: { providerID: string; id: string; variant?: string }
}
export type ModelRef = { providerID: string; id: string; variant?: string }
export type CacheView =
  | { state: "empty" }
  | { state: "unknown"; reason: string }
  | { state: "hot"; countdownMs: number; ttlMs: number; hitShare: number | null; model: ModelRef | undefined }
  | { state: "cold"; sinceMs: number; reason: "expired" | "model-changed" | "no-cache-on-last-call"; hitShare: number | null; model: ModelRef | undefined }
export function hitShareOf(tokens: EvidenceMessage["tokens"]): number | null
export function classifyCache(messages: EvidenceMessage[], opts: { now: number; ttlMs: number | undefined; currentModel: ModelRef | undefined }): CacheView
```

Pinned algorithm (order matters; spec-authoritative):
1. Ignore failed compactions and non-completed assistants entirely.
2. Let `lastCompleted` = last completed evidence (assistant or compaction) in array order. If a `running` compaction exists with `created > lastCompleted.created` (or there is no completed evidence but a running compaction exists) → `unknown` ("compaction in progress"). An OLDER running compaction does not block a newer valid call.
3. No messages at all → `empty`. Messages exist but no completed evidence → `unknown` ("no completed model call yet").
4. Select the call of record: let A = last completed ASSISTANT with valid tokens (assistants lacking valid tokens are SKIPPED, they do not erase an older valid anchor); let C = last completed COMPACTION. If C exists and (no A or `C.created > A.created`): C has valid tokens → record = C, else → `unknown` ("no cache telemetry after compaction"). Else if A exists → record = A. Else → `unknown` ("no cache telemetry").
5. `hitShareOf(record.tokens)`: denominator `input+read+write` finite > 0 → `read/denom`, else `null`.
6. If `currentModel` defined and differs from `record.model` (`providerID`, `id`, `variant ?? ""` strict) → `cold` reason `model-changed`, `sinceMs = now - record.created`. (Takes precedence over zero-cache and ttl checks.)
7. `read === 0 && write === 0` → `cold` reason `no-cache-on-last-call` (even when `ttlMs` is undefined).
8. `ttlMs === undefined` → `unknown` ("ttl unknown").
9. `elapsed = now - record.created`; `elapsed < ttlMs` → `hot` (`countdownMs = ttlMs - elapsed`); else `cold` reason `expired`. Boundary `elapsed === ttlMs` is COLD. Hot/cold carry `hitShare` and `model: record.model`.

- [ ] **Step 1: Write failing tests**

Append to `logic.test.ts`. Declare constants BEFORE the helper; the helper defaults to a fresh anchor:

```ts
const NOW = 1_000_000, TTL = 300_000
const CUR: ModelRef = { providerID: "opencode-go", id: "qwen4-max" }
const msg = (over: Partial<EvidenceMessage> = {}): EvidenceMessage => ({
  type: "assistant", created: NOW - 60_000, completed: true,
  tokens: { input: 100, read: 900, write: 0 }, model: { ...CUR }, ...over,
})
const opts = (over: Partial<{ now: number; ttlMs: number | undefined; currentModel: ModelRef | undefined }> = {}) =>
  ({ now: NOW, ttlMs: TTL, currentModel: CUR, ...over })
```

Named cases (each `test(...)`; assert state, reason, and the listed values):

- empty: `classifyCache([], opts())` → `empty`.
- hot: `[msg()]` → `hot`, `countdownMs: 240_000`, `hitShare: 0.9`, `model` deep-equals `{...CUR}`.
- boundary: `[msg({created: NOW - TTL})]` → `cold` `expired`, `sinceMs: TTL`.
- expired: `[msg({created: NOW - TTL - 1})]` → `cold` `expired`.
- write-only first request: `[msg({tokens:{input:500,read:0,write:500}})]` → `hot`.
- newer zero-cache overrides older anchor: `[msg(), msg({created: NOW-10_000, tokens:{input:900,read:0,write:0}})]` → `cold` `no-cache-on-last-call`, `hitShare: 0`.
- newer telemetry-less assistant SKIPPED: `[msg(), msg({created: NOW-10_000, tokens: undefined})]` → `hot` anchored on the older, `countdownMs: 240_000`.
- invalid telemetry skipped: `[msg(), msg({created: NOW-10_000, tokens:{input:-1,read:0,write:0}})]` → `hot`; same with `Infinity` read → `hot`; sole message with negative tokens → `unknown`.
- in-progress ignored: `[msg(), msg({created: NOW-1_000, completed:false})]` → `hot`.
- failed compaction ignored: `[msg(), {type:"compaction", created: NOW-1_000, completed:false, failed:true}]` → `hot`.
- running compaction newer: `[msg(), {type:"compaction", created: NOW-1_000, completed:false, running:true}]` → `unknown`.
- running compaction OLDER than valid call: `[{type:"compaction", created: NOW-120_000, completed:false, running:true}, msg()]` → `hot`.
- completed compaction with tokens is the record: `[msg({created: NOW-120_000}), {type:"compaction", created: NOW-30_000, completed:true, tokens:{input:50,read:400,write:100}, model:{...CUR}}]` → `hot`, `countdownMs: 270_000`.
- completed compaction without tokens (barrier): `[msg(), {type:"compaction", created: NOW-30_000, completed:true}]` → `unknown`.
- OLDER token-less compaction does not block: `[{type:"compaction", created: NOW-120_000, completed:true}, msg()]` → `hot`.
- tool loop: `[msg({created: NOW-120_000}), msg({created: NOW-60_000}), msg({created: NOW-5_000})]` → `hot`, `countdownMs: 295_000`.
- array-order selection (retry with older created LAST): `[msg({created: NOW-10_000}), msg({created: NOW-290_000})]` → `hot`, `countdownMs: 10_000` (last array element wins; pessimistic retries documented).
- model switch: `opts({currentModel:{providerID:"opencode-go",id:"kimi-k3"}})` → `cold` `model-changed`.
- model-changed precedence over zero-cache: `[msg({tokens:{input:900,read:0,write:0}})]` with switched model → `cold` `model-changed`.
- variant switch: anchor `model:{...CUR, variant:"max"}`, current `{...CUR}` → `cold` `model-changed`.
- currentModel undefined → model check skipped → `hot`.
- ttl undefined + cache activity → `unknown`.
- zero-cache + ttl undefined: `[msg({tokens:{input:900,read:0,write:0}})]`, `opts({ttlMs: undefined})` → `cold` `no-cache-on-last-call`.
- no telemetry at all: `[msg({tokens: undefined})]` → `unknown`; `[msg({completed:false})]` → `unknown` (not `empty`).
- hitShare guards: `hitShareOf(undefined) === null`; `hitShareOf({input:0,read:0,write:0}) === null`; `hitShareOf({input:NaN,read:1,write:0}) === null`.

- [ ] **Step 2: Run to verify failure**

Run: `TZ=UTC node --test logic.test.ts`
Expected: new tests fail OR the whole module fails on missing exports (acceptable red — Task 2's suite was green at its own commit). The final run in Step 4 must be entirely green.

- [ ] **Step 3: Implement `hitShareOf` + `classifyCache` in `logic.ts`**

Follow the pinned algorithm order exactly.

- [ ] **Step 4: Run to verify pass**

Run: `TZ=UTC node --test logic.test.ts && TZ=America/New_York node --test logic.local.test.ts`
Expected: PASS, 0 fail in both.

- [ ] **Step 5: Commit**

```bash
git add logic.ts logic.test.ts
git commit -m "feat: cache hot/cold/unknown classification with evidence precedence"
```

---

### Task 4: TUI wiring — orchestrator + Go usage meters section

**Files:**
- Modify: `~/.config/opencode/plugins/go-usage/tui.tsx` (replace spike render; remove `spikeProbe` import; KEEP lifecycle/fetch log markers until Task 6 verification)
- Modify: `~/.config/opencode/plugins/go-usage/logic.ts` (remove the temporary `spikeProbe` export)
- Modify: `~/.config/opencode/plugins/go-usage/SPIKE.md` (append wiring notes if shapes differed)

**Interfaces:**
- Consumes: `normalizeLimits`, `formatReset`, `resetTimerDelay`, `LimitsView`, `MeterView` (Task 2); ALL probe facts from `SPIKE.md` (Task 1) — especially the exact limits envelope and event payload paths.
- Produces: module-level shared state in `tui.tsx` that Task 5's component reads:

```ts
// module scope in tui.tsx
const [limits, setLimits] = createSignal<LimitsView>({ kind: "unavailable" })
const [now, setNow] = createSignal(Date.now())
// orchestrator: created in setup(); acquire()/release() refcount mounted slots;
// requestRefresh(reason) debounces into the single fetch loop.
```

Task 5 reads `limits`/`now`, calls `orchestrator.acquire()/release()` in its lifecycle, and must NOT add any fetch loop or tick timer of its own.

- [ ] **Step 1: Implement the refcounted orchestrator**

Module-level orchestrator created in `setup`, closing over the CURRENT context (re-read `context.client` at call time — it changes after restart). Location resolved at refresh time: `context.location ?? context.data.location.default()`; if the resolved location directory changes, bump the generation and reset backoff.

- `acquire()`: refs++; if refs === 1 → start subscriptions + timers, immediate refresh. `release()`: refs--; if refs === 0 → stop ALL timers/subscriptions, bump generation (invalidates pending fetches). Log markers: `[go-usage] acquire refs=<n>` / `release refs=<n>`.
- Fetch: skip if one is in flight; capture generation; call `context.client.experimental.usage.limits({ location })`; on success `setLimits(normalizeLimits(response))` where `response` is the EXACT envelope recorded in SPIKE.md (expected: the body `{location, data:{go…}}` itself — no `?? response` heuristic unwrapping); on failure set `{kind:"unavailable"}`, back off next allowed attempt 5s → 30s → 60s cap (reset on success); ignore stale-generation completions. Log `[go-usage] fetch #<n> <reason>` and, on failure only, `[go-usage] limits fetch failed: <error name/code>`.
- Triggers into `requestRefresh(reason)` (debounced ~2s, single-flight): mount/acquire; `context.data.on` for `session.execution.succeeded`, `session.execution.failed`, `session.execution.interrupted`, `session.usage.updated`, `session.usage.recorded` — filtered by the session/location payload paths recorded in SPIKE.md; `server.connected` if SPIKE.md proved it available; reset timer armed ONLY via `resetTimerDelay(nearestFutureResetsAt, now, nextAllowedAt - now)` (past/invalid resets → no reset timer; the backoff/max-interval path covers them); 60s max-interval timer. Re-arm the reset timer after each successful refresh.
- 1s tick: `setNow(Date.now())` — one timer, owned by the orchestrator, started/stopped with refs.
- Plugin option `debugFailLimits?: boolean` (default false) forces the failure path — used by smokes.
- Every subscription's unsubscribe and every timer handle is stored and cleared on last release.

- [ ] **Step 2: Render the meters section**

Replace the spike marker with a `Go usage` header + three rows (`5h`, `week`, `month`): rounded percent, 10-cell bar (`▓` filled / `░` empty from `barFraction`), `formatReset(meter.resetsAt, now())`; `limited` or percent ≥ 80 → theme warning/error token (semantic `context.theme` tokens). States: `no-subscription` → `no Go subscription`; `unavailable` → `usage unavailable`; invalid meter → that row shows `—` while others render. Slot component lifecycle: `orchestrator.acquire()` on mount, `release()` in `onCleanup`.

- [ ] **Step 3: Runtime smoke (record results in SPIKE.md, using the log markers)**

Fresh TUI in a session: (a) numbers match `opencode api get /api/experimental/usage/limits` taken at the same moment; (b) send a prompt → meters refresh within a few seconds of completion; (c) `"debugFailLimits": true` in cli.json options, reload → `usage unavailable`, TUI unaffected, no error spam; revert; (d) `opencode service restart` with TUI open → panel recovers; (e) narrow terminal until sidebar hides, then widen → still exactly one panel; fetch markers show ONE schedule; (f) `/reload` → old instance released (refs=0 marker), exactly one new instance; (g) open TWO session tabs → acquire markers show refs matching mounted slots but fetch/tick markers show ONE schedule; close one tab → other still live; close the last → refs=0 and no further fetch/tick markers.

- [ ] **Step 4: Commit**

```bash
git add tui.tsx logic.ts SPIKE.md
git commit -m "feat: refcounted orchestrator and live Go usage meters in sidebar"
```

---

### Task 5: TUI wiring — cache section

**Files:**
- Modify: `~/.config/opencode/plugins/go-usage/tui.tsx` (append cache section below meters)

**Interfaces:**
- Consumes: `classifyCache`, `resolveTtlMs`, `EvidenceMessage`, `CacheView`, `ModelRef` (Tasks 2–3); shared `limits`/`now` signals + orchestrator acquire/release (Task 4); `SPIKE.md` shapes for messages, catalogs, `ui.model.current()`.
- Produces: complete panel (both sections) — the shipped feature.

- [ ] **Step 1: Wire evidence + TTL (session-reactive)**

A reactive effect keyed by the slot's `sessionID`: on every change, `await context.data.session.message.sync(sessionID)` with a generation guard (ignore stale async completions from a previous sessionID), then read `context.data.session.message.list(sessionID)` reactively for the CURRENT id. Also re-sync after `server.connected` (orchestrator trigger or own subscription cleaned up in `onCleanup`). Map entries to `EvidenceMessage`: assistant → `completed = !!m.time.completed && !m.error && m.finish !== "error"`, `tokens = m.tokens && { input: m.tokens.input, read: m.tokens.cache.read, write: m.tokens.cache.write }`, `model = m.model`; compaction → `completed/running/failed` from `m.status`, same token/model mapping; skip other types.

TTL: `currentModel` from `context.ui.model.current()`; when undefined, use the classification's anchor `model` (CacheView.model) for catalog lookup — never fabricate Go fallback eligibility. Catalog lookup matches BOTH `providerID` and model `id` (paths per SPIKE.md): provider entry → `settings.cache.ttl`; model entry → `settings.cache.ttl`; variant settings from the model entry's `variants[]` matching the effective variant. `resolveTtlMs({ providerID, variantTtl, modelTtl, providerTtl, fallback: options.cacheTtl ?? "5m" })`. Recompute `classifyCache` reactively on message/model/`now` changes; the orchestrator's 1s tick drives the countdown. If SPIKE.md found a visibility signal, pause work while hidden.

- [ ] **Step 2: Render the cache section**

Header `Cache · <current model id>` (anchor model id when no selection). States: `hot` → `HOT  ~<m>m <s>s left (<ttl> ttl)` + `last call: N% of input from cache` (`hitShare` null → `last call: —`); `cold` → `COLD — <reason copy>` (`expired`: `last used Xm ago`; `model-changed`: `model changed`; `no-cache-on-last-call`: exact copy) + hit-share line; `unknown` → `UNKNOWN — <reason>`; `empty` → `no requests yet`. HOT in success/accent token, COLD muted, UNKNOWN warning — semantic theme tokens only. Lifecycle: orchestrator acquire/release exactly as the meters section (shared refcount).

- [ ] **Step 3: Runtime smoke (record in SPIKE.md)**

(a) Send a prompt → after completion: HOT with countdown near 5m and a hit-share %; (b) `"cacheTtl": "10s"` in options, reload, send a prompt → HOT ~10s, then COLD `expired` without further requests; revert to `5m`; (c) switch model mid-session (`/models`) → COLD `model changed`; (d) new empty session → `no requests yet`; switch session A↔B → evidence follows the session, never shows the other's; (e) leave panel idle 5 minutes → fetch markers ≤ 6, ALL reasons are limits refreshes (the plugin's only client call is `experimental.usage.limits` — confirm by code inspection), session message count unchanged (Go percents may drift from other clients — do not assert constant); (f) `opencode service restart` with TUI open → cache section recovers via message re-sync (not just limits); (g) compaction (`/compact` if available, else note as untested-with-reason) → UNKNOWN or fresh-evidence HOT, never stale HOT.

- [ ] **Step 4: Commit**

```bash
git add tui.tsx SPIKE.md
git commit -m "feat: cache hot/cold section with countdown and hit share"
```

---

### Task 6: README, verification, cleanup

**Files:**
- Create: `~/.config/opencode/plugins/go-usage/README.md`
- Modify: `~/.config/opencode/plugins/go-usage/tui.tsx` (remove spike remnants; markers removed LAST, after verification)

**Interfaces:**
- Consumes: everything above.
- Produces: shippable plugin + recorded acceptance evidence.

- [ ] **Step 1: Write README.md**

Contents: what the panel shows; data sources (server usage endpoint — experimental, may change; session token telemetry); TTL assumption (5m default for opencode-go only; precedence variant > model > provider > `cacheTtl` option; cli.json options example); limitations (warming requests invisible to history → pessimistic countdown; provider eviction and system/tool/agent/prefix changes invalidate; retries pessimistic; TTL config changes not retroactive; compaction without telemetry → UNKNOWN); `debugFailLimits` debug option; tests: `TZ=UTC node --test logic.test.ts && TZ=America/New_York node --test logic.local.test.ts`.

- [ ] **Step 2: Remove spike remnants (keep markers for now)**

Delete the spike probe render and the `spikeProbe` import/export if still present. KEEP lifecycle/fetch log markers and `debugFailLimits` — Step 3's checks depend on the markers.

- [ ] **Step 3: Full verification pass (record each item in SPIKE.md "Final verification")**

1. `TZ=UTC node --test logic.test.ts && TZ=America/New_York node --test logic.local.test.ts` → all PASS.
2. Re-run Task 4 smokes (a), (c), (d), (e), (f), (g) on the cleaned plugin — markers prove one schedule and full cleanup.
3. Re-run Task 5 smokes (a), (b), (e), (f).
4. Per-section degradation: with `debugFailLimits: true`, send a prompt → usage shows `usage unavailable` WHILE the cache section still flips to HOT with a fresh countdown; revert.
5. Any failure → fix and re-run before proceeding.

- [ ] **Step 4: Remove markers, final smoke, commit**

Remove the lifecycle/fetch console.log markers (keep sanitized failure logging and `debugFailLimits`). Quick smoke: panel renders both sections, no console noise.

```bash
git add README.md tui.tsx logic.ts SPIKE.md
git commit -m "docs: README and limitations; chore: remove spike scaffolding and markers"
```

- [ ] **Step 5: Report**

Summarize for the user: panel live, test count, smoke results, any SPIKE.md deviations from the design (these feed the whole-branch review).
