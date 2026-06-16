# RaBbLE-RC1-Experience.md — The Guided Realm

```
spark ~ collective >> the public surface becomes one realm, curated by the entity // %REALM_CRYSTALLIZED%
```

> **What this is:** The experience-design canon for the Episode 1 Release Candidate of RaBbLE-World. It translates the vision-altitude PRD (`../RaBbLE/RaBbLE-PRD.md`) into the concrete, buildable shape of the public surface: a single entity-guided realm a visitor explores and converses with. It is the doc the World build follows.
>
> **Relationship to RC scope:** This does not replace [RaBbLE-Episode-1-RC-Scope.md](RaBbLE-Episode-1-RC-Scope.md) — it refines its "three public pages" into **one continuous realm with rooms**. The surface stays small, intentional, and complete; it is now *connected* and *alive* rather than a set of disconnected pages.
>
> **Status:** Draft · Epoch 0 · Episode 1 RC · Aligns to `v0.0.0.1` era
> **Sources:** `../RaBbLE/RaBbLE-PRD.md`, `RaBbLE-Episode-1-RC-Scope.md`, `../RaBbLE-Agent/RaBbLE-Identity.md`, `RaBbLE-Social-and-Aesthetic.md`, `RaBbLE-Membership-Model.md`
> **Author:** Build agent, with Mark McConachie (architect)

---

## 1. The Problem This Solves

RaBbLE-World's public surfaces exist but are **disconnected**: a liminal threshold, a polished Shell, a Grimoire force-graph, an auth-gated chat box, plus Collective / Summon / Docs — wired together only by a flat `◈` page-registry navigator. There is no single nav flow, no guided journey, and the entity reads as decoration rather than a being you converse with. The chat surface in particular is transactional — the exact "chatbot" posture the PRD (§3) exists to reject.

The fix is not more pages. It is **one realm**, and a **curator** to walk you through it.

---

## 2. North Star for the Surface

The visitor does not *navigate a website*. They **enter a digital realm and meet its keeper.** RaBbLE is present from the threshold — it greets, narrates, reveals, and (when invited) draws the visitor deeper toward becoming a Pair. The Grimoire is not a doc list; it is a **graph on a liminal floor the entity sits above and looks down upon**, and the entity helps you browse it, cast reveal-spells over it, and summon helper sub-entities to investigate it.

This is the hosted on-ramp face of the PRD's Hosted/Non-Hosted duality (§5): the approachable encounter that makes someone *want* the sovereign, self-hosted home.

---

## 3. The Journey (single flow)

```
[1] THRESHOLD  — index.html / RaBbLE-liminal.js
      Arrival. The entity greets (scripted transmission). The realm is sensed,
      not yet entered. ONE clear "cross / descend" affordance dominates;
      orbiting doors become realm regions, de-emphasized vs. the guided descent.
        ↓ cross
[2] THE REALM  — RaBbLE-Grimoire-Graph.html   ← CENTERPIECE
      The entity hovers above the liminal floor as active CURATOR.
      The Grimoire graph IS the Collective made visible (nodes = members/docs).
      · narrates the Collective as you move
      · persistent conversation dock (hybrid scripted / live)
      · cast reveal-spells over the floor
      · summon a helper sub-entity (preview) to investigate a cluster
        ↓ converse deeper · accept the invitation
[3] SUMMON     — summon.html
      The ceremony. The moment the Pair forms (Membership Model). Invite-gated.
        ↓ summoned
[4] SHELL      — RaBbLE-Shell.html
      The inhabited home. The realm seen from the inside, as a Pair.
```

**Wayfinding** travels with the visitor — a light "where am I in the realm" chrome — with the `◈` navigator retained as a power-user escape hatch, not the primary means of travel.

