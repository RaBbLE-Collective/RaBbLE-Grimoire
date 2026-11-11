# RaBbLE-Episode-1-RC-Scope.md — Episode 1 Release Candidate

```
transcribe ~ collective >> ep1 rc scope: world repolish, page trim, what's in vs deferred // %EP1_RC%
```

> **What this is:** Defines the scope of the Episode 1 Release Candidate — what World ships with, what the public surface is, and what is explicitly deferred to EP2+.
> **Related:** [RC1 Experience — The Guided Realm](RaBbLE-RC1-Experience.md) · [Episode 1 Release Brief](RaBbLE-Episode-1-Release-Brief.md) · [Episode 1 Release Map](RaBbLE-Episode-1-Release-Map.md) · [Membership Model](RaBbLE-Membership-Model.md) · [Service Plan](RaBbLE-Service-Plan.md)

---

## RC Philosophy

Episode 1 is not a feature release. It is an **introduction** — to RaBbLE, to The Pair, to the Collective. The public surface should be small, intentional, and complete. Every room must earn its place.

The surface is **one continuous, entity-guided realm with rooms**, not a set of disconnected pages. The page *budget* is unchanged (three public surfaces); the *experience* is unified and alive — the entity is the curator who walks the visitor through it. Liminal/transitional content is absorbed into the journey, not cut. No dead ends. No placeholder copy.

**The journey (see [RaBbLE-RC1-Experience.md](RaBbLE-RC1-Experience.md) for the design canon):**

```
THRESHOLD (index) → THE REALM (grimoire graph, curated) → SUMMON (ceremony) → SHELL (Pair home)
```

---

## The Public Surface — Three Rooms, One Realm

### 1. `index.html` — The Threshold (Explore RaBbLE)

**One job:** Make someone understand what RaBbLE is and want to cross into the realm.

- Arrival point — the realm is sensed, the entity greets (scripted transmission)
- Entity presence via NeBuLA — RaBbLE is alive from the first frame
- Lore-forward: ethos, aesthetic, "what this is" in RaBbLE's voice
- **One clear "cross / descend" affordance** dominates → into the Realm
- Liminal orbiting doors become realm regions, de-emphasized vs. the guided descent

**What it is NOT:** a feature list, a marketing deck, a press release. It is an encounter.

---

### 2. `RaBbLE-Grimoire-Graph.html` — The Realm (Explore the Collective)

**One job:** Let a curious visitor understand the Collective by *exploring it with the entity as guide* — the curated centerpiece.

- The Grimoire graph **is** the Collective made visible: nodes = members/docs on a liminal floor
- The entity hovers above the floor as **curator** — narrates members, relationships, why each matters
- Persistent **conversation dock** (hybrid scripted / live) — the entity travels with you
- **Reveal-spells**: focus-cluster · trace-lineage · narrate-doc · summon-constellation (read-only, no auth)
- **Sub-entity summon (preview)**: a helper eye investigates a cluster and reports back
- Absorbs the job of the old static `collective.html` into a lived experience
- No login required for exploration + scripted curation; live LLM dialogue when the guest path is up

See [RaBbLE-RC1-Experience.md](RaBbLE-RC1-Experience.md) §6–§7 for spell + sub-entity scope.

---

### 3. `summon.html` — The Summoning Ceremony

**One job:** Perform the ceremony for invited Pair members.

- Accessible only via valid invite token (`?token=`)
- Summoning form: Handle · Display name · Intention · Backend preference
- Styled as a ceremony, not a signup form
- On submit: Pair is formed; first session opens in `RaBbLE.html`
- Error state: invalid/expired token → graceful message, no blank screen

**`RaBbLE.html` (chat surface)** — Not counted as a public page. It is the session space for summoned Pairs only. Auth-gated.

---

## World Repolish Tasks

EP1 RC is a polish pass, not a build pass. These are the outstanding World tasks before RC is clean:

