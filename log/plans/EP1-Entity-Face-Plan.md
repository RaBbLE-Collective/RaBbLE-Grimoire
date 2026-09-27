# EP1-Entity-Face-Plan.md

```
spark ~ grimoire >> S234: EP1 entity face plan — "alive" entity into NeBuLA, guided Arrive→Boot→Meet→Summon→Enter World, CF unblock // %EP1_ENTITY_FACE_PLAN%
```

> **Status:** 🟡 ACTIVE (S234 proposed + Opus-reviewed, 2026-09-26) — decisions locked with Mark this session.
> **Supersedes:** `EP1-Air-Push-Plan.md` **A4** (the S203 entity-forward face — built, never
> deployed, now replaced before anyone saw it live). The rest of the Air-Push plan stands.
> **Cold-start handoff:** `log/handoffs/HANDOFF-S234-EP1-Entity-Face.md`.
> **Informed by:** `RaBbLE-BaBbLE/reliquary/2026-09-26-entity-harness/` (the "alive" HTML + SVG
> rig), `RaBbLE-NeBuLA/specs/rig/`, `RaBbLE-Aether/RaBbLE-Entity-Visual-Spec.md` (S233 rewrite),
> `log/plans/EP2-Accounts-Encryption-Spec.md`, `log/EP1-AIR-CHECKLIST.md`, S234 live audit.

---

## Context

### S234 audit — what's actually live (2026-09-26)

