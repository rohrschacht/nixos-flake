# Go Usage + Cache Sidebar Panel — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the three OpenCode Go usage meters and the current session's prompt-cache hot/cold state (with countdown) in the TUI's right sidebar.

**Architecture:** A TUI-only OpenCode plugin (`tui.tsx` + pure `logic.ts`) registered in `cli.json`. Meters come from the server's existing `client.experimental.usage.limits()`; cache state is computed from session message token telemetry. All classification/formatting lives in pure, unit-tested functions; the TUI layer is thin wiring + rendering.

**Tech Stack:** TypeScript, Solid JSX (OpenTUI), OpenCode V2 TUI plugin API (`@opencode/plugin/tui`, runtime-resolved), `node --test` (Node v24.22.3, native TS type stripping, zero deps).

**Spec:** `docs/superpowers/specs/2026-11-22-go-usage-sidebar-design.md` (in `/home/tobias/nixos`) — read it before starting; it carries the agreed behavior and the architect-reviewed edge cases.

## Global Constraints

- OpenCode **2.3.0** V2 plugin API only. Import `Plugin`/`usePlugin` from `@opencode/plugin/tui` and Solid from `solid-js` — OpenCode resolves these at runtime. NEVER use the stale `@opencode-ai/plugin@1.17.7` in `~/.config/opencode/node_modules` (V1 leftover).
- Plugin code lives in `~/.config/opencode/plugins/go-usage/` — its **own git repo** (initialized in Task 1). All code commits happen there. The nixos repo (`/home/tobias/nixos`) only holds spec/plan. No worktree needed: the plugin repo is brand new and isolated.
- `~/.config/opencode/cli.json` must keep its existing `$schema` and `"theme": {"name": "opencode"}`; only add the `plugins` entry.
- The plugin must NEVER send model requests, and never handle/store/display/log API keys or tokens. Logs: sanitized error name/code + operation only — never whole config/provider/context objects, responses, requests, or headers.
- Pure logic (`logic.ts`): no OpenCode imports, no I/O, no global clock — `now` is always an explicit parameter. Tests: `TZ=UTC node --test logic.test.ts`, relative imports carry the `.ts` extension.
- While mounted: steady-state ≤ 1 limits fetch per 60s, event triggers debounced, one 1s local countdown tick. Everything registered in component lifecycle with `onCleanup`. Hidden-but-mounted ticking is accepted by the user (spec, Resolved question).
- The `"5m"` TTL fallback applies ONLY to provider `opencode-go`. Other providers without explicit TTL → UNKNOWN, never a fabricated countdown.
- Exact UI copy: headers `Go usage` and `Cache · <model id>`; states `no requests yet`, `reset unknown`, `no Go subscription`, `usage unavailable`, `no cache on last call`, `last call: N% of input from cache`.

## Review Focus

1. **A future OpenCode update changes the experimental endpoint shape** → panel shows quiet `usage unavailable`, TUI never crashes. (Task 2 garbage-input tests; Task 4 `debugFailLimits` smoke.)
2. **Streaming/in-flight calls during a tool loop** → unfinished calls never anchor the countdown; newest completed call wins; no HOT claimed from stale evidence. (Task 3 in-progress/tool-loop/zero-cache tests.)
3. **Server restart/reconnect while the TUI stays open** → limits and messages resync; no permanently stale panel. (Task 1 probe; Task 4 reconnect smoke.)
4. **Narrow terminal / sidebar auto-hide / plugin reload** → exactly one slot instance, timers cleaned up on disposal, no duplicate fetch loops. (Task 1 mount-count probe; Tasks 4–5 cleanup + reload smoke.)
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
- Produces: repo + loading path proven; `SPIKE.md` records the real shapes Tasks 4–5 wire against (limits response, message fields, catalog `settings.cache`, `ui.model.current()`, visibility behavior, event availability, relative-import resolution).

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
    console.log("[go-usage] setup", JSON.stringify({ options }))
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

