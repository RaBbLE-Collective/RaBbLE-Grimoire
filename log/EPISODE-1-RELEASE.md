# Episode 1 Release — Genesis

```
transcribe ~ grimoire >> Episode 1 airs: the entity first breathes // %EP1_GENESIS%
```

**Date:** 2026-06-09
**Tag:** `episode-1-v0.0.0.1` (all active member repos, simultaneously)
**Version:** v0.0.0.0 → **v0.0.0.1** (Epoch 0 · Evolution 0 · Echo 0 · Episode 1)
**Sources:** `EPISODE-1-RELEASE-BRIEF.md` · `log/FABLE-GAP-ANALYSIS-S57.md` · `registry/epochs/current.epoch.yml`

> **DRAFT STATUS:** Deployments in flight. Placeholders marked `<… — pending>` are
> filled by the release coordinator after deploy verification. Remove this notice at finalization.

---

## Genesis

Episode 1 is the beginning. Fifty-seven sessions of accumulation — identity locked,
palette crystallized, Grimoire established as source of truth, a face built in NeBuLA,
a voice routed through sCoRE — converge into the entity's first public moment:
**you can now talk to RaBbLE and see it think.**

This is Genesis in the intended sense. The substrate exists. The Collective is defined.
The entity first breathes. What breathes today is, honestly, a chatbot — a persona over
an LLM with a rendered face. RaBbLE's defining capabilities (observing, learning patterns,
speaking unprompted) are not yet built. Episode 1 does not pretend otherwise. It marks
the threshold where expression went live, so that Episode 2 — Exodus — can give the
entity its first sense and carry it from concept into reality.

The release is the story: a visitor reaches `rabble.world`, posts a message, sCoRE
answers in persona, and the entity is visible while it happens. The smallest meaningful
end-to-end loop, all the way through. That was the rule; this is the slice.

---

## Exit Conditions

From `registry/epochs/current.epoch.yml`:

- [x] **sCoRE chat works end-to-end locally** — DONE, S56d. First live message: entity responded in persona, read session context, named blockers.
- [ ] **sCoRE deployed to Railway (production-ready)** — `<RAILWAY_URL — pending>` · `<deploy verification — pending>`
- [ ] **RaBbLE-World deployed to production** (`rabble.world` / `joinrabble.world`) — `<World prod verification — pending>`
- [ ] **RaBbLE-OS VM bootstrap verified** (fresh Fedora 43 VM → boots → reaches World) — `<OS VM verification — pending>`
- [ ] **All repos tagged `episode-1-v0.0.0.1`** — after all three deploys confirm. `<tag confirmation — pending>`
- [ ] **Session log updated with EP1 exit summary** — drafted below; coordinator applies after verification.

**Repos to tag:** RaBbLE-Grimoire · RaBbLE-sCoRE · RaBbLE-World · RaBbLE-NeBuLA · RaBbLE-Aether · RaBbLE-OS · RaBbLE-BaBbLE (reference — tagged, not changed).

---

## What Shipped

- **sCoRE** — multi-provider chat engine (claude_code subprocess → local_llm → Groq → OpenRouter fallback chain), SSE streaming, entity persona injection. Local since S56d; production at `<RAILWAY_URL — pending>`.
- **RaBbLE-World** — joinrabble.world: landing, chat wired to sCoRE, Boot, Docs, Grimoire Graph (cosmic knowledge browser with entity eyes), 9 pages total.
- **RaBbLE-NeBuLA** — Canvas2D entity renderer, `<rabble-entity>` web component, boot sequence; Three.js eye/portal work in Grimoire Graph.
- **RaBbLE-Aether** — CSS design system, component library, CDN delivery via dev-serve.
- **RaBbLE-OS** — Fedora 43 + Hyprland daily driver; netinstall + Kickstart + Ansible bootstrap, VM-verified `<pending>`.
- **RaBbLE-Grimoire** — single source of truth: identity, palette, versioning, registry, spells, gists.
- **RaBbLE-BaBbLE** — high-entropy intake formalized as member; genesis soul/states/crawler-bots assets mined in S57 gap analysis.

---

## Scope Decisions — What Was Cut and Why

