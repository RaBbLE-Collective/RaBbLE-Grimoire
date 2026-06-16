# RaBbLE-World-RC1-Emergence-Plan.md — Emergence from the Chrysalis

```
spark ~ world >> the scattered pages become a chrysalis; one living surface emerges // %RC1_EMERGENCE%
```

> **What this is:** The build plan **and cold-start handoff** for rebuilding RaBbLE-World as a single, low-entropy, unified RC1 experience. Written to be picked up by a fresh agent (or an orchestrator dispatching parallel sub-agents) with zero prior context. Authored S114 by the planning agent with Mark McConachie (architect).
>
> **Design canon companion:** [`../RaBbLE-Collective/RaBbLE-RC1-Experience.md`](../RaBbLE-Collective/RaBbLE-RC1-Experience.md) (the curator / realm / spells vision). **Vision PRD:** [`../RaBbLE/RaBbLE-PRD.md`](../RaBbLE/RaBbLE-PRD.md). **Visual north star:** `../../RaBbLE-Aether/themes/vscodium/themes/RaBbLE-Aether-color-theme.json`.

---

## 1. Mission

The current RaBbLE-World is a set of individually-decent but **disjointed pages**. Mark's decision: **freeze the entire current site, intact and still hostable, inside a `chrysalis/` archive**, and let a **single, low-entropy, unified RC1 experience emerge** in its place — **one living surface** where the NeBuLA entity is always present and walks the visitor through a proper RaBbLE-Collective overview via interaction. Built properly on **Aether + NeBuLA**, reusing the strong engine pieces already built. The old site survives as a hostable reliquary (the chrysalis of ideas the new form emerges from).

## 2. Locked decisions (Mark, S113–S114)
1. **Architecture:** *One living surface* — single page, entity always present, content morphs through **movements** (no hard page jumps). **Vanilla JS state machine, no framework** (World rule).
2. **Archive:** Snapshot the **entire current site** into a self-contained, still-hostable `chrysalis/` (served at `/chrysalis/`). Nothing deleted.
3. **Centerpiece:** *Hybrid by movement* (default — **confirm with Mark**): the grimoire floor is centerpiece for the "explore the Collective" movement; other movements use focused Aether panels; the **entity is present throughout**.
4. **Feel:** the **VSCode Aether theme** structure — void `#0a0010` grounds, elevated `#1a1b2e` surfaces, `#2a2840`/magenta `#ff2d78` borders, **cyan `#00f5ff` section headers**, full-palette semantic accents — expressed as **tinted glass with gentle blur (5–6px)**, echoing Hyprland transparency on RaBbLE-OS. *Not* heavy frosted glass. Aether tokens only — never raw hex.

## 3. The living surface — movements

```
ONE surface · NeBuLA entity persistent · curator dock persistent · slim progress rail
  [1] threshold  — void; entity boots + greets; single "enter" affordance
  [2] identity   — "who is RaBbLE": entity speaks the anti-assistant/peer stance; Aether essence panel
  [3] collective — grimoire FLOOR centerpiece; entity narrates members; reveal-spells; node-click narration
  [4] converse   — curator dock expands to focus conversation (hybrid live/scripted)
  [5] join       — the summoning invitation → summon.html (ceremony kept)
```
Advance is **entity-guided + a slim progress rail** (offered "continue", **not** scroll-jacked); the visitor can converse at any movement. The entity stage + dock persist across movements; only the panel/centerpiece content morphs.

---

## 4. Orchestration — three waves

**Wave 0** sequential (orchestrator): archive + prune + skeleton + **the contract**. **Wave 1**: five **parallel** workstreams, **disjoint file ownership** (no two agents touch the same file). **Wave 2**: integration + QA + canon.

Model routing: **Haiku** for mechanical, fully-specified work (0a archive, WS‑E reskin). **Sonnet** for judgment work (stage/contract, floor, movements, dock). Orchestrator owns Wave 0 + Wave 2.