If `./logic.ts` fails to resolve at load, try `./logic`; record which worked in `SPIKE.md`. Add a `.gitignore` with `node_modules/`. Commit: `chore: spike scaffold`.

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
2. `await context.client.experimental.usage.limits({ location: context.location })` — succeeds? Paste the redacted response shape (it must contain `data.go.{rolling,weekly,monthly}` with `percent/limited/resetsAt`). Compare with shell ground truth: `opencode api get /api/experimental/usage/limits`.
3. `await context.data.session.message.sync(sessionID)` then `.list(sessionID)` — assistant entries expose `time.created/completed`, `tokens.cache.read/write`, `model.{providerID,id,variant}`, `finish`, `error`? Any `type:"compaction"` entries, and their `status` field?
4. `context.data.location.provider.list(location)` / `.model.list(location)` — where does `settings.cache.ttl` appear (provider settings, model settings, `model.variants[].settings`)? Paste one redacted example (or "absent everywhere" — expected on this machine).
5. `context.ui.model.current()` — exact shape incl. `variant`?
6. Visibility: hide the sidebar (narrow the terminal until it auto-hides, and any manual toggle), switch route home↔session, background the tab — do render/setup/cleanup markers show unmount, or does it stay mounted? Is any visibility prop/signal available on the slot input?
7. Events: does `context.data.on("server.connected", …)` type-check/fire (reconnect probe: `opencode service restart` while TUI open)? Do `session.execution.succeeded` and `session.usage.updated` fire after a prompt?
8. Reload plugin (config save / `/reload`) — old slot cleaned up, exactly one new instance?
9. Remote-server readiness: confirm the plugin uses only `context.client` / `context.location` (no hardcoded `127.0.0.1` or port); note in SPIKE.md that it is remote-compatible by construction (cli.json registration keeps TUI plugins active against remote servers).

- [ ] **Step 4: Gate decision**

If probe 2 fails (method not exposed in plugin context) → **STOP and report back**; approach B (server+RPC) needs re-approval, do not improvise. If probe 6 shows a usable visibility signal, note it — Tasks 4–5 must pause work while hidden. Otherwise proceed (hidden-but-mounted ticking is user-accepted).

- [ ] **Step 5: Commit evidence**

```bash
git add SPIKE.md tui.tsx logic.ts .gitignore
git commit -m "chore: runtime spike evidence for opencode 2.3.0"
```

---

### Task 2: Pure logic — durations, TTL, meters

**Files:**
- Create: `~/.config/opencode/plugins/go-usage/logic.ts` (replace stub)
- Test: `~/.config/opencode/plugins/go-usage/logic.test.ts`

**Interfaces:**
- Consumes: nothing external (pure module).
- Produces (Tasks 4–5 rely on these exact names/types):

```ts
export function parseDuration(text: string): number | undefined
export function resolveTtlMs(a: { providerID: string; variantTtl?: string; modelTtl?: string; providerTtl?: string; fallback: string }): number | undefined
export type MeterView = { valid: true; percent: number; barFraction: number; limited: boolean; resetsAt: number | null } | { valid: false }
export type LimitsView = { kind: "ok"; meters: { rolling: MeterView; weekly: MeterView; monthly: MeterView } } | { kind: "no-subscription" } | { kind: "unavailable" }
export function normalizeLimits(raw: unknown): LimitsView
export function formatReset(resetsAt: number | null, now: number): string
```

Pinned semantics: `parseDuration` accepts `^(\d+(?:\.\d+)?)(ms|s|m|h|d)$` → ms, else `undefined`. `resolveTtlMs` tries variant → model → provider (skip levels whose value is absent or unparseable), then `fallback` ONLY if `providerID === "opencode-go"`, else `undefined`. `normalizeLimits`: object with `data` object but no `data.go` → `no-subscription`; anything else malformed → `unavailable`; per meter: `percent` finite ≥ 0 → `percent: Math.round(percent)`, `barFraction: Math.min(percent,100)/100` (number kept even when >100), `limited` coerced boolean, `resetsAt` finite > 0 → kept else `null`; any missing/invalid field → that meter `{valid:false}` only. `formatReset`: `null` or ≤ now → `"reset unknown"`; same local calendar day → `"HH:MM"` (24h); within next 6 days → `"Ddd HH:MM"` (e.g. `Mon 00:00`); else `"Mon D"` (e.g. `Dec 22`).

- [ ] **Step 1: Write failing tests**