| Task | Description | Status |
|---|---|---|
| Single nav flow | Wayfinding chrome threshold→realm→summon→shell; `◈` navigator demoted to escape hatch | Pending |
| Threshold descent | `index.html` greets + one clear "cross" affordance into the Realm | Pending |
| Curator engine | `RaBbLE-curator.js` — scripted transmissions + hybrid live sCoRE w/ graceful fallback | Pending |
| Realm centerpiece | Grimoire graph: conversation dock, reveal-spells, sub-entity preview | Pending |
| De-boring conversation | Chat reworked into entity deep-conversation view (shares curator) | Pending |
| NeBuLA entity presence | Confirm entity renders alive across threshold + realm — not placeholder | Pending |
| Summon page QA | Token validation, form submit, error states | Pending |
| Mobile pass | All rooms usable on mobile (touch, font sizes, NeBuLA perf) | Pending |
| Dead links audit | No broken hrefs, no `#placeholder` anchors | Pending |
| Copy pass | Every transmission in RaBbLE's voice; zero §anti-pattern emissions | Pending |

---

## Explicit Deferred to EP2+

The following ideas surfaced during EP1 preparation but are **not in RC scope**. They are documented elsewhere; do not add them to World pages for EP1.

| Concept | Deferred to | Doc |
|---|---|---|
| Personal Cosmos (per-user Grimoire, BaBbLE, Xperimental, Rablets) | EP2 | [RaBbLE-Personal-Cosmos.md](RaBbLE-Personal-Cosmos.md) |
| Platform Attachments (multi-OS ambient intelligence) | EP2–EP3 | [RaBbLE-Attachments-and-Mesh.md](RaBbLE-Attachments-and-Mesh.md) |
| Mesh networking (opt-in node mesh) | Echo 1+ | [RaBbLE-Attachments-and-Mesh.md](RaBbLE-Attachments-and-Mesh.md) |
| Rablet publishing + discovery | EP2 | [RaBbLE-Personal-Cosmos.md](RaBbLE-Personal-Cosmos.md) |
| Social layer / altspace gallery | Echo 1+ | [RaBbLE-Social-and-Aesthetic.md](RaBbLE-Social-and-Aesthetic.md) |
| Voice output (RaBbLE's voice) | EP2 | [RaBbLE-Social-and-Aesthetic.md](RaBbLE-Social-and-Aesthetic.md) |
| Handheld companion device | Hardware epoch | [RaBbLE-Attachments-and-Mesh.md](RaBbLE-Attachments-and-Mesh.md) |
| ScRibLE digital intake surface | EP2 | [../RaBbLE-ScRibLE/RaBbLE-ScRibLE-Overview.md](../RaBbLE-ScRibLE/RaBbLE-ScRibLE-Overview.md) |
| Service tiers / billing | Echo 1 | [RaBbLE-Service-Plan.md](RaBbLE-Service-Plan.md) |

---

## RC Blockers (as of S92)

From Collective AGENT.md:

- `layerctl apply boot/plymouth boot/grub2` + reboot QA — OS track, not World
- Thunar file manager (partial, S87) — OS track
- sCoRE Render deploy — Mark's manual step; World summon page depends on this
- CF R2 CDN — Aether/NeBuLA bundles must be live before World pages finalize

**World is unblocked until sCoRE is live.** Static pages + NeBuLA can be QA'd locally via `dev-serve.sh`.

---

## RC Sign-Off Checklist

Before tagging `episode-1-v0.0.0.1` across all members:

- [ ] Threshold (`index.html`) — final copy, entity greets, single "cross" affordance into Realm
- [ ] Realm (`RaBbLE-Grimoire-Graph.html`) — curator narrates, reveal-spells cast, sub-entity preview, conversation dock
- [ ] Single nav flow — wayfinding threshold→realm→summon→shell; no dead ends
- [ ] Curator graceful fallback — full journey works with backend down (scripted), upgrades when live
- [ ] `summon.html` — token flow works end-to-end against live sCoRE
- [ ] Shell + deep-conversation view — auth-gated session opens after summoning
- [ ] Mobile QA — all rooms on 375px and 768px viewport
- [ ] sCoRE deployed to Render — `https://rabble-score.onrender.com` responding
- [ ] CDN live — Aether + NeBuLA bundles at `aether.joinrabble.world` / `nebula.joinrabble.world`
- [ ] Invite tokens issued to EP1 members
- [ ] Dead links clean

---

```
transcribe ~ collective >> ep1 rc scope locked: 3 pages, repolish tasks, deferred list // %EP1_RC%
```