- **joinrabble.world AND dev.joinrabble.world still serve the S190 liminal passage** ("one living
  surface"). The S203 face (World `2434da6`) never deployed: every World Action since June fails
  with Cloudflare auth `[code:10000]` = **B-12** (token lacks User Details:Read). The checklist's
  G10 "World now ships the entity-forward face" is false.
- Chat spine healthy: `score.joinrabble.world/api/v1/chat` streams SSE. **Cold start measured
  32s** on first `/health` (Render free tier).
- `joinrabble.world/setup.sh` → **404** (the bootstrap command in Collective AGENT.md/README and
  the G9 guide). `joinrabble.world/RaBbLE-OS.ks` → 404. `AGENT.md`/`CONTEXT.md` publicly served.
- `chrysalis.joinrabble.world` does not resolve; Chrysalis has no deploy workflow.
- GitHub secrets: World + Aether have token+account id; NeBuLA + sCoRE token only; ScRiBbLE none.
- World `summon.html` POSTs `/api/v1/users/summon`, which **exists**
  (`RaBbLE-sCoRE/server/auth_routes.py:159`, `member_router`, commit 7064771) as an **invite-gated**
  registration: `/api/v1/admin/invites` (:141) mints invites, `/users/me` GET/PUT (:220/:228),
  auth prefix `/api/v1/auth` (:17). The flow is fragile, not missing: invites + users live on
  Render's ephemeral `/tmp`, and the invite URL `/summon/{token}` (:151) matches no World path.
  *(S234 first draft wrongly said the route was absent; corrected after Opus review.)*
- sCoRE CORS is exact-match from `FRONTEND_URL=https://joinrabble.world` (`render.yaml:23`,
  `server/main.py:34-45`) — **dev.joinrabble.world will be CORS-blocked** until the origin is added.

### The new entity

S233 routed Mark's entity-harness drop, but misfiled the key piece. What exists:

| Artifact | Where | What it is |
|---|---|---|
| `RaBbLE · The Entity (alive).html` | BaBbLE reliquary only — **never landed** (S233 called it "an unrelated earlier canvas render") | Self-contained entity: Canvas2D **and** Three.js (r128) modes, expression springs, blink/double-blink, heartbeat, sigh, lonely→joy mind loop, gravity-well grid, stars/haze/bokeh/motes, mesh+pulses, lens, orbits, sparks/bolts/rings, pointer attention, pinch-zoom, portrait layout, and a **timed boot sequence with scrolling log** (`BOOT`, `LOG`, `bootStep`). |
| `entity-rig.svg` + `.json` + `entity.html` | `RaBbLE-NeBuLA/specs/rig/` (reference only) | Hand-authored SVG animation rig: pivots/poles/tiers/spawners/occlusion; five-mood state machine (Idle/Ponder/Process/Insight/Curious) + `listening`. |
| Entity Visual Guide (html+pdf) | reliquary | Visual spec for both. Canon now in `RaBbLE-Entity-Visual-Spec.md`. |

Mark (S234): the alive 3D entity is **better than what NeBuLA has**, and the SVG + new Canvas2D
carry the **newer entity effects EP1 should use**. Current NeBuLA: `element.js` +
`canvas2d/` (~1.2k lines) + `threejs-backend.js` (873 lines).

**Palette gap:** the alive file uses **13 off-palette hexes** (e.g. `#03000b`, `#1a0030`,
`#f8faff`, `#7744cc`, `#55aaff`, `#33ddf0`, `#bb55dd`, `#ccddff`…). Per Rules these can't ship
as invented values; see Decision D4.

## Decisions locked (S234)

- **D1 · Accounts: plan only, ship later.** EP1 does not persist users. The Summon beat is a
  **preview** (pick portal colors, see *your* entity) framed as "claimable in Exodus". Real
  accounts = EP2 Phase 1 per `EP2-Accounts-Encryption-Spec.md`, amended by W4 below.
- **D2 · Entity port: into NeBuLA.** The alive renderer + rig moods become NeBuLA backends behind
  `<rabble-entity>`; World only consumes the element (member roles: NeBuLA renders, World assembles).
- **D3 · World flow: Arrive → Boot → Meet → Summon → Enter.** Boot duration masks sCoRE cold start.
- **D4 · Palette: swap to closest canonical (LOCKED S234).** Every off-palette hex in the alive
  file swaps to its nearest canonical color (blues hue-kept to cyan); the novel ones go on the
  consideration list `RaBbLE-Agent/RaBbLE-Palette-Candidates.md` for possible promotion. The
  8-stop nebula ramp is the lead candidate; the port keeps depth with alpha/blur until then.

---

## Workstreams

Parallel lanes. **W1-contract** (below) is the only hard dependency: W2 builds against it with a
stub while W1 implements.

### W0 · Cloudflare unblock + edge fixes (air-critical) — Mark step 1, then agent
1. **Mark:** dash.cloudflare.com → API Tokens → "Edit Cloudflare Workers" template, account
   `0391968396156c874398a9696e0b3598`, zone `joinrabble.world`, **+ Zone DNS:Edit**. Paste into
   `RaBbLE-Grimoire/.cloudflare/config` (gitignored) — never into chat.
2. **Agent:** verify token (`/user/tokens/verify` + a Workers read); `gh secret set`
   `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` on World, Aether, NeBuLA, sCoRE, ScRiBbLE,
   Chrysalis (values piped from the config file, never echoed).
3. Chrysalis `deploy.yml` (mirror World's) + bind `chrysalis.joinrabble.world`.
4. World `_redirects` (external targets OK: `curl -L` and dracut `--location` follow them):
   `/setup.sh` → raw GitHub Collective `main/setup.sh`; `/RaBbLE-OS.ks` → raw OS
   `new-horizons/RaBbLE-OS.ks` (the KS exists **only** on `new-horizons`; repoint to `main` at air).
   **Extend** the existing `.assetsignore` with `AGENT.md`, `CONTEXT.md`, `gist/`, `scripts/`,
   `.github`, `.wrangler`, `wrangler*.jsonc` (CLAUDE/CODEX/GEMINI symlinks aren't in CI checkouts).
   Note Chrysalis's remote is `markm1206/…`, not the org — set its secrets there.
5. **Keep-warm:** sCoRE proxy Worker gets `triggers: { crons: ["*/10 * * * *"] }` in
   `wrangler.jsonc` + a `scheduled()` export that GETs Render `/health`. `deploy-proxy.yml` fires
   only on `main`, and sCoRE `main` is a stub (no `cf-proxy.js`/`wrangler.jsonc`) — the proxy has
   only ever been hand-deployed. Add `new-horizons` to the workflow trigger (or deploy manually
   via `cloudflare-ctl.sh deploy score`). One always-on free service fits Render's 750 h/mo.
5b. **CORS for dev review:** add `https://dev.joinrabble.world` to `FRONTEND_URL` (comma list per
   `main.py:34-45`) in `render.yaml` **and** the Render dashboard value (dashboard wins; check it
   with `render-ctl.sh`). Without this W2 review on dev silently runs offline.
6. Re-run failed Actions; confirm dev.joinrabble.world serves current `new-horizons`; resolve B-12;
   update `registry/subdomains.yml` (dev blocker → none; homepage tech = Workers).

### W1 · NeBuLA: the alive entity becomes `<rabble-entity>` (air-critical, largest)

**W1-contract (write first, commit alone, ~½ session)** — the API World codes against:

```
<rabble-entity backend="alive" dimension="2d|3d" state="idle" emotion="calm"
               portal-a="--token" portal-b="--token" autoboot="false" autonomous="true">
  el.boot({ steps:[{id,label}] })   → resolves when visual boot completes
  el.completeStep(id) / el.failStep(id)  // World reports real work; each pushes a log line
  el.setState('idle'|'ponder'|'process'|'insight'|'curious'|'listening'|'speaking')
  el.setEmotion('calm'|'joy'|'sad'|'angry')
  el.setPortals(a, b)               // Summon preview; recolors 2D AND 3D materials
  el.pulse(kind)                    // spark / bolt / ring accents
  el.attend(x, y)                   // pointer attention when chat UI covers the canvas
  el.pause() / el.resume() / el.resize() / el.dispose()  // removes window listeners + WebGL
  autonomous=false                  // silences the mind/lonely loop so World's setState wins
  compat: setEntityState() + `rabble:entity-state` stay as aliases (13 call sites, Catalog, summon.html)
  events: entity-boot-step, entity-boot-complete, entity-state
```

Curator → state mapping: `thinking`→`process`, `speaking`→`speaking`, `idle`→`idle`; typing →
`listening` (alive's hold-to-listen pointer gesture is disabled when World drives listening).

**Boot semantics (grounded in alive's timeline):** visual phases end ~4.2 s (`BOOT` at :115-116);
log/services run 5.3–7.4 s; slide at 7.6 s. **Hold = clamp `boot.t` at the ready phase until all
steps settle.** Drop the hard-coded fake-kernel `LOG` (:533); lines come only from
`completeStep`/`failStep` labels. Disable `skipBoot` on pointerdown (:658) while held. Boot is
**2D only** (`setMode` refuses 3D pre-boot, :711). During boot the entity sits in the left
quarter (`bootPlace`, :110): World keeps that zone clear. Reduced motion: skip to a short fade
boot (alive only slows time ×0.4 today, :933). Log UI is a `createBootLog` factory under
`src/ui/` (existing `createX` naming), Aether-styled.

**W1-port (EP1 = wrap, not split):** alive is **961 lines** of shared module globals (`ctx`
reassigned for the 3D face texture, `E`, `cam`, `boot`, `time`, `energy`, `sty`, poles, `nodes`,
`bokeh`) hard-wired to DOM ids (`#cv`, `#cv3`, `#bootui`, `#dock`, `#toast`, `#skip`), and
`init3D` reuses the 2D arrays. So for EP1:
- Wrap the file **whole** in `createAlive(host, opts)` inside `src/backends/alive-backend.js`:
  DOM created inside the element, ids → scoped refs, contract methods bolted on. The 5-file split
  (`state/draw2d/draw3d/boot/field`) moves to **post-air**.
- Merge the **SVG rig moods** (five moods + `listening`) into alive's `EXPR` table as the state
  map. Enforce Visual-Spec invariants: portal asymmetry, eye/portal pole opposition.
- **Three.js (bigger than it looks):** `three-loader.js:16` pins **0.160.0**; alive uses r128 +
  `examples/js/lines` (404 at 0.160, only ESM `examples/jsm` importing bare `three`); IIFE marks
  `three` external. Plan: esbuild-alias `three` → a `window.THREE` shim and bundle the jsm
  `LineSegments2`/`LineMaterial`; set `ColorManagement.enabled=false` + linear output so additive
  glows match r128; **visual A/B vs r128** screenshots. 0.160 is the last version with
  `build/three.min.js`, so the pin is fragile (note in NeBuLA CONTEXT).
- **Palette reader is broken today:** `puppet/palette.js:48-62` reads `--rabble-primary/
  secondary/tertiary/grid`, but Aether publishes `--rabble-magenta/cyan/…`
  (`assets/palette/rabble-palette.css`), so it always falls back to hardcodes; it also snapshots
  at import and its header points at a stale `common/` path. Fix names + read at runtime.
  Swaps per D4 are tabled in `RaBbLE-Palette-Candidates.md`; use exactly those.
- `backend="alive"` becomes **default**; old `canvas2d`/`threejs` stay selectable until Mark signs
  off the face, then reliquary to Chrysalis per condense-not-delete.
- Perf: keep `frame-budget.js` + DPR caps; mobile portrait uses alive's `portrait()` layout.
- `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.
- Rewrite `RaBbLE-NeBuLA-API.md` against the new contract (closes Air-Push C4's worst mismatch).

**Verify:** headless Playwright: element boots, each state renders, 2D↔3D toggle, `setPortals`
changes both portals, boot holds until `completeStep` of all steps; ≥50 FPS desktop 2D.

### W2 · World: guided Arrive → Boot → Meet → Summon → Enter (air-critical)

One page (`index.html`), no scroll, beats are states of the same surface. Aether classes + NeBuLA
element only; vanilla JS; no hex in World CSS.

| Beat | What happens | Real work masked |
|---|---|---|
| **Arrive** | Near-dark field (NeBuLA ambient). One line + one action: *wake RaBbLE*. | Page load already fires sCoRE `/health` (config.js) — cold start starts ticking here. |
| **Boot** | `el.boot(steps)`: log lines = real steps only — *Aether woven* · *NeBuLA renderer* · *reaching sCoRE…* · *awake*. No invented steps. | `config.js:67` exports its `/health` promise as `window.RABBLE_HEALTH` (and runs locally too); that gates *reaching sCoRE*; hold until 200 or 45 s → offline-degrade line, entity still wakes. Curator retries live chat after a cold start instead of latching offline (~`RaBbLE-curator.js:150`). |
| **Meet** | Entity centered; conversation is the only input. `listening` while typing, `process` awaiting first token, `speaking` while streaming, `insight` on done. First RaBbLE line is short presence copy. | — |
| **Summon** | After a few exchanges (or via affordance): RaBbLE invites you to see *your own* entity. Pick two portal colors (palette tokens only, pole-opposition enforced) → `setPortals` preview. Copy: claim it in **Exodus**. **No persistence** (D1). | — |
| **Enter** | Quiet doors: the Collective (members), RaBbLE-OS (download: netinstall + `inst.ks=https://joinrabble.world/RaBbLE-OS.ks`, Developer Preview label), Episodes/roadmap, Grimoire. | — |

- Reuse: `RaBbLE-curator.js` (chat SSE), `RaBbLE-face.js` presence chip. Retire to Chrysalis:
  `summon.html` + `RaBbLE-summon.js`/`RaBbLE-account.js` (invite-gated flow whose invites and users
  vanish on every Render restart; per D1 EP1 persists nothing). Summon beat replaces it.
- S203 face (`2434da6`) freezes to `Chrysalis-Web/ep1/world/` as "the face that never aired".
- Genesis copy: short presence lines scaffolded from `RaBbLE-Identity.md` for Mark's edit
  (em-dash-free per feedback).
- Deploys to **dev.joinrabble.world** on push (post-W0) → Mark reviews there.

**Verify:** Playwright walkthrough of all five beats at desktop + 390px portrait; boot hold
demonstrated with sCoRE blocked; offline path; screenshots to Mark.

### W3 · Grimoire truth-alignment (coherence, zero risk)
- Collective `AGENT.md` Current State → S234; fix `end-session.sh` S199-label bug (recurred
  S231/232/233) and move the stray S199 entry below `## LATEST`.
- `current.epoch.yml` blocker_note (B-10 resolved → B-12); `EP1-AIR-CHECKLIST.md` G10 → truth;
  retag blockers: B-12 → `ep1-gate`, B-02 → `resilience` (G5 already met).
- `distill-gists.sh`; index the 19 unreachable docs; rename Grimoire `RaBbLE-ScRibLE/` →
  `RaBbLE-ScRiBbLE/`; `sync-symlinks.sh` for Pocket/ScRiBbLE.
- Move `RaBbLE · The Entity (alive).html` provenance into NeBuLA `specs/rig/` README.

### W4 · Accounts direction (plan only — D1)
Amend `EP2-Accounts-Encryption-Spec.md` (no build):
- The EP1 Summon preview **is** the front half of the EP2 summoning ceremony; the entity config
  it produces (`portal-a`, `portal-b`, future OID) is exactly what EP2 persists. `<rabble-entity>`
  attributes are the schema.
- Record existing surface: sCoRE `/api/v1/auth/register|token|me`, `/api/v1/admin/invites`,
  `/api/v1/users/summon` (invite-gated), `/api/v1/users/me` GET/PUT (JWT, 8 h TTL). It is an
  invite-era EP1 scaffold on ephemeral Render `/tmp` — the persistence store is the real EP2 work,
  and the spec's "no invite gate" direction means summon-via-invite gets replaced, not extended.
  Fix the invite URL shape (`/summon/{token}` matches no World path) when it's rebuilt.
- Open for EP2: storage choice (spec says DynamoDB/S3 vs sCoRE-local), OAuth provider, and the
  EnGrAm vs sCoRE memory boundary (S233 open item).

---

## Sequencing

```
now ─┬─ W0.1 Mark mints token ──► W0.2–6 agent ──► dev.joinrabble.world live
     ├─ W1-contract ──┬─► W1-port ──► vendor bundle ─┐
     │                └─► W2 (stub) ─────────────────┴─► W2 on dev ──► Mark sign-off (G10)
     ├─ W3 (anytime, sub-agent)
     └─ W4 (anytime, doc only)
then: G7 + G9 (Mark, VM) ──► EP1-AIR-CHECKLIST §D air procedure
```

Sub-agent fan-out (pin `model: "sonnet"`): W1-port, W2, W3 in parallel after W1-contract lands.
W0 stays in the main session (secrets). Claim scopes via `session-start.sh` per lane.

## Mark-gated
- ~~W0.1 token mint~~ ✅ S234 · ~~D4 palette call~~ ✅ S234 · face sign-off on dev (G10) · Genesis copy edit · G7/G9 · air call.

## Deferred (unchanged from Air-Push plan)
sCoRE refactor · `.rc-*` retirement · OS manifest SSoT · CI guards · ISO track · vault build ·
real accounts/ingestion (EP2) · Studio maturation (C5).