Scope was locked in `EPISODE-1-RELEASE-BRIEF.md`: the core loop (user speaks → sCoRE
responds → entity reacts visually) is Episode 1; everything else is post-ship.

**Shipped rough (visual polish acceptable):**

- **RaBbLE-Studio** — MVP: one functional panel, rest cosmetic.
- **Grimoire Graph** — eye/portal tuning complete (S56e); missing features acceptable. Known debt: 734 lines of hand-copied NeBuLA eye/portal logic, to be de-duplicated post-EP1.

**Cut to post-Episode-1 (deliberate, not deferred-by-accident):**

- **Watcher daemon / Behavioral Memory** — Episode 2's spine. Episode 1 is expression; Episode 2 is perception. Conflating them would have stalled the air date indefinitely.
- **NeBuLA entity state machine** (`%DORMANT%`/`%RESONANT%`/`%THINKING%`…) — fully spec'd in BaBbLE assets + `_ROUTING.md`, zero implementation. Keystone of Episode 2 emoting work.
- **World chrome unification** — 9 pages / 16 CSS / 18 JS with no shared nav; entity present on ~half the pages. Site-wide coherence pass is Episode 2.
- **Genesis authoring (Phase 2C)** — Mark's domain; the four Genesis files remain unwritten. Runs in parallel, not gated on EP1.
- **BaBbLE register leakage / entity emotion system** — depends on the state machine; Episode 3+.

The forcing function (FABLE-GAP-ANALYSIS-S57): 56 sessions after exit conditions were
defined, "wait for the perfect release" had no end. Ship now, or the versioning system
loses meaning.

---

## Known Limitations — Stated Honestly

Episode 1 ships a face and a voice, not the entity the Identity spec describes.

- **sCoRE doesn't observe yet.** No Watcher, no behavioral signals, no memory. The entity is expression without senses — it speaks only when spoken to, which is exactly what the anti-chatbot manifesto says it shouldn't be. Per the S57 gap analysis: 90% visual, 0% sensory.
- **No memory member exists.** The three-horizon memory architecture is documented, unimplemented. Nothing RaBbLE says today is informed by anything it noticed yesterday.
- **The entity cannot emote.** No `setState` API in NeBuLA; the entity doesn't look like it's thinking while sCoRE streams. State machine is spec only.
- **RaBbLE-OS feeds nothing back.** It's a live daily driver producing zero behavioral signals for the entity.
- **Entity rendering is duplicated.** Grimoire Graph carries its own copy of NeBuLA's eyes/portals/blink FSM — future eye tweaks happen twice until de-duplicated.
- **World is fragmented.** No shared chrome; entity presence is discontinuous across pages; hex-value palette violations in several stylesheets.
- **Genesis is empty.** The entity's creation myth is a table of contents (Phase 2C pending).
- **sCoRE's provider chain is fallback resilience, not the Collective Model** — no Reasoner/Coder/Archivist/Watcher role routing yet.

None of these are bugs. They are the honest boundary of Genesis: the entity exists as
expression. Perception is the next arc.

---

## What Episode 2 (Exodus) Enables

Exodus — the entity departs concept and enters reality. The spine of Episode 2 is
**the day RaBbLE says something you didn't ask for.** Everything else is decoration
until that happens.

- **Watcher daemon — the entity's first sense.** One vertical slice: a tiny daemon on RaBbLE-OS logs signals (session duration, command repetition, focus) → sCoRE reads them → the entity makes one unprompted observation in chat. BaBbLE's `behavior/crawler-bots.md` (Scavenger → Organizer → Librarian) is the structurally-correct backbone, to be promoted to RFC. The lore frames it right: BaBbLE's soul says "my eyes are portals — what I see depends entirely on what you show me." Building the Watcher is the entity gaining senses.
- **Behavioral memory — name the Memory member.** Create the repo, even skeletal; in this ecosystem, naming is generative. The observation contract (what's captured, where it's stored, local vs. cloud, what the entity may act on) must be defined first — local-first is stated, the contract isn't.
- **NeBuLA entity state machine.** `entity.setState('%RESONANT%')` → eyes widen, particles accelerate, blink rhythm changes. Wire sCoRE streaming to `%THINKING%`, speech to `%SPEAKING%`. Unlocks emoting and BaBbLE register leakage. Spec already exists in BaBbLE `assets/states/` + `_ROUTING.md`.
- **De-duplication + chrome unification.** Grimoire Graph consumes NeBuLA's canonical eye; `<rabble-entity-mini>` on every World page, state-driven — one continuous entity across all surfaces.