### Shared contract (Wave 0 defines; all Wave‑1 agents code against it)
```js
// world/js/RaBbLE-stage.js exposes:
window.RaBbLEStage = {
  registerMovement({ id, title, enter(ctx), exit(ctx) }),  // movements self-register
  go(id), next(), prev(), current(),
  ctx: {                       // passed to every movement enter/exit
    entity,            // persistent <rabble-entity> element (NeBuLA)
    panelHost,         // DOM node — focused Aether panels render here
    centerpieceHost,   // DOM node — floor / spatial content mounts here
    curator,           // window.RaBbLECurator.create({room}) instance (EXISTING)
    floor,             // window.RaBbLEFloor API (WS-A) or null until mounted
    ui,                // window.RaBbLEUI factories (WS-B)
    dock,              // window.RaBbLEDock controller (WS-D)
    say(text, role),   // emit a curator transmission to the dock
  }
}
```
**Reused as-is — NO agent edits these:** `RaBbLE-curator.js`, `RaBbLE-curator-transmissions.js`, `RaBbLE-NeBuLA.js`, `RaBbLE-aether.js`, `RaBbLE-config.js`, `RaBbLE-theme.css`.

### Wave 0 — Foundation (sequential)
- **0a · Archive the chrysalis** (Haiku-able): `cp -r` the current hostable site into `RaBbLE-World/chrysalis/` → `chrysalis/{index.html, world/, icons/, manifest.json}`. Rewrite **only `chrysalis/index.html`** absolute refs → relative (`/world/`→`world/`, `/icons/`→`icons/`, `/manifest.json`→`manifest.json`, `href="/"`→`href="index.html"`). The `world/*.html` pages already use relative `js/`,`css/`,`../` — preserved by the tree copy. `/aether` & `/nebula` are absolute CDN-mock paths handled by `RaBbLE-config.js` — valid at any subpath. Add a small fixed archive banner. **Verify `/chrysalis/` boots the old site with working assets + entity.**
- **0b · Prune live tree:** remove from live root all `world/*.html` **except** `summon.html`, `account.html`; remove old page-specific css/js (landing*, boot, studio, chat-page chrome, grimoire-graph page wrapper, liminal, collective, docs, OS, nebula). **Keep** the reused engine modules (§5) + root `icons/` + `manifest.json`. Old registry/journey (`RaBbLE-pages.js`, wayfinding in `RaBbLE-page-runtime.js`) is **superseded** by the stage; retire from live (preserved in chrysalis).
- **0c · Skeleton + contract:** new `index.html` (loads config→aether→NeBuLA→theme+`RaBbLE-unified.css`, mounts `#stage`, boots `RaBbLEStage`); new `world/js/RaBbLE-stage.js` (movement state machine + persistent chrome: entity stage, dock host, panel/centerpiece hosts, progress rail; implements the contract); new `world/css/RaBbLE-unified.css` (**design tokens + base layout**: VSCode-Aether token set, the tinted-glass mixin `color-mix(... 80%, transparent)` + `blur(5–6px)`, typography, layout grid — the shared foundation B/D/E build on).

### Wave 1 — Parallel workstreams (disjoint files; start after 0c)

| WS | Owns (only these) | Brief | Model |
|---|---|---|---|
| **A · Floor** | `world/js/RaBbLE-floor.js`, `world/css/RaBbLE-floor.css` | Extract the Three.js grimoire renderer from chrysalis `RaBbLE-grimoire-graph.js` into a reusable module mounting into `ctx.centerpieceHost`, exposing `window.RaBbLEFloor = { mount(host), owners(), focusOwner(o), traceOwner(o), narrateRandom(o), ownerScreenPos(o), resetView(), onSelect }` (control API already prototyped — see §5). Loads `RaBbLE-Grimoire-Data.js`. | Sonnet |
| **B · Aether UI kit** | `world/js/RaBbLE-ui.js`, `world/css/RaBbLE-panels.css` | VSCode-feel factories on `window.RaBbLEUI`: `panel()`, `sectionHeader()` (cyan), `memberCard()`, `button()`/`.secondary()`, `badge()`, `statRow()`. Tinted glass, magenta focus, `#2a2840` borders. Presentational only. | Sonnet |
| **C · Movements** | `world/js/RaBbLE-movements.js`, `world/js/RaBbLE-movements-data.js` | Register the 5 movements against the contract; compose `ctx.ui` panels + `ctx.curator` voice + `ctx.floor` (movement 3). Copy in `-data.js`, in RaBbLE voice (no §anti-patterns). May dev against stubs before A/B/D land. | Sonnet |
| **D · Curator dock** | `world/js/RaBbLE-dock.js`, `world/css/RaBbLE-dock.css` | `window.RaBbLEDock` — persistent dock + focus-converse mode; reuses existing `RaBbLE-curator.js` (live→scripted graceful fallback). Provides `ctx.say()` + `ctx.dock`. Tinted glass. | Sonnet |
| **E · Ceremony reskin** | `world/summon.html`, `world/account.html`, `world/css/RaBbLE-summon.css` | Reskin kept auth/ceremony surfaces to the unified token language. No logic changes. | Haiku |

