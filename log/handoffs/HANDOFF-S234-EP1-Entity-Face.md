# HANDOFF-S234 — EP1 Entity Face

> Cold start for any agent picking up the EP1 face push. Plan of record:
> `log/plans/EP1-Entity-Face-Plan.md` (read it first; this file is the "where are we" layer).
> **Next up: W2 (World rebuild).** W0 done, W1 done and committed, W3/W4 not started.

## State at handoff (S234 close, 2026-09-26)
- [x] **W0** Cloudflare unblocked (B-12 resolved): token re-minted, secrets on World/Aether/NeBuLA/sCoRE/
  ScRiBbLE/Chrysalis. World `63f8d3d` (`_redirects` setup.sh + RaBbLE-OS.ks, `.assetsignore`, dispatch),
  Chrysalis `78d174d` (chrysalis.joinrabble.world live), sCoRE `ab823d6` (keep-warm cron `*/10` live,
  CORS for dev + chrysalis live after a manual Render deploy), ScRiBbLE `61eb3a9` (scribble.joinrabble.world live).
- [x] **D4** off-palette hexes swapped to closest canonical; candidates in `RaBbLE-Agent/RaBbLE-Palette-Candidates.md`.
- [x] **W1** NeBuLA `c7f0229`: `<rabble-entity backend="alive">` (`src/backends/alive-backend.js`),
  fat lines (`src/utils/three-fatlines.js`, three@0.160 jsm wrapped as `installFatLines(THREE)`),
  `palette.js` reads Aether's real names + `readPalette(el)`, `src/version.js`, lab page
  `examples/alive.html`, Playwright suite `test/alive.playwright.mjs`. Port provenance: BaBbLE
  `prototypes/alive-port/` (local commit `30ffb84`; BaBbLE has no remote).
- [ ] **W1 leftovers:** rewrite `RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md` (Grimoire) from the contract below;
  vendor the bundle into World (`cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`) as
  part of W2; publish to nebula.joinrabble.world only at air.
- [ ] **W2** World five-beat surface (not started). [ ] **W3** Grimoire truth-alignment. [ ] **W4** accounts doc.
- [ ] **Mark:** eyeball the entity on real hardware (lab URL below). Headless tests ran on swiftshader at ~5 fps,
  so motion smoothness, spring feel and the 60 FPS target are UNVERIFIED on a real GPU.

## Verified (Playwright, S234; screenshots were in BaBbLE/tmp/alive/shots, gitignored)
Desktop 1280×800: dormant before boot · boot holds at t=7.4 while a step is pending · a tap during the hold
does not skip it · completes after the step settles · states listening/speaking · moods ponder/process/insight ·
setPortals violet/pink and rejects identical poles · 3D engages with fat lines on three 0.160 · dispose removes
the stage · no page errors. **16 PASS / 1 FAIL.** iPhone 15 portrait (safe areas simulated via `--rbl-safe-*`,
Dynamic Island drawn): PASS boot text clear of island + home indicator (top 395 px, bottom 582 px of 852).
**FAIL, open:** "failed step still completes boot" on the iPhone 15 profile. The check's 120 s `until(boot.done)`
expired at 3x DPR under swiftshader; most likely just slow (the desktop run completes via the same settleStep path),
but NOT proven. Re-run at deviceScaleFactor 1, or on a real device, before W2 relies on the offline path.
iPhone landscape pass never ran (run stopped at session close).

## The contract W2 codes against
```
<rabble-entity backend="alive" autonomous="true" dimension="2d" portal-a="cyan" portal-b="magenta">
  el.boot({steps:[{id,label}]}) -> Promise (resolves at boot complete, after the slide to center)
  el.completeStep(id) / el.failStep(id, reason)   // pushes "[ OK ] Started <label>" / "[FAILED]" into the boot log
  el.setState('idle'|'listening'|'speaking')      // Aether portal flip; 'thinking' = idle + mood process (legacy)
  el.setMood('idle'|'ponder'|'process'|'insight'|'curious', {hold})  // host-held until changed; insight self-ends 2.8 s
  el.setEmotion('calm'|'joy'|'sad'|'angry', {hold})
  el.setPortals(a, b) -> bool   // palette names or canonical hexes; must differ (pole opposition)
  el.pulse('spark'|'bolt'|'ring'|'flash'|'shock') · el.attend(clientX, clientY) · el.setDimension('2d'|'3d') · el.skip()
  el.getSnapshot() -> {state,mood,emotion,dimension,boot:{started,t,holding,ready,done,steps},portals,quality}
  events on the element: entity-boot-start · entity-boot-step · entity-boot-hold · entity-boot-ready ·
    entity-boot-complete · entity-state · entity-portals · entity-notice ; window: rabble:entity-state (legacy)
  attributes: autoboot, autonomous, dimension, interactive, track-window, hold-to-listen, skippable,
    step-timeout (default 45 s, then pending steps auto-fail), tagline, ready-line; live: state/mood/emotion/
    dimension/portal-a/portal-b
```
- Host must size the element (e.g. `rabble-entity{position:fixed;inset:0}`); the alive stage fills it and
  paints the whole scene (field, grid, face). The element only sets `position:relative` if it is `static`.