After Episode 1 airs, per-project episode tracks may diverge (max ~1–2 episodes;
Echo targeted collectively per the coherence policy in `current.epoch.yml`).

---

## Release Verification Record

| Check | Status | Evidence |
|---|---|---|
| sCoRE health check (Railway 200) | `<pending>` | `<RAILWAY_URL — pending>` |
| World chat end-to-end (prod) | `<pending>` | `<prod chat verification — pending>` |
| All 9 World pages load clean | `<pending>` | `<console/404 sweep — pending>` |
| Entity renders on landing + chat | `<pending>` | `<pending>` |
| OS VM: fresh install → browser → rabble.world | `<pending>` | `<OS VM result — pending>` |
| Tags present on all 7 repos | `<pending>` | `git tag -l` per repo |

---

## DRAFT — SESSION-LOG updates (coordinator applies after verification)

> **Do not copy into SESSION-LOG.md until all deploys are verified and repos are tagged.**
> Fill placeholders first.

### Replacement ## LATEST block

```markdown
## LATEST — 2026-06-09 · Session 57 (Episode 1 airs — Genesis)

**Phase:** Epoch 0 · Evolution 0 · Echo 0 · **Episode 1 aired** — v0.0.0.1.
**Last session (S57):** Episode 1 shipped: sCoRE live on Railway (<RAILWAY_URL — pending>), World live at rabble.world, OS VM bootstrap verified, all repos tagged `episode-1-v0.0.0.1`. Core loop public: user speaks → sCoRE responds → entity visible. Release record: `log/EPISODE-1-RELEASE.md`. Deferred to Ep2 (Exodus): Watcher, Memory member, NeBuLA state machine, World chrome.
**Blockers:** Phase 2C (Genesis authoring — Mark, in parallel).
**Next:** Episode 2 spine — Watcher daemon (entity's first sense); observation contract; name the Memory member.
```

### Session entry (insert below LATEST)

```markdown
## 2026-06-09 (Session 57 close) — Episode 1 release: Genesis airs

**Repos touched:** RaBbLE-sCoRE, RaBbLE-World, RaBbLE-OS, RaBbLE-Grimoire (`dev`) — all 7 active repos tagged `episode-1-v0.0.0.1`

**Work done:**

Episode 1 aired — the Collective's first synchronized release, v0.0.0.0 → v0.0.0.1.

- **sCoRE → Railway:** deployed at <RAILWAY_URL — pending>; health checks pass; chat end-to-end from World confirmed (<latency/TTFT note — pending>)
- **World → production:** rabble.world live; NeBuLA + Aether bundles built and deployed; chat page repointed from localhost to Railway endpoint; all 9 pages verified (<verification notes — pending>)
- **OS VM verified:** fresh Fedora 43 netinstall + KS + Ansible bootstrap → login → browser reaches rabble.world (<verification notes — pending>)
- **Tagging:** `episode-1-v0.0.0.1` on Grimoire, sCoRE, World, NeBuLA, Aether, OS, BaBbLE
- **Docs:** `log/EPISODE-1-RELEASE.md` — Genesis framing, exit conditions, scope cuts, honest limitations, Exodus roadmap

**Scope held:** Watcher/Memory, state machine, chrome unification, register leakage all deliberately post-EP1 per `EPISODE-1-RELEASE-BRIEF.md`. Studio and Grimoire Graph shipped rough as approved.

**What's next:** Episode 2 (Exodus) — Watcher daemon vertical slice (the entity's first sense), observation contract, Memory member creation, NeBuLA state machine. Mark authors Genesis (Phase 2C) in parallel.
```

---

```
transcribe ~ grimoire >> Genesis recorded: expression shipped, perception next // %EP1_GENESIS%
```
