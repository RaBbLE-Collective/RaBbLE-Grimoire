# HANDOFF-S234 — EP1 Entity Face

> Cold start for any agent picking up the EP1 face push. Plan of record:
> `log/plans/EP1-Entity-Face-Plan.md` (read it first; this file is the "where are we" layer).

## Read first (in order)
1. `log/plans/EP1-Entity-Face-Plan.md` — decisions D1–D4, workstreams W0–W4.
2. `RaBbLE-BaBbLE/reliquary/2026-09-26-entity-harness/RaBbLE · The Entity (alive).html` — the
   renderer to port (single file, 961 lines of shared globals; EP1 wraps it whole in `createAlive()`, split is post-air; key symbols: `C`, `BOOT`, `EXPR`, `LOG`, `bootStep`,
   `setMode`, `init3D`, `drawFace`, `autoTick`).
3. `RaBbLE-NeBuLA/specs/rig/` + `RaBbLE-Aether/RaBbLE-Entity-Visual-Spec.md` — mood state machine
   + invariants (portal asymmetry, pole opposition).
4. `RaBbLE-NeBuLA/src/element.js` (current `<rabble-entity>`), `src/utils/three-loader.js`,
   `src/puppet/palette.js`.
5. `RaBbLE-World/index.html`, `world/js/RaBbLE-curator.js` (chat SSE), `RaBbLE-config.js`.

## State at handoff (S234, 2026-09-26)
- [x] W0.1 Mark minted CF token (B-12 resolved S234)
- [x] W0.5b dev + chrysalis origins in sCoRE `FRONTEND_URL` (sCoRE ab823d6 + Render env)
- [x] W0.2–6 secrets synced ×6; World 63f8d3d (_redirects, .assetsignore); Chrysalis 78d174d
  (chrysalis.joinrabble.world); sCoRE ab823d6 (keep-warm cron live); ScRiBbLE 61eb3a9 (scribble.joinrabble.world)
- [ ] W1-contract committed in NeBuLA
- [ ] W1-port · [ ] W2 · [ ] W3 · [ ] W4
- [x] D4: swap to closest canonical; novel hexes → `RaBbLE-Agent/RaBbLE-Palette-Candidates.md`

## Gotchas
- Opus review (S234) corrected the plan: `/api/v1/users/summon` EXISTS (invite-gated, ephemeral);
  Three.js 0.160 vs alive's r128 lines is real work; `puppet/palette.js` reads the wrong var names.
- Render did NOT auto-redeploy on `render-ctl.sh env-set` or on a push to sCoRE `new-horizons`
  (S234: last deploy was 2026-06-26). After any sCoRE env/code change run
  `bash spells/render-ctl.sh deploy --wait`, then verify with a GET (`/health` rejects HEAD, 405).
- Never echo the CF token; pipe from the config file into `gh secret set`.
- Build before testing NeBuLA in World: `npm run build:iife && cp dist/nebula.iife.js
  ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`. Use `spells/dev-serve.sh`, not ad-hoc servers.
- NeBuLA effects mounts force host `position` inline: wrap in a fixed div.
- No hex in World CSS; no invented hex anywhere (palette = `RaBbLE-Agent/RaBbLE-Palette.md`).
- No em dashes in web copy.
- Prod deploys only from `main` (World `deploy.yml`); `new-horizons` → dev.joinrabble.world.
- `end-session.sh` mislabels LATEST as S199: diff after running.
- Pin `model: "sonnet"` on sub-agents.