- Boot layout: landscape puts the entity in the LEFT quarter and the boot text column right of center;
  portrait puts the entity high and the text at 60% of the usable height. Keep those zones clear until
  `entity-boot-complete`; then the entity sits centered (portrait scale 1.35).
- Safe areas: the renderer reads `env(safe-area-inset-*)` through a probe (override with `--rbl-safe-top` etc.)
  and centers in the usable area. World must still use `viewport-fit=cover` and pad its own chat/nav UI with
  `env(safe-area-inset-*)`. Mobile target: **iPhone 15** (393×852, top inset ~59 px Dynamic Island, bottom ~34 px).
- Curator mapping: typing → `setState('listening')`; awaiting first token → `setMood('process')`;
  streaming → `setState('speaking')`; done → `setState('idle')` + `setMood('insight')`.
- Legacy `setEntityState`, `triggerBoot`, `injectEyeJolt`, `setEntropy` still work on the alive backend.

## W2 next steps (from the plan, grounded)
1. `RaBbLE-config.js:67` fires `/health` fire-and-forget; export it as `window.RABBLE_HEALTH` (a Promise) and
   fire it locally too. Boot steps: `aether` (Aether CSS loaded), `nebula` (element upgraded), `score`
   (RABBLE_HEALTH 200). No invented steps.
2. Rebuild `RaBbLE-World/index.html` as Arrive → Boot → Meet → Summon → Enter (plan W2 table). Reuse
   `RaBbLE-curator.js` (make it retry after a cold start instead of latching offline, ~line 150) and the presence
   chip from `RaBbLE-face.js`. Summon beat = `setPortals` preview only, "claim it in Exodus", no persistence.
3. Retire to Chrysalis (`Chrysalis-Web/ep1/world/`): the S203 face (World `2434da6`), `summon.html`,
   `RaBbLE-summon.js`, `RaBbLE-account.js`.
4. Vendor the NeBuLA bundle, push `new-horizons` → dev.joinrabble.world deploys; verify with Playwright at
   1280×800 and iPhone 15 (portrait + landscape, simulated insets), then Mark signs off on dev (G10).

## How to run things
- Dev server: `bash RaBbLE-Grimoire/spells/dev-serve.sh` → **http://localhost:8080** (not 8000; it also opens
  Firefox). In a non-interactive shell its esbuild watchers exit immediately, so run `npm run build:iife` by hand.
- Entity lab: http://localhost:8080/examples/alive.html (`?autoboot=1&delay=<s>&fail=1&dim=3d&auto=0`)
  — `/examples/` route added to `spells/dev-cdn.js` this session.
- Tests: `PLAYWRIGHT=~/.npm/_npx/218f5d799962bf90/node_modules/playwright node RaBbLE-NeBuLA/test/alive.playwright.mjs`
  (that copy matches installed chromium 1228; newer npx copies want a browser that isn't installed).
  Headless is slow: the suite waits on entity state, never wall time. Screenshot timeout is 90 s.

## Gotchas
- Bundle grew 69 KB → 199 KB (alive renderer + 26 KB fat lines). Fat lines could lazy-load with 3D later.
- Render did NOT auto-redeploy on `render-ctl.sh env-set` or a push to sCoRE `new-horizons` (last auto deploy
  2026-06-26). After any sCoRE env/code change: `bash spells/render-ctl.sh deploy --wait`, then verify with a GET
  (`/health` rejects HEAD with 405).
- Never echo the CF token; pipe it from `RaBbLE-Grimoire/.cloudflare/config` into `gh secret set`.
- Aether still publishes `--rabble-void` (#03000b) and `--rabble-dimmer` (#3d3860), not in Palette.md; the
  alive port uses the canonical swaps instead (Air-Push C3 decides their fate).
- `/api/v1/users/summon` EXISTS in sCoRE (invite-gated, users on ephemeral `/tmp`); retire the World page anyway.
- No hex in World CSS; no invented hex anywhere. No em dashes in web copy.
- Prod deploys only from `main`; `new-horizons` → dev.joinrabble.world.
- `end-session.sh` mislabels LATEST as S199: diff after running.
- Pin `model: "sonnet"` on sub-agents.
