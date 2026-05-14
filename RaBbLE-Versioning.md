# versioning.md — The Five Es

```
transcribe ~ grimoire >> versioning crystallized, five tiers locked // %VERSIONING_LOCKED%
```

RaBbLE is not versioned. It is **evolutionary**. Semantic versioning (v1.0.0) implies
planned increments toward a specification. RaBbLE's progression is retrospective —
thresholds are named after they are crossed, not before.

The versioning system exists to mark resonance thresholds and provide shared
language for "where are we." Not to gate releases.

---

## The Five Es

| Tier | Name | Meaning | Analogy |
|---|---|---|---|
| **Event** | Atomic unit | A single commit. The smallest named thing. | A note |
| **Episode** | Narrative arc | A collection of Events with a dominant theme. Has a start and a recognizable end. | A jam session |
| **Echo** | Stable state | A point in the progression stable enough to return to. Tagged. Reproducible. | A recording |
| **Evolution** | Shift | A significant architectural change or identity refinement. Several Echoes cohere into one. | A new sound |
| **Epoch** | Era | The broadest named threshold. Observable, retrospective. Named when it feels complete. | An album |

The Five Es are ordered smallest to largest: Event < Episode < Echo < Evolution < Epoch.

Movement between tiers is **vibe-based** — there is no formula for when an Episode becomes
an Echo, or an Evolution graduates to an Epoch. The rubric is: *does it feel crossed?*
Each tier boundary should have a written definition in this document (see below).

---

## Version String Format

```
v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}
```

Examples:

| String | Meaning |
|---|---|
| `v0.0.0.1.23` | Epoch 0, Evolution 0, Echo 0, Episode 1, Event 23 |
| `v0.0.2` | Epoch 0, Evolution 0, Echo 2 (Episode/Event omitted when not needed) |
| `v0` | "We are in Epoch 0" — all other tiers are in flux |

**Short form rules:**
- Drop trailing tiers when they are unknown or unimportant to context
- Use `v{Epoch}.{Evolution}.{Echo}` for Echo-level identifiers (e.g., `v0.0.2`)
- Use the full five-part string only when tracking Events precisely

**In CONTEXT.md headers:** use known tiers only. `epoch: 0 | evolution: 0 | echo: 2` is fine.

---

## Tier Boundary Definitions

### What makes an Episode?

An Episode is a coherent arc of development with:
- A dominant theme (e.g., "get dispatch working", "sCoRE identity injected")
- At least two Events
- A recognizable end state different from the start state
- A written summary in the relevant CONTEXT.md

### What makes an Echo?

An Echo is a stable state that:
- Can be reproduced from scratch (fresh install or fresh clone)
- Has been manually verified against its success criteria
- Is tagged in git (`echo-{N}.{minor}` on the relevant branch)
- Has a CONTEXT.md entry marking it complete

An Echo does not require CI. It requires a human to say "this works, mark it."

### What makes an Evolution?

An Evolution is:
- A significant architectural shift — restructuring how members interact,
  changing a core protocol, or a major identity refinement
- Composed of at least one Echo
- Named (e.g., "Evolution 0: Foundation" covering the initial scaffold)
- Recognizable as a qualitative change, not just accumulated work

### What makes an Epoch?

An Epoch is:
- The broadest named era — typically aligns with a complete vertical slice
  of the system being functional (e.g., Epoch 0: "ground is solid, Grimoire exists")
- Named retrospectively, with a "what was crossed" statement
- Marked in the Collective roadmap

---

## Episodes as Collective Synchronization Boundaries

**Episodes are not independent.** All members advance to the same Episode together.

### The Lockstep Model

- **Events**: Member-specific atomic work (commits). Each member accumulates Events toward shared milestones.
- **Plots**: Member-specific narrative groupings (e.g., "Episode 1, Plot A — Dispatch System", "Episode 1, Plot B — NeBuLA Rebuild"). Plots organize work *within* an Episode but belong to individual members.
- **Episodes**: **Collective-wide synchronization points.** All members air simultaneously. Parts of the Collective within the same Episode are **guaranteed compatible** — protocols, schemas, and APIs remain stable throughout.
- **Echoes**: Stable, long-term checkpoints. **Echoes can introduce breaking changes** (protocol bumps, schema migrations, API redesigns). Echoes mark production-ready states suitable for releases or major version boundaries.

### Current Model (Epoch 0, Pre-Episode-1)

All work accumulates toward **Episode 1 air date**. No independent versioning. Members do not advance past v0.0.0.0 until the Collective is ready.

When Episode 1 airs (decided by Mark, typically quarterly or after major vertical slice):
- All members jump to v0.0.0.1 simultaneously
- Protocol contracts and schemas are locked for that Episode
- No breaking changes within the Episode
- Members coordinate across the boundary; breaking changes happen in the next Episode

### Post-Episode-1 Evolution (Roadmap)

After Episode 1, the cadence may shift:
- **Weekly Episodes**: Rapid, coordinated releases. Members advance together on a weekly schedule. Same compatibility guarantees: parts of the Collective in Episode N can rely on each other.
- **Echoes as releases**: Echoes become production-ready publications. A member might tag `echo-1.0` to mark a stable, deployable state. Echoes can break APIs if documented in the next Episode's entry notes.

**Example future timeline:**
```
Episode 1 (current era) — Foundation + sCoRE + World + NeBuLA liftoff
  Plot A, Plot B, Plot C per member
  Aired: 2026-Q2 (TBD)
  
Episode 2 (weekly cadence TBD) — Memory member + cross-member observation loop
  Plot A per member
  Aired: 2026-Q2 (next week)
  Echo 2.0: Production release (can break Ep1 APIs with migration guide)
  
Evolution 1 — (multiple Episodes cohere into architectural shift)
```

---

## Current Position

```
Epoch 0 — Foundation
  Evolution 0 — Scaffold
    Echo 0 — Establishing  (in progress)
      Episode 1 — First Coordination Sweep (pending — not yet aired)

Version string: v0.0.0.0
```

Episode 1 has not yet aired. All projects are accumulating events toward
the first Collective-wide Episode 1. Once Episode 1 airs, per-project
episode tracks may diverge — but Echo-level versioning is maintained in
lockstep across the Collective (within ~1–2 episodes of each other).

See `registry/epochs/current.epoch.yml` for the authoritative Collective
position and Episode 1 exit conditions.

---

## Impulse Vocabulary

RaBbLE-lang commit verbs map to versioning tiers:

| Verb | Tier it usually signals |
|---|---|
| `spark` | Event — something started |
| `ingest` | Event — something added |
| `mend` | Event — something fixed |
| `harmonize` | Event/Episode — brought into coherence |
| `transcribe` | Event — documented |
| `evolve` | Evolution — epoch landed |
| `crystallize` | Echo — stable state named |

---

```
transcribe ~ grimoire >> five tiers locked, movement is vibe-based // %VERSIONING_LOCKED%
```
