# World Framework Refactor — Cold-Start Handoff (post-S182/S184)

> For the next agent picking this up fresh. Companion to
> `World-Framework-Refactor.md` (the plan) and `World-Framework-Refactor-API.md`
> (the frozen P0 contract). Read those two first if you need depth; this file is
> the "where we are / what's left" snapshot.

## The thesis (unchanged)
- **Aether** = CSS theming framework. Ships the class bundle.
- **NeBuLA** = JS rendering framework. Ships `<rabble-*>` elements + `NeBuLA.effects.*` + `NeBuLA.ui.*`.
- **World** = thin assembler. Applies Aether classes, mounts NeBuLA elements. No bespoke
  rendering engine, no component stylesheet. Page-layout + state glue only.
- Root lesson: **apply, don't redefine.** Every bug this arc came from World
  re-implementing something a framework already provides.

## What shipped (S182 round 1 + S184 round 2)

### Aether (`RaBbLE-Aether`, branch new-horizons)
- `a315d6d` — 18 canonical `.rabble-*` component + motion classes from the harvest;
  glass recipe + `--rabble-accent` tokens; `.rc-*`/`--rc-*` legacy aliases (non-breaking).
- `a172cc4` — CSS effects: `.rabble-text-shudder` (`.is-active`, `.fast`/`.slow`),
  `.rabble-horizon-glow`, `.rabble-tint-radial` (`--rabble-tint-origin`),
  `.rabble-reveal-3d` (`.fast`/`.slow`), `.rabble-sigil` idle breathe.
- Firefox conic-flow gate verified clear (`.rabble-border-harmony` animates in both engines).

### NeBuLA (`RaBbLE-NeBuLA`, branch new-horizons)
- `a110de6` — extracted `<rabble-floor>` (World floor.js), `<rabble-graph>` (grimoire-graph.js),
  `<rabble-doors>` stub, real `NeBuLA.effects.starfield`. Global is `window.NeBuLA` (uppercase).
- `f4b9144` — real `NeBuLA.effects.{streaks,constellation,haze}` + real `<rabble-doors>`
  orbit engine (6 doors, theta=(2π/N)·i−π/2, omega=0.05+0.011·(N−i), ring 0.55+0.085·i,
  squash y*0.42 — from Chrysalis `liminal.js`).
- **Effect mount contract (IMPORTANT):** `NeBuLA.effects.<name>(target, opts)` — `target`
  MUST be a sized `position:relative` container `<div>`, NOT a `<canvas>`. The effect injects
  its own absolutely-positioned canvas. Mounting on a bare `<canvas>` renders 0px (blank).
- Build: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.

### World (`RaBbLE-World`, branch new-horizons)
- `b995235` — the Atlas (`world/RaBbLE-Catalog.html`): catalog rendering every item purely
  from framework parts. Registered in new `world/js/RaBbLE-pages.js`.
- `b0d934c` — scroll fix: removed `overflow-y:auto` from `<html>` root (scroll-container
  footgun in non-Chromium engines). html/body now carry no overflow declarations.
- `821b96c` — P4: index/os/account/summon pages consume Aether classes + NeBuLA elements
  directly; dropped migrated component CSS/JS; deleted orphaned `RaBbLE-grimoire-graph.js`
  + `RaBbLE-realm.js`.
- `eac0167` — Atlas grown with real deepfield effects (container-mounted: streaks/constellation/
  haze) + 6 orbiting `<rabble-doors>` + the 4 new Aether CSS effects. Console-clean, 0 failed
  requests. (Streaks/haze are live but faint by design — probabilistic spawn / slow drift.)

### Grimoire (`RaBbLE-Grimoire`, branch new-horizons)
- `4cc3815` — `RaBbLE-Agent/RaBbLE-Theme-System.md` (API ref: ~80 Aether classes, 4 elements,
  4 ui factories, 7 effects, CDN consumption) + `RaBbLE-Frontend-Guide.md` (how agents build
  new RaBbLE front-end apps). Both indexed in INDEX.md.
- `log/plans/harvest-map-effects.md` — 2nd-pass effect harvest (confirmed all 4 stubs real).

## Open flags for Mark (decisions, not yet acted on)
1. **`page-runtime.js` (global ◈ nav) + `bg.js` (ambient) don't exist** — pages referenced
   them; removed in a prior RC1 prune. Track C de-referenced the dead links. If those were
   meant to survive, they need *restoring*, not just de-referencing. **Mark's call.**
2. **`account.html` "← chat" → `RaBbLE-Chat.html` (404)** — that page is gone. Should repoint
   to `../index.html` (trivial fix, not yet done).
3. **World `AGENT.md` page inventory is stale** — lists Chat/Boot/Docs/Studio pages that
   no longer exist. Needs a pass.

## What's left (next phase)
- **P4 final cleanup (deferred):** drop the `.rc-*` alias rule blocks from Aether once all
  World pages reference `.rabble-*` directly; shrink the per-page CSS further. Aliases are
  load-bearing until every page is migrated — verify with per-page screenshot parity first.
- **De-dupe Three.js** — loaded by both the NeBuLA bundle and floor/graph ("Multiple
  instances" console warning, non-blocking).
- **EP1 gates G7/G9** — Mark-led.

## How to run / verify
- dev-serve: `bash RaBbLE-Grimoire/spells/... ` → serves World + versioned bundles on `:8080`.
  Flip point `world/js/RaBbLE-config.js` (localhost → `:8080` CDN mock).
- Screenshot QA: CommonJS Playwright from npx cache, drive `window.RaBbLEStage.next()`,
  bundles from `:8080`. Confirm border flow animates in **Firefox** too.
- Palette vars ONLY, never raw hex (hex lives only in palette-definition files).
- Chrysalis (`RaBbLE-Chrysalis/Chrysalis-Web/ep1/`) is READ-ONLY genesis archive — harvest, never edit.
