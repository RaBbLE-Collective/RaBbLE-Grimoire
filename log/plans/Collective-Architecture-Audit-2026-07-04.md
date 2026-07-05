# Collective Architecture Audit — 2026-07-04

**Status:** complete (recon + design only — zero code modified anywhere)
**Executed:** S193, per `Collective-Architecture-Audit-Plan.md` (S192) — fable-5 orchestrator + 8 scoped sub-agents (one per member, small members combined)
**Companion doc:** `sCoRE-Extensibility-Refactor-Plan.md` (the sCoRE deep-dive — options + tradeoffs)
**Relation to EP1:** findings only. Any implementation waits until after G7/G9 land, per the plan's own guardrail.

Every claim below carries a `file:line` citation from the sub-agent recon. Per-member sections each end with **Open decisions for Mark** — this doc proposes, it does not decide.

---

## Part 1 — Systemic patterns (cross-repo)

Seven patterns showed up in three or more members. These are Collective-level problems; fixing them member-by-member without a shared answer will just regrow them.

### SP-1. Doc claims outrun code, and nothing forces reconciliation

The single most repeated finding. Member `CONTEXT.md` files fossilize because nothing forces their refresh the way `end-session.sh --synopsis` forces the Grimoire LATEST box:

- World `CONTEXT.md` is an S53 fossil — its Structure table lists ~10 JS/CSS files and 6 pages that no longer exist (`RaBbLE-World/CONTEXT.md:55-72`), and mandates load-order rules for files that don't exist (`CONTEXT.md:35-48`).
- OS `CONTEXT.md` is 7+ weeks stale — claims active branch `RaBbLE/episode-I`, which does not exist (`RaBbLE-OS/CONTEXT.md:15-16`), and points at an in-repo `grimoire/` dir that was consolidated away (`CONTEXT.md:37-45`).
- sCoRE docs admit their central gap but the identity docs don't reflect the server half at all (see the companion deep-dive).
- Aether `CONTEXT.md` still says deploy is "Cloudflare R2 — Pending" while `.github/workflows/deploy.yml` + `wrangler.jsonc` show Workers deploy already live.
- NeBuLA is the extreme case: Grimoire's `RaBbLE-NeBuLA-API.md` documents `window.NeBuLA.createPuppet()` as the public API (10+ references); zero matches for `createPuppet` exist in `src/` — the real API is the `<rabble-entity>` element (`RaBbLE-NeBuLA/src/element.js:201-240`). The canonical doc describes a different architecture.
- Xperimental root `CONTEXT.md:15,23-26` still says "repo just scaffolded" while RaBbLE-Voice sits at Phase 2/7 with 32/32 tests passing.
- Chrysalis violates its own charter: docs say "nothing here runs, never add new code," yet `Chrysalis-Web/` is a live Cloudflare Workers site with 10 commits of feature work (2026-06-24/25) postdating those docs.