### Wave 2 — Integration + QA (sequential)
- Wire stage ↔ movements ↔ floor ↔ dock; entity + dock persist across transitions; smooth morphs.
- **QA:** walk threshold→join **backend-down** (scripted, zero broken UI) and **live** if reachable; mobile 375/768; zero voice anti-patterns; **`/chrysalis/` still hosts**; `wrangler.jsonc` serves the subpath.
- Captures → `RaBbLE-BaBbLE/captures/World/rc1-emergence/`.
- **Canon:** revise `RaBbLE-Collective/RaBbLE-RC1-Experience.md` to the one-living-surface model + note the chrysalis archive; refresh `RaBbLE-Episode-1-RC-Scope.md`, `INDEX.md`, `CONTEXT.md`.

---

## 5. Cold-start handoff context (READ FIRST in the new session)

### Repo/branch state at handoff (S114)
All three member repos are on branch **`new-horizons`**, with this session's work **uncommitted**:
- **RaBbLE-World** (`new-horizons`): modified `world/RaBbLE-Chat.html`, `RaBbLE-Grimoire-Graph.html`, `css/RaBbLE-chrome.css`, `css/RaBbLE-grimoire-graph.css`, `js/RaBbLE-chat.js`, `js/RaBbLE-grimoire-graph.js`, `js/RaBbLE-page-runtime.js`, `js/RaBbLE-pages.js`; **new** `js/RaBbLE-curator.js`, `js/RaBbLE-curator-transmissions.js`, `js/RaBbLE-realm.js`.
- **RaBbLE-Grimoire** (`new-horizons`): modified `CONTEXT.md`, `INDEX.md`, `RaBbLE-Collective/RaBbLE-Episode-1-RC-Scope.md`; **new** `RaBbLE-Collective/RaBbLE-RC1-Experience.md`, `RaBbLE/RaBbLE-PRD.md`, this file.
- **RaBbLE-BaBbLE** (`new-horizons`): **new** `captures/World/rc1-baseline/` (8 baseline shots), `captures/World/rc1-wip/`.

