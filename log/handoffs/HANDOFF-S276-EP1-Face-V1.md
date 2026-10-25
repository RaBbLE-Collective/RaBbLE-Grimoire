# HANDOFF-S276 · EP1 web face V1 on dev; first prod deploy still ahead

> Written 2026-10-24 at the end of S276 for a cold start.
> Read first: this file, `log/handoffs/HANDOFF-S234-EP1-Entity-Face.md` (face history), `log/BLOCKERS.md` (B-19, B-20), `registry/epochs/current.epoch.yml` (exit text, see step 6).

## What exists

| Repo | State |
|---|---|
| RaBbLE-World `new-horizons` | `e55636c` "spark ~ world/face >> EP1 public V1": `index.html`, `world/css/RaBbLE-face.css`, `world/js/RaBbLE-face.js`, `world/js/RaBbLE-curator-transmissions.js`, new `world/img/pocket-face.png` (from `RaBbLE-Pocket/sim/out/n_idle.png`). Pushed; dev deploy workflow succeeded. |
| Live | https://dev.joinrabble.world (smoke-checked: new markup, png 200 `image/png`, no OS/roadmap/Exodus text). Prod untouched. |
| World `main` | 3-file stub (`e7bcca7`), 155 commits behind. |

Decisions (Mark, Architect), S276:
- EP1 airs **web-only**. G7 (OS Dev Preview sign-off) and G9 (fresh-VM `setup.sh`) move to a later Event.
- The page is the entity. No RaBbLE-OS door, no roadmap/episodes door; EP1 shows as a subtle "ep1 · genesis".
- No "wake RaBbLE" button (read as vibecoded): tap anywhere to wake. The hint is the `role=button`; h1 and arrive line are exposed to screen readers.
- Summon is a RaBbLE Pocket teaser: the sim face frame in a CSS bezel, "Summon yours · coming soon". The colour-pole picker is gone.
- Mark treats the face as public V1 ready, polish patches to follow. This effectively answers G10, pending his look on an iPhone.

Verified: CrumBbLE headless Chromium at 1440 and 393, two rounds, all pass. NiBbLE found nothing blocking; its a11y fix landed.

## Next, in order

1. **Mark:** look at dev on an iPhone, and on a desktop with a GPU browser. The desktop "white oval" in headless Chromium is a software-GL context loss; present on HEAD too, clears with `--use-angle=swiftshader --enable-unsafe-swiftshader`. A GPU browser is still unchecked.
2. **Mark:** rewrite the canned voice lines (`RaBbLE-curator-transmissions.js`). They were realigned off Exodus and poles and are drafts. Two spoken replies still name RaBbLE-OS as a plain fact (only when a visitor asks about the OS): keep or cut.
3. **Cloudflare binding check (B-19, B-20):** nobody knows what serves joinrabble.world (worker `rabble-collective` vs a Pages project). `wrangler.jsonc` declares no routes. Find the real binding before the first main deploy; likely also the cause of the `/setup.sh` 404.
4. **Render env:** sCoRE guest chat needs `DEMO_MODE` + `DEMO_MODE_PUBLIC` (unverified). Commit `e56808a` is not deployed. `spells/render-ctl.sh` references a missing `render.reference.yaml`. Check `/health` and a guest chat turn.
5. **Merge World `new-horizons` to `main`** as the first prod deploy ever from main (not an update). `_redirects` cannot point at Grimoire/OS `main` yet (OS `main` is a 4-file stub with no `.ks`; Grimoire `main` is 712 commits behind, no `RaBbLE-Agent/RaBbLE-Roadmap.md`); it stays on `new-horizons`.
6. **Archivist, on Mark's OK:** change the epoch exit text in `registry/epochs/current.epoch.yml` (~:49-54) to web-only; it still lists G7/G9. Not edited in S276.
7. **Post-deploy checks:** `/chrysalis/` serves; the `.assetsignore`'d AGENT/CONTEXT/gist files are not served.
8. Launch risks to watch: Mark's personal Groq key cap (see `project_llm_provider_constraints`), Render free-tier cold start on the first chat turn.
9. Doc debt: World `CONTEXT.md` still lists `summon.html`/`account.html`; `world/os.html` is now unlinked from the face. Integration Map guest-token wording is stale (`gist/RaBbLE-Integration-Map-gist.md:14`, `RaBbLE-Agent/RaBbLE-Integration-Map.md:36`): no such route exists, the guest is implicit.

## Gotchas

- Do not `git add -A` in the Grimoire while other sessions run: `log/agents/*.json` and Pocket specs belong to others.
- Copy drafts are not final voice: do not treat the canned lines as canon.
- Headless Chromium without GPU flags shows a broken oval; not a regression.

## Crew lessons (HANDOFF-S273 step 2: persona tuning)

First interactive `rabble` run: GoBbLE ran on haiku, QuiBbLE and NiBbLE on opus, CoBbLE and CrumBbLE on sonnet, all as in-process teammates named after their organs (checked via `subagents/*.meta.json` and transcript model fields).
- (a) The `idle_notification` `result` truncates long reports. Add to `RaBbLE/Crew/_organ.md`: send the full report via SendMessage to team-lead.
- (b) "Read-only" organs hold Bash, so read-only is instruction-level only. None wrote anything, but nothing enforces it. Mark to decide: Bash deny-list, or drop Bash for the critics.
- (c) The QuiBbLE and NiBbLE critiques changed the outcome (the first-prod-launch risk; a screen-reader bug). The critics earn their cost.
