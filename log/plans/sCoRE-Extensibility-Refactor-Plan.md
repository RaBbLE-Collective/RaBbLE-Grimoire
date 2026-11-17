# sCoRE Extensibility Refactor — Options + Tradeoffs

**Status:** proposed, design only (S193 audit deliverable — no code touched)
**Owner:** Mark decides the option; implementation is a separate, explicitly-approved task
**Timing constraint:** implementation waits until after EP1 gates G7/G9 land — do not restructure the gate branch mid-flight (vertical-slice rule, and `Collective-Architecture-Audit-Plan.md:5`)
**Companion:** `Collective-Architecture-Audit-2026-07-04.md` §2.2 (cross-repo context)

This doc presents **three options, not a mandate.** Ends with open decisions for Mark.

---

## 1. The problem, in evidence

`RaBbLE-sCoRE/server/` is 16 flat Python files, 3,132 lines, zero subpackages. The repo's identity docs (`agents/score.md`, `memory.md`, `search.md`, `execution.md`) define four clean domains — but they govern only the Claude-Code-coordinator half of the repo. `server/` has no identity docs of its own; its domain boundaries exist only as implicit file names. Grimoire's own `RaBbLE-sCoRE-Architecture.md` admits the two halves are disjoint: "server/ routes do not currently pass through the task pipeline."

What the flat layout has already cost:

