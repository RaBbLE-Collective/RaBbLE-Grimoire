# Inventory: RaBbLE-World

**Answer: the Portal's entity today = `<rabble-entity id="faceEntity" backend="alive" autonomous="true" dimension="2d" portal-a="cyan" portal-b="magenta" ready-line="awake. hello.">` at RaBbLE-World/index.html:35-42. NeBuLA alive backend (src/backends/alive-backend.js, createAlive), 2D. Loaded from CDN https://nebula.joinrabble.world/v0.1.0/nebula.iife.js in prod (RaBbLE-config.js:24), /nebula/v0.0.0.0/nebula.iife.js (NeBuLA dist via dev-serve) locally (config.js:36,51), via world/js/RaBbLE-nebula-loader.js:14-15 (document.write). Driven by world/js/RaBbLE-face.js (boot/mood contract).**

| File | Draws/mounts | Backend + attrs | Spec | Last commit | Importers | Copies | URL |
|---|---|---|---|---|---|---|---|
| index.html:35-42 | the entity, full-page | alive; autonomous, dimension=2d, portal-a=cyan, portal-b=magenta, ready-line | EP1-Entity-Face-Plan.md (W2) (index.html:30) | 2026-11-17 | loads nebula-loader (:22), face.js (:136) | none | joinrabble.world/ |
| world/account.html:72 | entity `#acctEntity` | alive; autonomous, dimension=2d, portal-a/b | none cited | 2026-11-18 | nebula-loader (:10) | none | joinrabble.world/world/account.html |
| world/RaBbLE-Catalog.html:765-771 | `#catalogEntity` demo | default (canvas2d, no backend attr); mode=idle particle-count=180 overscan=1.8. Also NeBuLA.ui.createEntityMini/GrimoireEye/AmbientEye/GrimoireRing demos (:838-886) | catalog of NeBuLA elements | 2026-11-13 | nebula-loader (:16) | none | /world/RaBbLE-Catalog.html |
| world/js/RaBbLE-face.js | drives the alive entity (boot steps, boot(), moods); no drawing | alive (header :3) | EP1 face plan | 2026-11-17 | index.html:136 | none | n/a |
| world/js/RaBbLE-nebula-loader.js | mounts NeBuLA bundle; failure banner | CDN vs dist chosen by config | n/a | 2026-11-11 | index, account, Catalog | none | n/a |
| world/css/RaBbLE-face.css | layout of `body.face rabble-entity` (:32), portal-colour bezel (:206) | n/a | n/a | 2026-11-17 | index.html | none | n/a |
| world/js/RaBbLE-floor.js (883 lines) | HAND-ROLLED Three.js: draws its own entity eye (tall pill EYE_W 18 x EYE_H 52, gap 38, :119-123), portal arcs/fills/glow layers (:201-205, :486-487), blink (:457-476), plus knowledge-graph nodes (:41-48). Comment: constants copied from threejs-backend.js eyeConfig x100. | none (own THREE scene, CDN three r160) | none | 2026-06-18 | **no importer found**: only AGENT.md:50, CONTEXT.md:72-74 mention it; no HTML loads it; RaBbLE-stage.js/movements/pages also unreferenced by any page | md5 2382c90c... vs NeBuLA src/elements/floor.js 38836425...: DIFFERENT (883 vs 717 lines); forked | not served |
| world/js/RaBbLE-stage.js | RC1 movement chrome; looks up a `rabble-entity` in `#entity-stage` (:30) | n/a | RC1 | 2026-06-26 | not loaded by any page (grep) | none | n/a |
| world/js/RaBbLE-account*.js, session, curator, movements-data, Grimoire-Data, catalog-page, tests/test_account_portal.py | grep hits are "portal"=login/site or "eye" words, not entity drawing | n/a | n/a | n/a | n/a | n/a | n/a |

## Notes / plan corrections
- Plan row "World floor: check: scaffold, not the entity" -> verdict: it is NOT scaffold-only; it is a dead, forked hand-rolled entity-eye + graph renderer (Jun 2026, pre-alive), with no live importer. Retire/archive (pointer left), or fold into NeBuLA floor.js. Needs Mark's sign-off. (Dead-ness is by grep of World repo only; confirm no external loader.)
- World contains no other hand-rolled entity drawing; no boot page (boot/face is index.html + face.js on alive).
- Plan's "Portal" is thus alive backend, not Canvas2D: plan says Canvas2D is the canonical web path; the live Portal uses `alive` (and the plan row "alive: decide merge or keep" matters most for World). Catalog demo uses canvas2d default.
- Prod pins NeBuLA v0.1.0; CDN not fetched/verified live here. Pre-existing World instruction: World is scaffold only; NeBuLA owns rendering (memory).
- Correction: Catalog loads only RaBbLE-pages.js (:1622); no page loads floor/stage/movements, so floor.js stays unmounted (pages.js refs checked: see grep).
