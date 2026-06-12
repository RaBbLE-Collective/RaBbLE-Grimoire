# RaBbLE-Episode-1-RC-Scope.md — Episode 1 Release Candidate

```
transcribe ~ collective >> ep1 rc scope: world repolish, page trim, what's in vs deferred // %EP1_RC%
```

> **What this is:** Defines the scope of the Episode 1 Release Candidate — what World ships with, what the 2–3 public pages are, and what is explicitly deferred to EP2+.
> **Related:** [Episode 1 Release Brief](RaBbLE-Episode-1-Release-Brief.md) · [Episode 1 Release Map](RaBbLE-Episode-1-Release-Map.md) · [Membership Model](RaBbLE-Membership-Model.md) · [Service Plan](RaBbLE-Service-Plan.md)

---

## RC Philosophy

Episode 1 is not a feature release. It is an **introduction** — to RaBbLE, to The Pair, to the Collective. The public surface should be small, intentional, and complete. Every page must earn its place.

Three pages maximum. Each page has one job. Liminal/transitional content from the build period is absorbed into the main page or cut. No dead ends. No placeholder copy.

---

## The Three Public Pages

### 1. `index.html` — Explore RaBbLE

**One job:** Make someone understand what RaBbLE is and want to join.

- Absorbs all liminal/transition content from the build period
- Entity presence via NeBuLA — RaBbLE is alive on this page
- Lore-forward: ethos, aesthetic, "what this is" in RaBbLE's voice
- CTA: **Join the Collective** → Summon page (invite token required) or waitlist
- Secondary: link to Collective overview

**What it is NOT:** a feature list, a marketing deck, a press release. It is an encounter.

---

### 2. `collective.html` — Explore the Collective

**One job:** Let a curious visitor understand the structure and scope of the Collective without needing a tour guide.

- What the Collective is: entity + humans + members
- Members overview: sCoRE, World, Aether, NeBuLA, OS — each with one-line purpose
- The Pair concept: brief, evocative, not technical
- Episode 1 as context — this is the beginning
- No login required. Fully public. No interactivity needed at RC.

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
| Absorb liminal content | Merge any transitional/WIP copy into `index.html` or remove | Pending |
| NeBuLA entity presence | Confirm entity renders on index — not placeholder | Pending |
| Summon page QA | Token validation, form submit, error states | Pending |
| Mobile pass | All 3 pages usable on mobile (touch, font sizes, NeBuLA perf) | Pending |
| Dead links audit | No broken hrefs, no `#placeholder` anchors | Pending |
| Copy pass | Every word on every page is intentional — no leftover build notes | Pending |

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

- [ ] `index.html` — final copy, NeBuLA entity live, CTA functional
- [ ] `collective.html` — static content complete, no placeholders
- [ ] `summon.html` — token flow works end-to-end against live sCoRE
- [ ] `RaBbLE.html` — auth-gated session opens after summoning
- [ ] Mobile QA — all pages on 375px and 768px viewport
- [ ] sCoRE deployed to Render — `https://rabble-score.onrender.com` responding
- [ ] CDN live — Aether + NeBuLA bundles at `cdn.joinrabble.world`
- [ ] Invite tokens issued to EP1 members
- [ ] Dead links clean

---

```
transcribe ~ collective >> ep1 rc scope locked: 3 pages, repolish tasks, deferred list // %EP1_RC%
```