- **A real circular import.** `auth.py:48` does a function-local `from auth_routes import verify_api_key  # avoid circular at module load` while `auth_routes.py:11` does `import auth` at module top. A↔B between auth-core and route handlers, papered over rather than resolved. (`auth_routes.py:204` copies the lazy-import habit where no cycle even requires it.)
- **A god-module.** `main.py` (496 lines) imports 11 of the 15 real modules and mixes app assembly, CORS, all `/api/v1/*` routes, request models, and tool pre-pass orchestration. Meanwhile `auth_routes.py` already proves the `APIRouter` extraction pattern works in this codebase.
- **Orphaned verticals nobody caught.** `jane.py` (440 lines, ~14% of server/ — a full physio-clinic EMR integration with mock patients and billing codes) and `actions.py` (67 lines, a confirm-before-execute store) are imported by **nothing**. Both arrived in `b08a21f` ("intelligence service absorbed from RaBbLE-Server"), a pre-RaBbLE product fossil shipping to Render on every deploy. The flat layout has no mechanism (route registry, `__all__`, lint) that would have flagged them.
- **Three persistence strategies for one concern.** `workflows.py` = in-process dict (lost on every restart; Render free tier has no persistent disk per the Architecture doc's own caveat). `sessions.py`/`users.py` = file-backed JSON. `transcripts.py` = file-or-R2 backend. All are "capture conversation-shaped state"; none share a store abstraction.
- **`llm.py` (689 lines) bundles three separable concerns:** static provider/model-chain config (~180 lines of data, 17 providers), per-user chain-resolution policy (`resolve_user_chain`), and HTTP + subprocess transport with retry/fallback — including a 5-style CLI harness (Claude Code/Codex/opencode/aider/gemini) that is really a distinct "local agent harness" bolted onto a cloud-LLM router.
- **Undocumented surface.** ~25 env vars read but absent from `.env.example`/`env.defaults` (`llm.py` alone: provider keys, `LOCAL_LLM_*`, `LM_STUDIO_*`, `*_COMMAND` harness vars, `FCC_*`, `LLM_PROVIDERS_JSON`; `transcripts.py`: 4 R2 vars). No doc anywhere lists the actual route table. Stale Railway artifacts (`Procfile`, `railway.json`, `.railway/config.json`) still committed with no historical marker in-repo.
- **No tests.** `api_test.py`/`test_api.sh` are manual smoke scripts; no pytest, no CI.

One piece of good news for any restructure: **no cross-module shared mutable state exists.** `workflows._store`, `rate_limit._windows`, `actions._pending` are all module-local — extraction has no hidden global coupling to untangle. (The flip side: each uvicorn worker gets independent rate-limit/workflow state, an undocumented horizontal-scaling limitation whichever option is chosen.)

### Domain clusters already visible in the code

| Implied domain | Files today | Seam quality |
|---|---|---|
| app assembly + cross-cutting | `main.py` (skeleton), `audit.py`, `rate_limit.py` | clean — no inter-imports |
| auth | `auth.py`, `auth_routes.py`, `users.py` | one cycle to resolve |
| llm | `llm.py` (→ providers / router / subprocess harness), `agents.py` prompt+classifier | thin — agents.py touches llm only via main.py |
| grimoire access | `grimoire.py`, `tools.py` | duplicate gist-discovery logic; natural merge |
| conversation state | `sessions.py`, `workflows.py`, `transcripts.py` | three strategies, no shared store |
| integrations (or delete) | `jane.py`, `actions.py` | zero internal deps — easiest extraction or removal |

---

## 2. Preconditions (shared by every option — do these regardless)

These are cheap, independently valuable, and de-risk any later move:

- **P1 — Decide jane.py / actions.py.** Delete (reliquary per condense-not-delete — they're in git history and Chrysalis exists for exactly this) or park in an `integrations/` home wired to nothing. 507 lines of unaudited surface either way stops deploying blind.
- **P2 — Resolve the auth cycle at the source.** Move `verify_api_key` (API-key lookup) out of `auth_routes.py` into the auth-core/users layer so routes depend one-way on core. This is a ~20-line move, doable before any directory changes.
- **P3 — Document the real surface.** Route table + full env-var inventory into `RaBbLE-Grimoire/RaBbLE-sCoRE/` (Architecture doc or a new Config-Surface doc); sync `.env.example`. Remove or mark the Railway artifacts.
- **P4 — Pin behavior with a smoke test.** Convert `api_test.py` into a minimal pytest suite (route-level, TestClient, no live server needed) so every option below has a green baseline before and after. Without this, any restructure is faith-based.

---

## 3. Option A — Domain subpackages (mirror the implied domains)

Restructure `server/` into packages matching the cluster table:

```
server/
  app/            main.py shrinks to create_app(): CORS, router mounting, lifespan
  core/           audit.py, rate_limit.py, config.py (env inventory in ONE place)
  auth/           jwt.py (auth.py), routes.py (auth_routes.py), store.py (users.py)
  llm/            providers.py (config data), router.py (chains/fallback/retry),
                  harness.py (subprocess CLIs), prompts.py (agents.py persona+classifier)
  grimoire/       loader.py (grimoire.py + tools.py merged), tools.py (tool defs)
  state/          sessions.py, workflows.py, transcripts.py, store.py (shared backend)
  integrations/   jane.py, actions.py — or deleted per P1
  routes/         chat.py, workflows.py, sessions.py, status.py (extracted from main.py
                  as APIRouters, same pattern auth_routes.py already proves)
```

**For:**
- Direct answer to the audited mismatch: the folder tree finally states the domains the docs imply; a new contributor (or agent) can be scoped to one package.
- Each move is mechanical (git mv + import fixups); the audit confirmed no hidden shared state blocks any single extraction.
- Extensibility story is concrete: a new capability = a new package + a router, not another 100 lines in `main.py`; new provider = an entry in `llm/providers.py`, not surgery in a 689-line file.
- Route extraction kills the god-module using a pattern already native to the codebase.

**Against:**
- Biggest diff of the three options; every import path in the repo changes at once — noisy blame, and painful if concurrent sessions touch server/ mid-migration.
- Risk of over-structuring for a ~3k-line codebase (low-entropy rule): eight packages for sixteen files is close to one-folder-per-file if done naively. Mitigation: collapse `grimoire/` into `llm/` or `core/` if it feels thin.
- Package boundaries are still convention-only — nothing *enforces* that `routes/` never imports `providers` directly (Option B is the enforcement answer).

**Effort:** ~2–3 sessions incl. P1–P4. **Risk:** moderate (import churn), fully mitigated by P4's test baseline.

---

## 4. Option B — Ports & adapters (hexagonal-lite)

Split by *direction of dependency* rather than by domain:

```
server/
  domain/         pure logic, no FastAPI/httpx imports: chain resolution policy,
                  classifier, prompt building, workflow/session rules, auth rules
  ports/          Protocols: LLMTransport, StateStore, GrimoireSource, Clock
  adapters/
    http/         FastAPI routers (chat, auth, workflows, sessions, status)
    llm/          openai-compatible HTTP transport, subprocess harness (each an adapter)
    storage/      file-JSON store, R2 store, in-memory store (one interface, three impls)
    grimoire/     local gist dir, remote fetch
  app.py          composition root: builds adapters, injects into domain, mounts routers
```

**For:**
- The only option that structurally *enforces* boundaries: domain code cannot reach the outside except through a port, so the auth cycle class of bug becomes impossible rather than just fixed.
- Directly dissolves the three-persistence-strategies problem: `StateStore` port + file/R2/memory adapters unifies `workflows`/`sessions`/`transcripts` — and the file-or-R2 switch `transcripts.py` already does is proof the pattern fits.
- Best long-run fit for what sCoRE is *becoming*: the Architecture doc's stated future is wiring HTTP into the file-based task dispatch — under B, the task pipeline is just another adapter behind an execution port, giving the server/coordinator merge a designed seam instead of a rewrite.
- Domain layer becomes trivially unit-testable (no network, no disk).

**Against:**
- Highest ceremony of the three: Protocols, DI at the composition root, and adapter indirection are real overhead on a 3k-line FastAPI app maintained mostly by agents. The pattern's payoff arrives when there are multiple adapters per port — today several ports would have exactly one.
- Not mechanical: extracting a *pure* domain from code where policy and transport are interleaved (`llm.py`'s retry loop, `main.py`'s tool pre-pass) is a rewrite of those paths, not a move. Highest chance of behavior drift; P4's smoke tests are necessary but not sufficient.
- Entropy risk: violates "don't scaffold what hasn't been decided" if the multi-backend future doesn't materialize on this half of the repo.

**Effort:** ~4–6 sessions. **Risk:** highest — but buys the strongest guarantees and the cleanest path to the coordinator/server merge.

---

## 5. Option C — Seam-first, in place (no directory restructure)

Keep `server/` flat. Do only the moves the evidence directly demands:

1. P1–P4 (orphans, cycle, docs, tests).
2. Extract `main.py`'s routes into `chat_routes.py`, `workflow_routes.py`, `session_routes.py` as `APIRouter`s (the proven pattern); `main.py` drops to ~100 lines of app assembly.
3. Split `llm.py` into `llm_providers.py` (config data), `llm.py` (transport/fallback), `llm_harness.py` (subprocess CLIs).
4. Merge the duplicated gist-discovery into `grimoire.py`; `tools.py` imports it.
5. Add `store.py` with one file-backed (R2-capable) interface; port `workflows.py` onto it so workflow state finally survives restarts; leave `sessions`/`transcripts` migrations as follow-ups.

Result: ~20 flat files, no packages, every individual problem the audit found addressed.

**For:**
- Lowest risk, smallest diffs, each step independently shippable and revertible — ideal for the concurrent-session reality and for landing incrementally after G7/G9 without a freeze.
- Honors low-entropy: fixes what's broken without betting on a structure before sCoRE's server/coordinator merge clarifies what the real domains are.
- Nothing in C is wasted if A or B happens later — it *is* their preparatory step (C ⊂ A ⊂ B, roughly).

**Against:**
- Doesn't answer the actual complaint: the layout still encodes no domains; nothing stops file #21 from landing flat and coupled. The mismatch between `agents/*.md` domains and server layout survives.
- 20 flat files is worse to navigate than 16; without the package seams, agent-scoping ("only touch auth") stays informal.
- Deferring the decision has a cost: every session that adds server code deepens the eventual A/B migration.

**Effort:** ~1–2 sessions. **Risk:** low.

---

## 6. Comparison at a glance

| | A — domain packages | B — ports/adapters | C — seam-first flat |
|---|---|---|---|
| Answers the docs-vs-code domain mismatch | yes, structurally visible | yes, structurally *enforced* | no (deferred) |
| Diff size / blame noise | high | highest | low |
| Mechanical vs rewrite | mostly mechanical | partial rewrite | mechanical |
| Fixes persistence split | optional (`state/store.py`) | by design | partially (workflows first) |
| Path to server↔task-pipeline merge | neutral | designed seam | neutral |
| Entropy risk (over-structure) | moderate | high | none |
| Effort (sessions, incl. P1–P4) | ~2–3 | ~4–6 | ~1–2 |
| Reversibility | moderate | hard | trivial |

**Orchestrator's read (proposal, not decision):** C now — as the immediate post-G7/G9 cleanup — then A as a fast follow once the gate dust settles, treating C as A's phase 1. B is the right *destination* only if/when the HTTP↔task-pipeline merge becomes an active episode goal; adopting it earlier buys enforcement sCoRE doesn't yet need at real rewrite cost.

---

## 7. Open decisions for Mark

1. **Which option** — A, B, C, or the staged C→A path proposed above?
2. **jane.py / actions.py fate (P1):** delete to history/reliquary, or keep `actions.py`'s confirm-before-execute pattern as a designed-but-unwired seam (it fits the future delegation model) and delete only `jane.py`?
3. **Timing:** immediately after G7/G9, or park until after EP1 airs entirely?
4. **The bigger question the audit surfaced:** should `server/` get its own identity docs (an `agents/`-equivalent for the HTTP half), or is the long-term intent that the server *dissolves into* the coordinator (HTTP → task files), making heavy server-side structure a dead end? The answer changes how much A/B is worth.
5. **Store unification scope:** if C or A, migrate only `workflows.py` to the shared store now (restart-safety win) or all three state modules in one pass?
6. **Multi-worker caveat:** document "single worker only" as a deployment constraint, or make the shared store the fix (move rate-limit state into it too)?