**Design proposal:** a lightweight convention, not tooling-first — add a `context-freshness` check to `spells/status.sh` (warn when a member's CONTEXT.md front-matter date is > N sessions old), and make "touch CONTEXT.md or state why not" part of the member-repo end-of-session ritual. Optionally a `spells/drift-check.sh` that greps each member CONTEXT.md Structure table against `ls` reality.

### SP-2. Palette discipline has no enforcement — three members forked hex silently

- OS invents four hex values in `ansible/inventory/group_vars/all.yml:22-29` (`#f7a8d4`, `#e8d5ff`, `#8860aa`, `#120025`) — and `#8860aa` is the exact "residual dim" color already open as a live KDE bug. The drift produced a symptom before the audit caught it. `config/gtk-3.0/gtk.css` uses the divergent set while `config/waybar/style.css` and `config/kitty/kitty.conf` use canon — themed surfaces disagree about what "muted" is.
- NeBuLA hardcodes off-Grimoire hex in ~8 files (`src/canvas2d/particle-system.js:2-6`, `src/effects/ambient-field.js:2-6` carry identical 16-color arrays; also `ui/entity-mini.js:18-23`, `portal-system.js:39`, `elements/floor.js:34-37`, `elements/graph.js:30-33`) — bypassing both of its own palette modules.
- Aether itself, the token owner, invents `--rabble-void` and `--rabble-dimmer` (`src/.../rabble-palette.css:58,67`) not present in Grimoire `Palette.md`, and carries one bare hex `--rabble-elevation-3: #222340` (`rabble-palette.css:101`) in the token source file.
- World is the counterexample: near-clean on live pages (only mask-composite `#fff` and the FOUC guard) — proof the discipline is achievable.

**Design proposal:** one `spells/palette-lint.sh` — grep member repos for hex literals, diff against `RaBbLE-Agent/RaBbLE-Palette.md`, allow-list the known-legit cases (mask gradients, FOUC guard). Run it in `status.sh`. This is the cheapest cross-member guard the audit surfaced.

### SP-3. Orphaned code rides along on every deploy — no member has orphan detection

- sCoRE: `server/jane.py` (440 lines, ~14% of server/ — a full physio-clinic EMR integration from a pre-RaBbLE product) and `server/actions.py` (67 lines) are imported by nothing, shipped to Render on every deploy.
- World: 7 of 16 JS files — 2,526 of 4,318 lines, 59% — are orphaned RC1-era code loaded by no page, including the single worst boundary violation in the Collective (`world/js/RaBbLE-floor.js`, an 883-line Three.js renderer with NeBuLA constants copied in, admitted at `RaBbLE-floor.js:120`). Plus 3 orphaned CSS files.
- OS: quickshell is a ghost member — role, site.yml play, dotctl bundle, and branch all exist; every task file is a stub and the manifest has no quickshell package. The site.yml "Dotfiles — Symlink pass" play routes exclusively to debug-msg stubs.
- NeBuLA: `dist/v0.0.0.1-rc.1/` is a stale frozen snapshot at ~60% the size of the current bundle, missing the entire Three.js entity feature — worth confirming it isn't CDN-published.

**Design proposal:** orphan sweeps are one-off cleanups (member sections below), but the pattern-level fix is a habit: any absorb/refactor commit that strands files must either delete them or reliquary them (condense-not-delete), same session. World's S190 liminal replacement and sCoRE's `b08a21f` absorption both stranded code silently.

### SP-4. Duplicated logic where a single owner is implied

- NeBuLA internal: `elements/floor.js` (717 lines) and `elements/graph.js` (566 lines) are near-total duplicates (identical function suites, `floor.js:74-390` vs `graph.js:70-325`), and neither uses the shared `eye-behavior.js` module that the two backends correctly share — three parallel eye/portal implementations. Two competing palette-resolution modules (`src/puppet/palette.js:24-37` vs `src/effects/_palette.js:13-17`) hardcode the same 5 fallbacks twice.
- sCoRE: `tools.py` and `grimoire.py` independently reimplement Grimoire gist-dir auto-discovery.
- OS: every package list is hand-duplicated 2–3× between the manifest and Ansible roles (SP-5 below); ANSI palette codes re-declared verbatim in each ctl script.
- The root lesson from the S182 World refactor — *apply, don't redefine* — applies inside members, not just between them.

### SP-5. "Single source of truth" claims that aren't wired

- OS manifest: claimed as SSoT in three places (`ansible/packages/manifest.yml:4`, `AGENT.md:18`, AgentGuide:97-100); in reality only `spells/generate-kickstart.py:27` consumes it. Zero Ansible roles read it; every role hand-duplicates its list; ~50 installed packages (virtualization, monitoring, most of runtime) are missing from it entirely.
- World/NeBuLA delivery: Integration-Map says "World consumes only CDN bundles" — since S190 the bundle is vendored into the repo (`world/js/RaBbLE-NeBuLA.js` *is* the IIFE build output, not a loader, contradicting `RaBbLE-World/AGENT.md:44`) and `RABBLE_NEBULA_URL` / `RABBLE_THREE_URL` / `RABBLE_RENDER_BACKEND` in `RaBbLE-config.js` have **zero consumers** (`RaBbLE-liminal.js:349` hardcodes the backend).
- Aether: README's CDN install URL points at a `/v0.0.0.1-rc.1/` subpath that CI never builds (deploy.yml runs flat `npm run build`; `build:versioned` is never invoked) — the documented install path likely 404s.

**Design proposal:** each "X is the single source" claim needs either the wiring or a rewrite of the claim. Flag per-member below; the choice is Mark's each time.

### SP-6. No automated tests or CI guards anywhere in the code members

sCoRE: manual smoke scripts only, no pytest, no CI. NeBuLA: `test/` contains a `.gitkeep`, despite an explicit 60fps/1000-entity performance contract in its AGENT.md. World: deploy-only workflow, no lint for hex/.rc-/orphan creep. Aether: no build verification pairing dev+prod bundles (prod bundle is ~8h staler than dev). The only tests in the Collective are in a sandbox rablet (RaBbLE-Voice, 32/32).

**Design proposal:** don't scaffold test suites wholesale (low-entropy rule). Pick the single highest-leverage guard per member: sCoRE = pytest smoke of the route table; NeBuLA = a headless render-smoke; World/Aether = lint-style greps in CI. Sequence after G7/G9.

### SP-7. Version and registry canon drift

- Grimoire's own member lists disagree five ways: 10 manifests vs 9 in `CONTEXT.md:63` and `INDEX.md:104` vs 8 in `AGENT.md:159-170` vs 11 rows in `status.sh`.
- Aether states four different versions in one repo (README `v0.0.0.1-rc.1`, package.json `0.0.0.0`, CONTEXT `v0.0.0.0`, rabble-palette.json `0.0.0.1`) — violating "stay v0.0.0 until EP1 airs."
- OS: KS installs Fedora 44 (`RaBbLE-OS.ks:7,22,50`) while identity says Fedora 43 (`AGENT.md:8`, `group_vars/all.yml`); three install roots coexist (`~/RaBbLE` from KS at `RaBbLE-OS.ks:102`, `~/RaBbLE-OS` from legacy Install.sh:31, `~/RaBbLE-Collective` by convention).
- RaBbLE-Captures exists as a directory but has no manifest, no epoch entry, no index section — and the canonical doc (`RaBbLE-Captures-System.md:10`) says it was folded into BaBbLE at S92, yet a new capture landed there 2026-07-02 (likely a stale OS screenshot keybind, silently orphaning captures from triage).

---

## Part 2 — Per-member findings + design-improvement plans

### 2.1 RaBbLE-Grimoire (knowledge layer — audited for drift, not code)

Mechanics are healthy (gist regeneration, blocker ledger, spell honesty). The registry and EP1 canon have drifted:

1. Five member lists disagree (SP-7 above).
2. Captures has no registry existence anywhere despite being treated as a member in the audit plan itself (`Collective-Architecture-Audit-Plan.md:26`).
3. Xperimental manifest still says "GitHub repo to be created / scaffold pending" though it's cloned and on new-horizons since S189.
4. Four manifests carry wrong "Active branch" notes (Aether:32, NeBuLA:35, World:37 say `dev`; OS:27) vs epoch `active_branch: new-horizons`.
5. `current.epoch.yml:99-101` World blocker note lists B-01/B-03/B-04 — all resolved S153; real open set is B-02/B-09/B-10. Epoch `episode_name` "First Integrated Release" (line 7) contradicts the canonical name **Genesis**.
6. The "CANONICAL" Episode-1-Release-Map (lines 30-31, stale since 2026-05-24) still calls sCoRE/World "Planned" on "Railway/Render" — so Episode1-gist contradicts Roadmap-gist inside the same orientation bundle agents read first. `Roadmap.md:26` still targets 2026-Q2.
7. INDEX "Plans (active)" and `log/plans/CONTEXT.md` contradict each other; `OS-ProArt-Power-Stack-Plan.md` is unindexed AND untracked in git.
8. Spent RaBbLE-Voice-Phase2 handoff sits unindexed in pending; INDEX.md:204 + CONTEXT.md:70 still mark the RC1 Guided Realm build "ACTIVE" though S190's liminal passage superseded it.
9. `SPELLS.md` missing 6 spells (chat-bridge.py, chat-local.sh, fcc-ctl.sh, groq-ctl.sh, openrouter-ctl.sh, sync-gists-to-world.sh); broken INDEX link (`RaBbLE-World/assets/`, INDEX.md:208); misfiled docs (DEBUG-SESSION in Aether's doc home, `sCoRE-Local-AI-Layer.md` unprefixed, TaskViSoR docs under RaBbLE-Collective/).

**Improvement plan:** one "registry reconciliation" session — single pass to align the five member lists, add-or-explicitly-retire Captures, refresh the four manifest branch notes and Xperimental status, fix the epoch blocker note + episode_name, re-stamp the Release-Map against current reality, reconcile INDEX vs plans/CONTEXT, index or archive the strays, complete SPELLS.md. All mechanical; no design decisions except the two below.

**Open decisions for Mark:**
- Captures: register as a member (manifest + epoch row) or finish the S92 fold into BaBbLE and fix the OS keybind writing to the stale path?
- Episode-1-Release-Map: re-stamp as canonical after refresh, or demote it (the epoch YAML + BLOCKERS.md now carry the live truth)?

### 2.2 RaBbLE-sCoRE (deep-dive target)

Full evidence and 3 restructuring options live in the companion doc `sCoRE-Extensibility-Refactor-Plan.md`. Headline findings: `server/` is 16 flat files / 3,132 lines with a real auth circular import (`auth.py:48` ↔ `auth_routes.py:11`), a god-module (`main.py` imports 11 of 15 modules), two fully orphaned files (`jane.py`, `actions.py` — 507 lines from a pre-RaBbLE clinic product, commit `b08a21f`), three incompatible persistence strategies for conversation-shaped state, ~25 undocumented env vars, an undocumented route table, no tests, and stale Railway artifacts. Open decisions are in that doc.

### 2.3 RaBbLE-World

Verdict from recon: **the 5 live pages are close to clean; the repo around them is not.**

- 59% of `world/js/` orphaned (SP-3), including `RaBbLE-floor.js` (the copied-NeBuLA-renderer violation) — all deleted-for-free once the orphan sweep lands.
- Both S182 open items untouched: `.rc-*` is still load-bearing (95 `--rc-*` tokens + 78 `.rc-` selectors; three live pages link `RaBbLE-unified.css` — `world/os.html:18`, `world/account.html:27`, `world/summon.html:19`), and Three.js is pinned in three places with the config flips dead (SP-5).
- Live-page leaks: `RaBbLE-liminal.js:219-283` draws bespoke Canvas2D constellation lines (belongs in NeBuLA as an effect); `@keyframes` in five page CSS files against `CONTEXT.md:27`; inline scripts/styles on every page against `CONTEXT.md:21`; Catalog carries a 338-line inline style block (`world/RaBbLE-Catalog.html:17`).
- A committed, stale, 9-file `gist/` copy of Grimoire gists (all differ from current Grimoire) — against "Grimoire consumed, not copied."
- `wrangler.jsonc` serves the whole repo: AGENT.md, CONTEXT.md, stale gists, scripts are all publicly served on joinrabble.world (`.assetsignore` excludes only .git/.gitignore/node_modules/*.log).

**Improvement plan (ordered):** (1) orphan sweep — reliquary the 7 JS + 3 CSS files per condense-not-delete; (2) rewrite CONTEXT.md, patch AGENT.md (liminal files, NeBuLA.js true nature) and README pages table; (3) tighten `.assetsignore`; (4) plan the `.rc-*` retirement as a real migration (it's 3 live pages, not a deletion); (5) move the constellation renderer into NeBuLA; (6) resolve the NeBuLA delivery story (decision below).

**Open decisions for Mark:**
- NeBuLA delivery: commit to the vendored bundle (then delete the dead `RABBLE_NEBULA_URL`/`RABBLE_THREE_URL` flips and update Integration-Map) or return to CDN (then restore a real loader)? Today both are documented, one is real.
- Serve-the-repo: is publicly serving AGENT.md/CONTEXT.md/gists on joinrabble.world acceptable (they're public repos anyway) or should `.assetsignore` gate to `world/` + `index.html`?
- `.rc-*` retirement timing: pre- or post-EP1? It touches all three non-index live pages.

### 2.4 RaBbLE-Aether

- Four conflicting version strings in one repo (SP-7); the 4-segment package.json version is also incompatible with npm tooling the README implies.
- README CDN install URL likely 404s (versioned build never runs in CI — SP-5).
- CONTEXT.md deploy status and Structure table stale (nonexistent `src/assets/palette.entry.css`; two of five bundled files omitted).
- Prod bundle `dist/aether.min.css` ~8h staler than dev `dist/aether.css` — no pairing guard.
- Token-owner discipline: two invented tokens + one bare hex in the token source (SP-2); `.rc-*` compat layer (~30-var alias block + 3 class families, `rabble-components.css:919-1631`) still shipping, marked "remove after World P4."
- Second hand-maintained entry point `rabble.css` drifts from `src/entry.css` (missing base/theme imports).

**Improvement plan:** (1) pick one version string and align all four surfaces to the v0.0.0 convention; (2) fix README install path to match what CI actually publishes (or wire `build:versioned` into CI); (3) refresh CONTEXT.md; (4) add a build step or pre-commit that rebuilds both bundles together; (5) either add `--rabble-void`/`--rabble-dimmer` to Palette.md or remove them, and tokenize `--rabble-elevation-3`; (6) delete or generate `rabble.css`; (7) `.rc-*` alias drop rides on World's migration (2.3).

**Open decisions for Mark:**
- Versioning: is `0.0.0.0` (package.json) the canon until EP1 airs? If so the README rc tag and palette JSON both walk back.
- `--rabble-void`/`--rabble-dimmer`: promote into Palette.md (Aether proposes, Palette ratifies) or purge?

### 2.5 RaBbLE-NeBuLA

- Canonical API doc describes a nonexistent `createPuppet()` API — inverse drift, worst doc/code mismatch in the Collective (SP-1).
- `elements/floor.js` + `elements/graph.js` near-duplicates; neither uses the shared `eye-behavior.js` soul module — three parallel eye/portal implementations (SP-4).
- Two competing palette modules + ~8 files hardcoding off-Grimoire hex against its own AGENT.md rule (SP-2, SP-4).
- Stale "P5 stub" comments (`src/index.js:5,20`) on fully-implemented doors/deepfield; `specs/render-gap-analysis.md` self-marked superseded but still in-repo (condense-not-delete applies).
- Zero tests against an explicit perf contract (SP-6); `dist/v0.0.0.1-rc.1/` stale snapshot (SP-3).
- `AnimationFilter` exported from `effects/index.js` but missing from `effects/effects-ns.js` — invisible on the actual `window.NeBuLA.effects` namespace.

**Improvement plan:** (1) rewrite `RaBbLE-NeBuLA-API.md` against the real element API (`src/element.js:201-240`); (2) extract the shared floor/graph geometry+eye suite into one module and route both elements (and ideally the liminal constellation effect arriving from World) through `eye-behavior.js`; (3) merge the two palette modules into one, then burn down the 8 hardcode sites against it; (4) fix the effects-ns export; (5) delete stale stub comments; condense render-gap-analysis into Grimoire; (6) confirm and remove/regenerate the stale dist snapshot; (7) smallest useful test = a headless boot-and-snapshot smoke.

**Open decisions for Mark:**
- Is the frozen `dist/v0.0.0.1-rc.1/` published anywhere (CDN/Workers)? If yes it's serving a 3-weeks-old entity; if no, delete it.
- Floor/graph unification: fold both into one parameterized element, or keep two elements over one shared internal module? (The latter preserves the public API.)

### 2.6 RaBbLE-OS

Top-level architecture is sound; the two load-bearing claims are false in code:

- Manifest-as-SSoT never wired (SP-5): one consumer, hand-duplicated role lists, ~50 packages missing, plus internal rot (duplicate `gh` at `manifest.yml:1042,1094`; undeclared `base`/`runtime` layers vs header `:15-26`; stale polkit FIXME at `:550-552`).
- dotctl copies, not symlinks (`RaBbLE-OS-dotctl.sh:281`), while AGENT.md:21 and site.yml say "symlink"; the whole site.yml dotfiles play is stub theater; `layerctl dotfiles` doesn't do what its label promises; hyprland role carries a broken `hypridle.conf` src path and a 1-of-8 scripts list that fails if anyone revives `config.yml`; quickshell ghost surfaces (SP-3). The *real* rule — "dotctl for user dotfiles, Ansible for system config" — is true in code and written nowhere.
- Palette drift with a live symptom (SP-2): four invented hex in `group_vars/all.yml:22-29`, gtk.css vs waybar/kitty disagreement, no `rabble_palette:` key despite the Palette doc claiming one, no generator tying `config/` hex to the palette source.
- Installer: three install roots + F43/F44 split + legacy Sway-era Install.sh still presented as first contact (`CONTEXT.md:27`) + Bootstrap defaulting any machine into ProArt hardware roles (`ansible/inventory/hosts.yml:15-21`).
- Doc staleness both sides: CONTEXT.md branch/paths fossils; AgentGuide "open bugs" already fixed (supergfxd, NVIDIA idempotency); protected `AiQuickstart.md` doesn't exist; AGENT.md omits `spells/` (12 scripts) entirely.
- Hygiene: two bug ledgers (root `ISSUES.md` vs Grimoire KnownIssues); Catppuccin theme files shipping beside Aether's; dotctl waybar post-apply silently editing `~/.claude/settings.json`/`~/.codex/config.toml` (correct merge behavior, surprising ownership); two wallpaper homes pointing different directions.

**Improvement plan (ordered):** (1) decide the manifest's fate (decision below) and in either case add the ~50 missing packages / fix rot; (2) delete the dead dotfiles plumbing (site.yml play, `*_tasks_only` vars, stale hyprland vars, quickshell ghosts) and codify the real dotctl/Ansible boundary in AGENT.md + AgentGuide; (3) reconcile the group_vars palette with canon and unify gtk.css — likely closes the `#8860aa` KDE bug for free; (4) archive Install.sh, converge on one install root, align the F43/F44 story with the planned Fedora44 upgrade doc, make Bootstrap's default inventory generic; (5) CONTEXT.md/AGENT.md/AgentGuide refresh; (6) merge the bug ledgers.

**Open decisions for Mark:**
- Manifest: wire Ansible roles to consume it (real SSoT — more work, one authoritative home) or demote it to "KS generator input + decision record" (honest, cheap)?
- Fedora 43 vs 44: is the KS's F44 jump intentional (upgrade underway) — should docs + `rabble_fedora_version` move now?
- Install root: converge KS on `~/RaBbLE-Collective` to match the dev convention?
- dotctl waybar post-apply's agent-config editing: keep (documented) or extract into an explicit `dotctl agents` verb?

### 2.7 RaBbLE-Xperimental (sandbox — audited for promotion candidates, not structure)

- One rablet: `rablets/RaBbLE-Voice` — active, Phase 2/7, 32/32 tests passing (the only automated tests in the Collective).
- Not yet member-worthy: core value unproven by its own admission (`CONTEXT.md:17`); Bark/Festival engine factories throw NotImplemented (`src/index.ts:31-40`).
- **Promote patterns, not code:** the six-emotion taxonomy + `SynthesisEngine` contract (`src/types.ts:8-71`) are stable interface design worth recording in Grimoire lore/architecture now, independent of the rablet's fate.
- Hygiene: root CONTEXT.md fossil ("just scaffolded"); no git remote and `main` 13 commits behind `new-horizons`; dead `tone` dep (`package.json:33`); `types` points at never-emitted `dist/bundle.d.ts` (`package.json:6`). Palette-compliant.

**Improvement plan:** record the SynthesisEngine contract + emotion taxonomy in Grimoire (one short doc); refresh root CONTEXT.md; push a remote or explicitly declare local-only. Leave the sandbox messy otherwise — that's its job.

**Open decisions for Mark:** does Voice continue toward memberhood after EP1, or park at Phase 2 with the contract preserved in Grimoire?

### 2.8 RaBbLE-BaBbLE (intake — audited lightly by design)

Healthy. Intake→signals→graduate flow coherent; reliquary duplication properly reduced to pointer stubs. Three small items: `_ROUTING.md:13,15` routes two signals to `RaBbLE-Grimoire/rfcs/`, which doesn't exist; `intake/Video.mov` untriaged since 2026-06-22; `tmp/` holds 20 files (06-25→07-03) never swept per its own Agent Scratch Rule.

**Open decision for Mark:** create `rfcs/` in Grimoire, or repoint the routing table?

### 2.9 RaBbLE-Chrysalis (archive — recon only, as chartered)

Charter violation: a live, actively-developed Cloudflare Workers site (`Chrysalis-Web/`, `wrangler.jsonc`, 10 commits 2026-06-24/25) inside the repo whose own AGENT.md/README say "nothing here runs, never add new code." README.md:19-31 also still claims `Python-Xperiments/`/`JS-Xperiments/` at root; they moved under `Chrysalis-Web/` in that same reorg.

**Open decision for Mark:** is Chrysalis-Web meant to live here (then amend the charter: "archive + its memorial site") or should it move (Xperimental rablet? World subdomain per the S186 registry?) so the reliquary stays sealed?

### 2.10 RaBbLE-Captures (utility)

Not actually a repo — an untracked directory inside the Collective root's git tree, gitignored as "Dev artifacts." Canonical doc says it was folded into `RaBbLE-BaBbLE/captures/` at S92 (`RaBbLE-Captures-System.md:10`), yet a capture landed there 2026-07-02 — an OS screenshot keybind still writes to the stale path, silently orphaning captures from triage. Decision folded into 2.1 (Grimoire registry) above; the code-side fix is one keybind path in RaBbLE-OS config.

---

## Part 3 — Suggested sequencing (post-G7/G9, all subject to Mark's call)

1. **Zero-risk cleanups** (deletes/doc fixes, no behavior change): World orphan sweep · sCoRE orphan decision · Grimoire registry reconciliation · stale-comment/doc fixes across members.
2. **Truth alignment** (make claims match code): NeBuLA API doc rewrite · World/NeBuLA delivery decision · OS manifest decision · Aether version alignment.
3. **Guards** (cheap, prevent regrowth): palette-lint spell · context-freshness check · per-member single highest-leverage test.
4. **Restructures** (the only risky tier): sCoRE server/ refactor (companion doc) · NeBuLA floor/graph unification · OS dotfiles-plumbing removal · `.rc-*` migration.

## Deliverables from this audit (for Mark to add to INDEX.md — not self-added, per plan)

- `log/plans/Collective-Architecture-Audit-2026-07-04.md` (this doc) — under "Plans (active)"
- `log/plans/sCoRE-Extensibility-Refactor-Plan.md` — under "Plans (active)"

Raw sub-agent findings live in the session scratchpad (ephemeral); everything load-bearing is cited inline above.
