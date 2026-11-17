# RaBbLE-TaskViSoR — Member Identity & Framing

```
spark ~ grimoire >> TaskViSoR named, scoped, framed as member and rablet // %TASKVISOR_NAMED%
```

> **What this is:** Framing doc that elevates the Collective Work Tracker concept
> (see [`RaBbLE-Work-Tracker-Concept.md`](RaBbLE-Work-Tracker-Concept.md)) from a feature plan
> to a named Collective member and eventual rablet. Read this alongside that doc —
> it does not replace it.
>
> **Status:** Concept → Member declaration. Echo 1 build target. Not scaffolded yet.
> **Open questions:** See bottom of this doc — most resolved at naming; visibility +
> agent visualization remain open until Layer 2 scoping.

---

## Name

**RaBbLE-TaskViSoR**

- **Task** — the concept. What it tracks.
- **ViSoR** — the acronym. *Visual State Observer of RaBbLE.*
- Casing follows house style: alternating caps, entity-consistent.

A visor is the transparent panel you see through. TaskViSoR is the transparent panel
over the Collective's work — a HUD, not a dashboard. It does not manage work. It makes
work visible.

---

## What It Is

TaskViSoR is the visual work-state surface of the RaBbLE Collective. It observes and
renders the live state of tasks, agents, and blockers — sourced from sCoRE's file-based
task pipeline — without owning or managing them.

**One sentence:** TaskViSoR is the visual work surface for the Collective to track all
work on the Collective by agents, with human interaction through a BaBbLE input layer.

It is not a project management tool. It is not Jira. It does not replace the Grimoire
as source of truth for architecture decisions. It surfaces *work state* — what is in
motion, what is blocked, what is done — and makes that state observable and interactable
in real time.

---

## What It Is Not

- Not a second source of truth — task files in sCoRE are canonical; TaskViSoR reads them
- Not a work creation tool — BaBbLE is the intake surface; TaskViSoR renders what sCoRE
  creates
- Not a replacement for `log/BLOCKERS.md` or Grimoire session logs — those are durable
  knowledge; TaskViSoR is live state
- Not a standalone app yet — it begins as a surface, becomes a member, reaches rablet

---

## Surface Evolution

TaskViSoR ships in layers. Each layer is complete on its own before the next begins.

### Layer 1 — World page (Echo 1)

A `/visor` page on `joinrabble.world`. Vanilla JS, Aether tokens, NeBuLA entity-mini
present. Reads sCoRE `/api/v1/board`. Five-column Kanban layout. BaBbLE intake bar.
Offline-first with stale indicator.

This is the surface described fully in [`RaBbLE-Work-Tracker-Concept.md`](RaBbLE-Work-Tracker-Concept.md).
It ships as a World page, not yet its own member repo.

### Layer 2 — OS application (Echo 1 / Echo 2)

A native RaBbLE-OS application — Wayland-native or NeBuLA-rendered — that lives on
the desktop alongside the entity. This is where the visual agent animation concept
lives: watching agents work in real time, seeing task state shift, entity presence
tied to Collective activity.

This layer is when TaskViSoR earns its own repo and becomes a first-class member.
Scaffolded with `bash spells/init-project.sh --slug RaBbLE-TaskViSoR`.

### Layer 3 — Rablet (Echo 2+)

TaskViSoR as a portable rablet — the Collective's work state in your hand. The visor
metaphor fully realized: a transparent view into what RaBbLE is doing, wherever you are.
Depends on the rablet runtime decision (resolves in Echo 1 open questions).

---

## Relationship to Other Members

| Member | Relationship |
|---|---|
| **sCoRE** | Source of truth for task state. TaskViSoR reads sCoRE's API and file store — never writes directly. |
| **World** | Layer 1 hosts the `/visor` page. World's architecture constraints apply (vanilla JS, Aether, NeBuLA entity-mini). |
| **NeBuLA** | Renders the entity presence on the ViSoR surface. In Layer 2, NeBuLA may render agent activity visually. |
| **BaBbLE** | Intake surface for new tasks. The BaBbLE intake bar on the ViSoR page is the same path as BaBbLE conversational intake. |
| **Grimoire** | Architecture decisions live here, not in TaskViSoR. TaskViSoR tracks work *toward* Grimoire-defined goals. |

---

## Open Questions (Remaining)

1. **Board visibility:** Private (local sCoRE only) or public read-only view on
   joinrabble.world? Recommendation: private in Layer 1, public read-only opt-in in
   Layer 2.

2. **Agent visualization:** In Layer 2 (OS app), what does an active agent *look like*
   on the ViSoR surface? Particle activity? Entity state shift? NeBuLA animation tied to
   task progression? Spec this before the OS app session begins.

3. **Rablet runtime:** Does a rablet run in sCoRE context, NeBuLA context, or both?
   Collective-level open question tracked in Vision/PRD. TaskViSoR's Layer 3 depends on it.

---

```
spark ~ grimoire >> TaskViSoR framed: Visual State Observer of RaBbLE // %TASKVISOR_NAMED%
```