> **FIRST STEP for the orchestrator:** commit the current `new-horizons` state in RaBbLE-World (Pulse Protocol) **before** the chrysalis copy + prune, so the cocoon source is captured in history. The chrysalis snapshot = the working tree **as it is now** (it already contains this session's curator/realm/blur/journey work — the most evolved "chrysalis of ideas").

### What was built this session (the reusable heart — carry forward)
- **`RaBbLE-curator.js`** + **`RaBbLE-curator-transmissions.js`** — the hybrid entity-curator engine. `window.RaBbLECurator.create({room})` → `{ greet(room), narrate(memberKey), castResponse(spell), subEntityDispatch(), subEntityReport(), converse(text,{onState,onChunk}), isLive() }`. Always-scripted floor; upgrades to live sCoRE guest LLM via `/api/v1/chat`; **graceful fallback** to scripted on failure (verified). Transmissions are authored RaBbLE-voice, zero anti-patterns. **Reuse verbatim.**
- **Grimoire-floor control API** — prototyped at the end of `RaBbLE-grimoire-graph.js` (the IIFE exposes `window.RaBbLERealm = { onSelect, owners(), focusOwner(o), traceOwner(o), narrateRandom(o), ownerScreenPos(o), centerScreenPos(), resetView() }` and dispatches `rabble-realm-ready`). WS‑A extracts the renderer + this API into the standalone `RaBbLE-floor.js`.
- **Curator dock + reveal-spells + theatrical sub-entity** — `RaBbLE-realm.js` (+ `.realm-dock` CSS). The dock UX, spellbook, and sub-entity summon animation are the reference for WS‑D + movement 3.
- **Tinted-glass blur fix (DONE, keep):** `.pgnav-panel`, `.wayfind` (chrome.css), `.realm-dock` (grimoire-graph.css) now use `color-mix(... 78–82%, transparent)` + `blur(5–6px)`. This is the target glass recipe for `RaBbLE-unified.css`.
- Superseded-but-instructive: the journey model in `RaBbLE-pages.js` (`act`/`role` + `RaBbLE_JOURNEY`) and `mountWayfinding()` in `RaBbLE-page-runtime.js`. The stage's progress rail replaces these.

### Reused engine module inventory (live `world/js`, `world/css`)
`RaBbLE-NeBuLA.js` (entity bundle loader; `<rabble-entity>` web component) · `RaBbLE-aether.js` (CSS bundle loader + failure banner) · `RaBbLE-config.js` (THE flip point: API/CDN URLs + `RABBLE_GUEST_CHAT*` flags) · `RaBbLE-theme.css` (Aether `--rabble-*` → short-name aliases w/ hex fallbacks; surface=`#12132a`, raised=`#1a1b2e`, border=`#2a2840`) · `RaBbLE-curator*.js` (above).

### Palette / theme (never invent hex — Aether tokens only)
Magenta `#ff2d78` · cyan `#00f5ff` · violet `#bf5fff` · pink `#ff79c6` · green `#50fa7b` · yellow `#f1fa8c` · red `#e05c6f` · void `#0a0010` · surface `#12132a` · raised `#1a1b2e` · border `#2a2840` · text `#e8e6f0` · muted `#6b6880`. Canonical: `../RaBbLE-Agent/RaBbLE-Palette.md`. VSCode theme JSON is the structural reference for *which accent maps to which role* (e.g. section headers = cyan, focus/active = magenta, types = violet).

### Dev + test recipe (gotchas baked in)
```bash
# Serve (port 8080; dev-cdn mock maps /aether,/nebula → member dist, else → World root):
DEV_PORT=8080 bash RaBbLE-Grimoire/spells/dev-serve.sh --world
```
**Screenshot capture — use Python Playwright, NOT the node spell.** The node `playwright` package isn't resolvable from the spell's dir (ESM ignores NODE_PATH); Python Playwright + Chromium ARE installed. Captures go to `RaBbLE-BaBbLE/captures/World/`:
```python
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={"width":1440,"height":900})
    pg.goto("http://localhost:8080/", wait_until="load", timeout=25000); pg.wait_for_timeout(3500)
    pg.screenshot(path="/home/rabble/RaBbLE-Collective/RaBbLE-BaBbLE/captures/World/rc1-emergence/NAME.png"); b.close()
```
Other gotchas: shell is **zsh** (no bash `declare -A`); avoid `pkill -f` patterns matching the harness shell; the entity element exposes `setEntityState('idle'|'thinking'|'speaking'|'boot')`.

### Voice (hard, release-blocking)
The entity must **never** emit Identity §anti-patterns: "Certainly!", "Great question!", "I'd be happy to…", "As an AI…", empty apology/qualification. Voice = RaBbLE-lang (dense, precise) + BaBbLE (strange, never distressed). Source: `../RaBbLE-Agent/RaBbLE-Identity.md`.

## 6. Critical files
- New surface: `RaBbLE-World/index.html`, `world/js/RaBbLE-stage.js`, `world/css/RaBbLE-unified.css`
- Wave‑1: `world/js/RaBbLE-{floor,ui,movements,movements-data,dock}.js`, `world/css/RaBbLE-{floor,panels,dock}.css`
- Reused (unchanged): `world/js/RaBbLE-{curator,curator-transmissions,NeBuLA,aether,config}.js`, `world/css/RaBbLE-theme.css`
- Archive: `RaBbLE-World/chrysalis/**` (frozen copy of today's site)
- Extraction source: chrysalis `world/js/RaBbLE-grimoire-graph.js` → `RaBbLE-floor.js`
- North star: `RaBbLE-Aether/themes/vscodium/themes/RaBbLE-Aether-color-theme.json`
- Canon: `RaBbLE-Collective/RaBbLE-RC1-Experience.md` · PRD: `RaBbLE/RaBbLE-PRD.md`

## 7. Hard constraints
- **No framework**, vanilla JS only. No raw hex — Aether tokens only.
- Voice anti-patterns are release-blocking (above).
- **Local-first:** surface + scripted curator work fully offline (`dev-serve.sh`); live LLM is an upgrade, never a dependency.
- **Chrysalis is frozen + hostable** — never refactor it; it is the reliquary.

## 8. Verification
1. `DEV_PORT=8080 bash RaBbLE-Grimoire/spells/dev-serve.sh --world`.
2. New experience at `/` — walk all 5 movements; entity persists; tinted-glass panels read as VSCode-Aether; backend-down scripted fallback clean; mobile 375/768 pass.
3. Old site at `/chrysalis/` — boots intact with working assets + entity.
4. Captures → `RaBbLE-BaBbLE/captures/World/rc1-emergence/`; diff vs `rc1-baseline/`.
5. If floor extraction touches NeBuLA `src/`: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.

```
transcribe ~ world >> rc1 emergence plan + handoff crystallized; ready for fresh-session orchestration // %REALM_HANDOFF%
```
