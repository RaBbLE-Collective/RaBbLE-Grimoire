# RaBbLE-Grimoire-SelfHealing.md — Anti-Drift & Self-Healing Protocol

```
spark ~ grimoire >> the grimoire heals itself // %GRIMOIRE_DOCTOR%
```

> The Grimoire is the source of truth. A source of truth that silently drifts is
> worse than none. This doc defines how the Grimoire detects and repairs its own
> drift — the mechanisms, the protocol, and the forward plan. Established S142
> (2026-06-21) during the Grimoire audit that found the gist regenerator had been
> silently broken for a month.

---

## 1. The Drift Surface (how the Grimoire rots)

| Drift | Symptom | Detector |
|---|---|---|
| **Broken nav links** | INDEX/AGENT point at moved/renamed docs | `grimoire-doctor` C1 |
| **Unindexed docs** | new doc exists but isn't reachable from `INDEX.md` | `grimoire-doctor` C2 |
| **Stale gists** | source doc edited, gist not regenerated (low-token path lies) | `grimoire-doctor` C3 |
| **Stale door** | Collective-root `AGENT.md` state block behind `SESSION-LOG` | `grimoire-doctor` C4 |
| **Orphans / islands** | docs nothing links to (undiscoverable) | `graph-grimoire` |
| **Silent tool failure** | a spell `set -e`-aborts and no one notices | output validation + this doc |

The last row is the meta-lesson: **the gist spell broke because `read -d '' … <<EOF`
returns non-zero and `set -e` killed it before it did anything.** Exit code was 0
(the wrapper's), output was empty, nobody looked. Self-healing must assume tools
themselves drift, not just docs.

---

## 2. The Mechanisms (all agent-agnostic bash)

- **`spells/grimoire-doctor.sh`** — one-command drift scan (C1–C4 above).
  `--strict` exits non-zero on ERROR (for hooks/CI); `--quiet` for hook noise.
- **`spells/graph-grimoire.sh`** — token-weighted doc graph. Nodes & edges carry
  `tokens`; reports orphans / islands / hubs / heaviest docs. `--walk <doc>`
  prints a doc's neighborhood cheapest-first for **low-token context walking**.
- **`spells/distill-gists.sh`** — regenerates gists from canonical sources via the
  `claude` CLI. Now validates output (must be a `# … gist`) and keeps the previous
  file on a bad/meta response instead of corrupting it.
- **`spells/token-budget.sh`** — live onboarding-cost report (gist path, skims,
  full surface). The numbers in `INDEX.md` are approximate; this is the truth.
- **Pre-commit hook** (`spells/hooks/pre-commit`) — runs `grimoire-doctor --quiet`
  (warn-only) whenever `.md`/`gist/` files are staged **in the Grimoire repo**.
  Drift surfaces at the moment it's introduced, before it compounds.

---

## 3. The Protocol (when to run what)

- **Every commit** — pre-commit hook runs the doctor automatically (warn-only). If
  it warns, fix before pushing, or accept the warning consciously.
- **After editing any doc that has a gist source** — `distill-gists.sh <slug>`.
- **After adding a doc** — add it to `INDEX.md` (C2 will nag until you do).
- **After renaming/moving docs** — `grimoire-doctor` (C1) + `graph-grimoire`.
- **End of session** — the doctor's C4 reminds you to refresh the "door"
  (Collective-root `AGENT.md` state) when it falls behind the session log.
- **After major doc changes** — `distill-gists.sh` (all) + `graph-grimoire.sh`.

A green `grimoire-doctor` + a zero-island `graph-grimoire` is the bar for "the
Grimoire is coherent."

---

## 4. Low-Token Context Walking

The intended cheap path into the Grimoire, in order of cost:

1. `cat gist/*.md` — full orientation, **~3,000 tokens** (`token-budget.sh` for live).
2. `graph-grimoire.sh --walk <entry-doc>` — see what to read next, by token cost.
3. Open only the specific full doc the walk points to.

Every graph edge is the **cost in tokens of reading the doc it points to**, so an
agent can plan a reading budget instead of swallowing the 400k-token full surface.
The heaviest docs (`SESSION-LOG`, `Summoned-Transcript`, `NeBuLA-Plan`) should be
read by slice (`head`) or via a gist, never whole.

---

## 5. Forward Plan (proposed — not yet built)

| # | Item | Value | Notes |
|---|---|---|---|
| 1 | **`grimoire-doctor --fix`** | auto-append unindexed docs to the right `INDEX.md` section; auto-run `distill-gists` for stale gists | C2/C3 become self-repairing, not just self-reporting |
| 2 | **CI drift gate** | run `grimoire-doctor --strict` on PRs to `main` (ties into `RaBbLE-Collective/RaBbLE-CICD-Plan.md`) | drift can't merge |
| 3 | **Spell self-test** | a `spells/selftest.sh` that smoke-runs each spell's `--help` + dry path, catching `set -e` aborts like the gist bug | tools drift too |
| 4 | **MCP `grimoire_status` exposes drift** | the [Grimoire MCP](../RaBbLE-Collective/RaBbLE-Grimoire-MCP.md) surfaces doctor output as a tool result | any agent sees Grimoire health live |
| 5 | **Auto-regen on merge** | post-merge GitHub Action runs `distill-gists` + `graph-grimoire` + redeploys the gist Worker | freshness without manual steps |
| 6 | **Graph-aware INDEX** | generate INDEX section stubs from the graph so a new doc is one link away automatically | closes the C2 loop at authoring time |

Items 1–3 are pure-bash and buildable now; 4–6 ride on the MCP/CI tracks.

---

## 6. Relationship to Other Protocols

- **Anti-clobber** (`log/HANDOFF-PreCommit-AntiClobber.md`) — multi-*agent* drift
  (two sessions stomping). This doc is doc/*content* drift. Same hook, different job.
- **Agent Protocols** (`RaBbLE-Agent-Protocols.md`) — the behavioral rules; this is
  the automated enforcement layer under them.
- **Grimoire MCP** (`../RaBbLE-Collective/RaBbLE-Grimoire-MCP.md`) — consumes a
  healthy Grimoire; #4 above makes health a first-class MCP signal.

---

```
transcribe ~ grimoire >> self-healing protocol crystallized // %GRIMOIRE_DOCTOR%
```