`logic.test.ts` (node:test + assert/strict, imports from `./logic.ts`). Cases with exact assertions:

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
  assert.equal(resolveTtlMs({ ...base, variantTtl: "junk", modelTtl: "10m" }), 600_000) // skip unparseable level
})
test("5m fallback only for opencode-go", () => {
  assert.equal(resolveTtlMs({ providerID: "anthropic", fallback: "5m" }), undefined)
  assert.equal(resolveTtlMs({ providerID: "anthropic", fallback: "5m", providerTtl: "1h" }), 3_600_000)
})
test("normalizeLimits happy path", () => {
  const m = { percent: 10.4, limited: false, resetsAt: 1_795_397_925_000 }
  const v = normalizeLimits({ data: { go: { rolling: m, weekly: m, monthly: m } } })
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
test("formatReset rules (TZ=UTC)", () => {
  const now = Date.UTC(2026, 10, 22, 12, 0) // Sun Nov 22 2026 12:00 UTC
  assert.equal(formatReset(null, now), "reset unknown")
  assert.equal(formatReset(now - 1, now), "reset unknown")
  assert.equal(formatReset(Date.UTC(2026, 10, 22, 15, 0), now), "15:00")
  assert.equal(formatReset(Date.UTC(2026, 10, 23, 0, 0), now), "Mon 00:00")
  assert.equal(formatReset(Date.UTC(2026, 11, 22, 12, 43), now), "Dec 22")
})
```

- [ ] **Step 2: Run to verify failure**

Run: `cd ~/.config/opencode/plugins/go-usage && TZ=UTC node --test logic.test.ts`
Expected: FAIL — exports not defined.

- [ ] **Step 3: Implement the six exports in `logic.ts`**

Signatures and pinned semantics above; bodies are the implementer's. No OpenCode imports, no `Date.now()` inside.

- [ ] **Step 4: Run to verify pass**

Run: `TZ=UTC node --test logic.test.ts`
Expected: PASS, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add logic.ts logic.test.ts
git commit -m "feat: pure logic for durations, TTL resolution, and usage meters"
```

---

### Task 3: Pure logic — cache classification

**Files:**
- Modify: `~/.config/opencode/plugins/go-usage/logic.ts` (append)
- Test: `~/.config/opencode/plugins/go-usage/logic.test.ts` (append)

**Interfaces:**
- Consumes: `parseDuration`/`resolveTtlMs` from Task 2 (TTL is passed in already resolved, as ms).
- Produces:

```ts
export type EvidenceMessage = {
  type: "assistant" | "compaction"
  created: number                 // time.created
  completed: boolean              // assistant: time.completed set, no error, finish !== "error"; compaction: status === "completed"
  running?: boolean               // compaction status === "running"
  failed?: boolean                // compaction status === "failed" → ignored entirely
  tokens?: { input: number; read: number; write: number }  // flattened; valid = all finite ≥ 0
  model?: { providerID: string; id: string; variant?: string }
}
export type CacheView =
  | { state: "empty" }
  | { state: "unknown"; reason: string }
  | { state: "hot"; countdownMs: number; ttlMs: number; hitShare: number | null }
  | { state: "cold"; sinceMs: number; reason: "expired" | "model-changed" | "no-cache-on-last-call"; hitShare: number | null }
export function hitShareOf(tokens: EvidenceMessage["tokens"]): number | null
export function classifyCache(messages: EvidenceMessage[], opts: { now: number; ttlMs: number | undefined; currentModel: { providerID: string; id: string; variant?: string } | undefined }): CacheView
```

Pinned algorithm (order matters):
1. Ignore failed compactions and non-completed assistants. A `running` compaction newer than the newest completed evidence → `unknown` ("compaction in progress").
2. No messages at all → `empty`. Messages exist but no completed evidence → `unknown` ("no completed model call yet").
3. Take the LAST completed evidence in array order (chronological) as the call of record. No valid tokens on it → `unknown` ("no cache telemetry").
4. `hitShareOf`: denominator `input+read+write` must be finite > 0 → `read/denom`, else `null`.
5. If `currentModel` defined and differs from the call's model (`providerID`, `id`, `variant ?? ""` strict) → `cold` reason `model-changed`, `sinceMs = now - created`.
6. `read === 0 && write === 0` → `cold` reason `no-cache-on-last-call`.
7. `ttlMs === undefined` → `unknown` ("ttl unknown").
8. `elapsed = now - created`; `elapsed < ttlMs` → `hot` with `countdownMs = ttlMs - elapsed`; else `cold` reason `expired`. Boundary `elapsed === ttlMs` is COLD. `hitShare` attached to hot/cold from step 4.

- [ ] **Step 1: Write failing tests**

Helper in the test file: `const msg = (over: Partial<EvidenceMessage> = {}): EvidenceMessage => ({ type: "assistant", created: 0, completed: true, tokens: { input: 100, read: 900, write: 0 }, model: { providerID: "opencode-go", id: "qwen4-max" }, ...over })`. `NOW = 1_000_000`, `TTL = 300_000`, `currentModel = { providerID: "opencode-go", id: "qwen4-max" }`. Cases (each a named `test(...)` with the asserted state/reason/values):

- empty: `classifyCache([], …)` → `empty`.
- hot: one msg `created: NOW - 60_000` → `hot`, `countdownMs: 240_000`, `hitShare: 0.9`.
- boundary: `created: NOW - TTL` → `cold` reason `expired`, `sinceMs: TTL`.
- expired: `created: NOW - TTL - 1` → `cold` `expired`.
- write-only first request: tokens `{input: 500, read: 0, write: 500}` → `hot`.
- newer zero-cache call overrides older anchor: `[msg({created: NOW-60_000}), msg({created: NOW-10_000, tokens:{input:900,read:0,write:0}})]` → `cold` `no-cache-on-last-call`, `hitShare: 0`.
- in-progress ignored: `[msg({created: NOW-60_000}), msg({created: NOW-1_000, completed: false})]` → `hot` anchored on the older.
- failed compaction ignored: `[msg({created: NOW-60_000}), {type:"compaction", created: NOW-1_000, completed:false, failed:true}]` → `hot`.
- running compaction: `[msg({created: NOW-60_000}), {type:"compaction", created: NOW-1_000, completed:false, running:true}]` → `unknown`.
- completed compaction with tokens becomes the call of record: `[msg({created: NOW-120_000}), {type:"compaction", created: NOW-30_000, completed:true, tokens:{input:50,read:400,write:100}, model:{providerID:"opencode-go",id:"qwen4-max"}}]` → `hot`, `countdownMs: 270_000`.
- completed compaction without tokens: same but `tokens: undefined` → `unknown`.
- tool loop: three completed msgs, newest `created: NOW-5_000` read>0 → `hot` anchored on newest.
- retries pessimistic: newest completed msg has older `created: NOW-290_000` → `hot` `countdownMs: 10_000` (documented behavior, not "fixed").
- model switch: `currentModel.id: "kimi-k3"` → `cold` `model-changed`.
- variant switch: anchor `model.variant: "max"`, current `variant: undefined` → `cold` `model-changed`.
- currentModel undefined → model check skipped, `hot`.
- ttl undefined + cache activity → `unknown`.
- no telemetry: only msg `tokens: undefined` → `unknown`; only msg `completed:false` → `unknown` (not `empty`).
- hitShare guards: `hitShareOf(undefined) === null`; `hitShareOf({input:0,read:0,write:0}) === null`; `hitShareOf({input:NaN as number,read:1,write:0}) === null`.

- [ ] **Step 2: Run to verify failure**

Run: `TZ=UTC node --test logic.test.ts`
Expected: new tests FAIL (exports missing); Task 2 tests still PASS.

- [ ] **Step 3: Implement `hitShareOf` + `classifyCache` in `logic.ts`**

Follow the pinned algorithm order exactly.

- [ ] **Step 4: Run to verify pass**

Run: `TZ=UTC node --test logic.test.ts`
Expected: PASS, 0 fail.

- [ ] **Step 5: Commit**

```bash
git add logic.ts logic.test.ts
git commit -m "feat: cache hot/cold/unknown classification with evidence precedence"
```

---

### Task 4: TUI wiring — Go usage meters section

**Files:**
- Modify: `~/.config/opencode/plugins/go-usage/tui.tsx` (replace spike render; keep probe code only until Task 6 cleanup)
- Modify: `~/.config/opencode/plugins/go-usage/SPIKE.md` (append wiring notes if shapes differed)

**Interfaces:**
- Consumes: `normalizeLimits`, `formatReset`, `LimitsView`, `MeterView` (Task 2); probe facts from `SPIKE.md` (Task 1).
- Produces: module-level shared state in `tui.tsx` that Task 5's component also reads:

```ts
// module scope in tui.tsx
const [limits, setLimits] = createSignal<LimitsView>({ kind: "unavailable" })
const [now, setNow] = createSignal(Date.now())   // 1s tick; timer lives in the component
let requestRefresh: (reason: string) => void = () => {}
// setup() assigns requestRefresh to the orchestration below, closing over the
// CURRENT context (re-read context.client at call time — it changes after restart)
```

(One in-flight fetch guard + generation counter live at module scope. Task 5 reads `limits`/`now` and must NOT add a second fetch loop.)

- [ ] **Step 1: Implement the shared fetch orchestration**

The function assigned to `requestRefresh` in `setup`: skip if a fetch is in flight; capture a generation id; call `context.client.experimental.usage.limits({ location })` (re-read `context.client` at call time); on success `setLimits(normalizeLimits(response.data ?? response))` (use the exact envelope proven in SPIKE.md); on failure set `{kind:"unavailable"}` and back off (next allowed attempt: 5s → 30s → 60s cap, reset on success); ignore completions from a stale generation. Log only `"[go-usage] limits fetch failed: <error name/code>"`. Add plugin option `debugFailLimits?: boolean` (default false) that forces the failure path — used by smoke tests.

Triggers (all debounced ~2s into one refresh, all inside the component lifecycle): on mount; `context.data.on("session.execution.succeeded" | "session.execution.failed" | "session.execution.interrupted" | "session.usage.updated" | "session.usage.recorded")` filtered to relevant sessions/location; `server.connected` if SPIKE.md proved it available; a timer at the nearest `resetsAt` (re-armed after each refresh); a 60s max-interval timer while mounted. `onCleanup` clears every timer and subscription.

- [ ] **Step 2: Render the meters section**

Replace the spike marker with a `Go usage` header + three rows (`5h`, `week`, `month`): rounded percent, 10-cell bar (`▓` filled / `░` empty from `barFraction`), `formatReset(meter.resetsAt, now)`; `limited` or percent ≥ 80 → theme warning/error token (use `context.theme` semantic tokens proven available; spike noted them). States: `no-subscription` → single line `no Go subscription`; `unavailable` → `usage unavailable`; invalid meter → that row shows `—` while others render. The 1s `now` tick signal is created here once and shared with Task 5's cache section.

- [ ] **Step 3: Runtime smoke (record results in SPIKE.md)**

Fresh TUI in a session: (a) numbers match `opencode api get /api/experimental/usage/limits` taken at the same moment; (b) send a prompt → meters refresh within a few seconds of completion; (c) set `"debugFailLimits": true` in cli.json options, reload → `usage unavailable`, TUI unaffected, no error spam in log; revert; (d) `opencode service restart` with TUI open → panel recovers (reconnect trigger); (e) narrow terminal until sidebar hides, then widen → still exactly one panel, one fetch loop (log markers); (f) `/reload` → old instance cleaned up.

- [ ] **Step 4: Commit**

```bash
git add tui.tsx SPIKE.md
git commit -m "feat: live Go usage meters in sidebar with guarded refresh"
```

---

### Task 5: TUI wiring — cache section

**Files:**
- Modify: `~/.config/opencode/plugins/go-usage/tui.tsx` (append cache section below meters)

**Interfaces:**
- Consumes: `classifyCache`, `resolveTtlMs`, `EvidenceMessage`, `CacheView` (Tasks 2–3); shared `limits`/`now` signals and the single fetch loop (Task 4); `SPIKE.md` shapes for messages, catalogs, `ui.model.current()`.
- Produces: complete panel (both sections) — the shipped feature.

- [ ] **Step 1: Wire evidence + TTL**

On mount and after reconnect: `await context.data.session.message.sync(sessionID)`; read `context.data.session.message.list(sessionID)` reactively. Map each entry to `EvidenceMessage`: assistant → `completed = !!m.time.completed && !m.error && m.finish !== "error"`, `tokens = m.tokens && { input: m.tokens.input, read: m.tokens.cache.read, write: m.tokens.cache.write }`, `model = m.model`; compaction → `completed/running/failed` from `m.status`, same token/model mapping; skip other types. TTL inputs: provider + model catalogs via `context.data.location.provider/model` (sync on mount), variant settings from the model entry's `variants[]` matching the current variant (exact paths per SPIKE.md); `resolveTtlMs({ providerID, variantTtl, modelTtl, providerTtl, fallback: options.cacheTtl ?? "5m" })`. `currentModel` from `context.ui.model.current()`. Recompute `classifyCache` reactively on message/model/tick changes; the 1s tick from Task 4 drives the countdown. If SPIKE.md found a visibility signal, pause tick+refresh while hidden.

- [ ] **Step 2: Render the cache section**

Header `Cache · <current model id>`. States: `hot` → `HOT  ~<m>m <s>s left (<ttl> ttl)` + `last call: N% of input from cache` (`hitShare` null → `last call: —`); `cold` → `COLD — <reason copy>` + time since (`expired`: `last used Xm ago`; `model-changed`: `model changed`; `no-cache-on-last-call`: exact copy) + hit-share line; `unknown` → `UNKNOWN — <reason>`; `empty` → `no requests yet`. HOT in success/accent token, COLD in muted, UNKNOWN in warning — semantic theme tokens only.

- [ ] **Step 3: Runtime smoke (record in SPIKE.md)**

(a) Send a prompt → after completion: HOT with countdown near 5m and a hit-share %; (b) set `"cacheTtl": "10s"` in options, reload, send a prompt → HOT ~10s, then COLD `expired` without further requests; revert to `5m`; (c) switch model mid-session (`/models`) → COLD `model changed`; (d) new empty session → `no requests yet`; (e) leave panel idle 5 minutes → no new session messages and no model requests (message count unchanged; Go percents may drift from other clients — do not assert constant); (f) compaction (`/compact` if available, else note as untested-with-reason) → UNKNOWN or fresh-evidence HOT, never stale HOT.

- [ ] **Step 4: Commit**

```bash
git add tui.tsx SPIKE.md
git commit -m "feat: cache hot/cold section with countdown and hit share"
```

---

### Task 6: README, cleanup, final verification

**Files:**
- Create: `~/.config/opencode/plugins/go-usage/README.md`
- Modify: `~/.config/opencode/plugins/go-usage/tui.tsx` (remove spike probe render/logging; keep `debugFailLimits`)

**Interfaces:**
- Consumes: everything above.
- Produces: shippable plugin + recorded acceptance evidence.

- [ ] **Step 1: Write README.md**

Contents: what the panel shows; data sources (server usage endpoint — experimental, may change; session token telemetry); TTL assumption (5m default for opencode-go only, precedence variant > model > provider > `cacheTtl` option, config example for cli.json options); limitations list (warming requests invisible to history → pessimistic countdown; provider eviction and system/tool/agent/prefix changes invalidate; retries pessimistic; TTL config changes not retroactive; compaction without telemetry → UNKNOWN); `debugFailLimits` debug option; how to run tests (`TZ=UTC node --test logic.test.ts`).

- [ ] **Step 2: Remove spike scaffolding**

Delete probe-only render lines and probe console.logs from `tui.tsx`; keep sanitized failure logging and `debugFailLimits`. Keep `SPIKE.md` as the evidence record.

- [ ] **Step 3: Full verification pass**

Run: `TZ=UTC node --test logic.test.ts` → all PASS. Then re-run Task 4 Step 3 (a,c,e) and Task 5 Step 3 (a,b,e) smokes on the cleaned plugin; record pass/fail per item in `SPIKE.md` (append "Final verification" section). Any failure → fix and re-run before committing.

- [ ] **Step 4: Commit**

```bash
git add README.md tui.tsx SPIKE.md
git commit -m "docs: README and limitations; chore: remove spike scaffolding"
```

- [ ] **Step 5: Report**

Summarize for the user: panel live, test count, smoke results, any SPIKE.md deviations from the design (these feed the whole-branch review).
