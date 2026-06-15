# RaBbLE-World — Episode 1 Unification Design

> Status: design / awaiting spine decision (S103). Source for the EP1 World build.
> Companion to `log/EP1-READINESS-AUDIT-S103.md` §D. Members hold code; this is the canon.

## Goal

Combine Mark's three favorite surfaces — **the liminal**, **the grimoire browser**, and
**the landing** — plus the **summon ceremony** into one cohesive EP1 experience that:
demonstrates the RaBbLE platform · introduces visitors to the Entity · lets them begin the
summoning ceremony to obtain a personal entity.

## What already exists (so this is consolidation, not new construction)

**Shared foundation (every page already loads it):**
`RaBbLE-theme.css` + `RaBbLE-chrome.css` (base look) · `RaBbLE-aether.js` + `RaBbLE-NeBuLA.js`
(CDN bundle loaders) · `RaBbLE-pages.js` + `RaBbLE-page-runtime.js` (page runtime). This is the
spine to build on; the 20 CSS / 21 JS files are per-surface layers on top of it.

**The liminal (`RaBbLE-Liminal.html` + `RaBbLE-liminal.js`)** is *already a navigation hub*:
entity-core (NeBuLA) keeper + **6 orbiting portal doors**, whisper cards (RaBbLE describes the
door under your cursor), ambient transmissions, entropy meter. Its 6 doors (`PORTALS[]`):
| glyph | name | organ | →
|---|---|---|---|
| ✦ | the channel | voice | chat |
| ⬡ | the collective | organism | collective / organs map + "path in" |
| ◈ | the graph | memory | **grimoire graph** |
| ▣ | the substrate | body | OS |
| ◌ | the eyes | render | NeBuLA |
| ◐ | the codex | signal | **docs / grimoire reader** |
Currently the statusbar self-labels "episode 2" and links back to `../index.html` ("the door").

**The landing (`index.html`)** is the most evolved surface: a full WM/desktop-in-browser shell
(`landing-shell/stage/panels/login` + Alpine.js + `RaBbLE-bg.js`) that **already hosts a
`grimoire` applet** (`data-applet="grimoire"`, `RaBbLE-Grimoire-Data.js` + `RaBbLE-Grimoire.js`),
a `stage` applet, and a `log` applet.

**The grimoire browser** exists in TWO forms: `RaBbLE-Docs.html` (TOC + reader = "the codex")
and `RaBbLE-Grimoire-Graph.html` (Three.js node graph = "the graph"). Plus the landing's
embedded `grimoire` applet panel.

**The summon (`summon.html` + `RaBbLE-summon.js`)** — the join ceremony — already built; plus
`account.html` for session-aware state.

## The EP1 journey (recommended spine)

```
joinrabble.world
   │
   ▼
[ THE LIMINAL ]  ← EP1 front door (re-framed from "ep2" to the arrival)
   entity-keeper + orbiting doors; RaBbLE notices you, whispers, transmits
   │   doors collapse to the EP1-essential set:
   ├── the collective  → [ WM SHELL ]  the platform, demonstrated (desktop-in-browser)
   ├── the codex/graph → [ GRIMOIRE BROWSER ]  meet the Entity through its knowledge/lore
   └── the channel     → [ SUMMON CEREMONY ]  begin joining → personal entity
```

Liminal is the cohesive connective tissue (it already whispers/transmits the Entity's voice);
the WM shell is the "show me the platform" payload; the grimoire browser is the "who is this
Entity" payload; summon is the conversion. Non-EP1 surfaces (standalone Chat/OS/NeBuLA-Demo/
Studio/Boot) fold into the WM shell as windows or defer to EP2.

## Consolidation work

1. **Shared shell extraction** — a single `RaBbLE-shell.css` + nav/transition module so each
   surface is a layer, not a silo. Target: collapse the landing-{shell,stage,panels,login} +
   per-page CSS toward Aether tokens + one shell + thin per-surface skins.
2. **One transition model** — liminal→shell→grimoire→summon should feel like moving through a
   place (the liminal's existing glitch-veil / state machine is the vocabulary), not page loads.
3. **Aether-token discipline** — per the Aether-first rule, World CSS should be structure/behavior;
   colors/fonts come from Aether `var(--*)`. Audit the per-page CSS for stray hex.
4. **Lean the surface set** — decide per page: EP1 door / WM window / defer to EP2 / archive.

## Open decisions (need Mark)

- **Spine:** Liminal as the EP1 front door (recommended) vs landing-shell-first with liminal as
  an intro overlay vs keep distinct pages but unify shell/nav only.
- **Grimoire browser form for EP1:** the Graph (◈ visual), the Codex/Docs reader (◐), or both
  (graph as the "wow", reader as the depth).
- **Door set:** which of the 6 liminal doors are EP1-live vs EP2-dimmed.

## Build sequence (after spine confirmed)

Phase 1: extract shared shell + token audit (no visual change). →
Phase 2: re-frame liminal as EP1 entry + wire the EP1 door set. →
Phase 3: grimoire browser as a coherent surface (graph and/or reader). →
Phase 4: summon flow polish + account/session continuity. →
Phase 5: transition model pass + screenshot QA loop (`spells/visual-screenshot.sh`).
Each phase verified with captures before the next.