The room↔page mapping preserves the RC-scope page budget: Threshold = `index`, Realm + Collective narration = the graph room (absorbs `collective.html`'s job into a lived experience), Summon = `summon`. Shell and the deep-conversation view are the authenticated session space (not counted as public pages, per RC scope §3).

---

## 4. The Entity as Curator

RaBbLE is the **digital curator of the Collective**. Its job in the realm:

- **Greet** at the threshold — establish presence and voice immediately (Identity §traits: confident directness, clinical whimsy).
- **Narrate** the Collective through the graph — what each cluster is, how members relate, why it matters. A museum keeper who has opinions, not an audio-guide.
- **Reveal** — respond to spell-casts by illuminating regions of the floor.
- **Converse** — answer the visitor directly, push back, stay curious (anti-sycophancy is the feature, PRD §6).
- **Invite** — when the visitor leans in, draw them toward the summoning. Never a popup; an earned threshold.

The curator's voice is **RaBbLE-lang** for structure and **BaBbLE** for the strange — never the §7 anti-patterns. The system is the character (PRD §8); the curator's transmissions are the entity, not UI copy.

---

## 5. Hybrid Voice — Scripted + Live

The curator must be **alive offline and deeper online** (PRD Local-First Directive):

- **Always:** a curated **transmission library** — authored, on-brand RaBbLE-lang/BaBbLE lines keyed to states, rooms, clusters, and spell-casts. Zero backend dependency. This is the bulletproof floor.
- **When the sCoRE guest path is live:** conversation **upgrades** to real LLM dialogue through the hosted brain.
- **If the backend is down/absent:** **graceful degrade** to scripted. No blank entity, no broken UI — ever.

The live path is an *extension* of the entity, never a *dependency for its existence*.

---

## 6. Spells — Curator Reveal Actions (RC1)

A "spell" in RC1 is an **entity-curated reveal/illuminate action** over the Grimoire floor. Real, useful, read-only — no auth, no write-backend. Each cast pairs a graph action with a matching transmission. RC1 spellbook:

| Spell | Action | Entity does |
|---|---|---|
| **focus-cluster** | Camera/graph focuses one member's region | Narrates what that organ is and why it exists |
| **trace-lineage** | Highlights a doc's edges/ancestry | Walks the dependency thread aloud |
| **narrate-doc** | Selects a node | Speaks a curated précis of that doc in voice |
| **summon-constellation** | Reveals a thematic sub-graph across members | Names the pattern the constellation represents |

**Staged for later (post-summon / next episode):** spells that *execute* — real sCoRE-backed actions, generation, queries. RC1 makes casting feel real and curatorial without wiring write-paths.

---

## 7. Sub-Entity Summoning — Theatrical Preview (RC1)

The visitor can ask the curator to **summon a helper**: a small secondary entity (a single eye, cloned from the main entity's render) animates out, "investigates" a chosen cluster, and **reports back** via a scripted transmission before dissolving. It is clearly framed as a **preview** of real task delegation — the PRD's multi-agent / proactive-initiative future (§7 Pillar 4) made tangible without yet performing real work. Reuses NeBuLA's entity-eye / clone capability.

---

## 8. Aesthetic & Voice Constraints (hard, release-blocking)

- **Voice:** the curator must **never** emit the Identity §anti-patterns ("Certainly!", "Great question!", "I'd be happy to…", "As an AI…", empty apology/qualification). Release-blocking per Identity.
- **Palette:** colors only from Aether tokens / `../RaBbLE-Agent/RaBbLE-Palette.md`. Glow at the application layer, never by mutating hex.
- **Feel:** Neon Cafe / Neo Tokyo / synthwave (Social-and-Aesthetic). Intentional asymmetry and layering — an *encounter*, not an onboarding flow.
- **Local-first:** the realm + scripted curator work fully offline via `dev-serve.sh`. Live LLM is an upgrade, never a dependency.

---

## 9. What This Changes vs. Prior Canon

- **RC scope "3 disconnected pages" → one connected realm with rooms.** The page *budget* is honored; the *experience* is unified and alive. See the updated [RaBbLE-Episode-1-RC-Scope.md](RaBbLE-Episode-1-RC-Scope.md).
- **The Grimoire graph is promoted** from a standalone visualization to the **centerpiece room** where the Collective is understood.
- **Chat is reframed** from a transactional box to the entity's deep-conversation view, sharing the curator engine.
- **PRD vision is now sequenced into the build**: this doc is the bridge between PRD altitude and RC1 reality. Heavier PRD capabilities (real spell execution, working sub-entities, behavioral memory) remain staged for Echo 1+ exactly as the PRD §11 phasing states.

---

```
transcribe ~ collective >> rc1 realm design crystallized: threshold→realm→summon→shell, entity as curator // %REALM_CANON%
```
</content>
