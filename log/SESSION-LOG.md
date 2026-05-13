# SESSION-LOG.md — RaBbLE Collective

Running log of significant sessions. Most recent at top.
Format: date, what was done, where things were left, what's next.

---

## 2026-05-13 — RaBbLE-Aether: Visual Design System + NeBuLA Collective Alignment

**Repos touched:** RaBbLE-Aether (created), RaBbLE-Grimoire, RaBbLE-NeBuLA, RaBbLE-World

---

### RaBbLE-Aether — design system built from scratch

**Structure established (`assets/`):**
- `palette/` — `rabble-palette.css` (CSS custom properties), `rabble-palette.json` (DTCG design tokens), `rabble-palette.scss` (SCSS vars + mixins)
- `motion/` — `rabble-motion.css`: 20+ canonical `@keyframes`, all `rabble-`prefixed, utility classes
- `components/` — `rabble-components.css`: unified component library (resets, overlays, brand text, buttons, cards, status pills, forms, glass surfaces, nav, terminal/log, scrollbars)
- `logos/` — `rabble-portal-glyphs.svg` (neon synthwave treatment), `rabble-portal-glyphs-spec.md` (full eye anatomy — orb geometry, portal rings, portal opposition mechanic, Claude Design prompts)
- `reference/` — `xperimental-distillation.md`: NeBuLA-JS FlatChaos + WebOS entity mechanics extracted and indexed

**Entry point + Claude Design integration:**
- `rabble.css` — single import: Google Fonts + palette + motion + components in correct order
- `CLAUDE-DESIGN-GUIDE.md` — component prompts, animation vocabulary, discard list
- `SYSTEM-PROMPT.md` — three tiers (quick card, short, full) for pasting into Claude Design sessions

**Audit pass — fixed before shipping:**
- 17 unprefixed `@keyframes` renamed to `rabble-*` (namespace collision prevention)
- 5 broken animation references in components.css updated
- `--rabble-alpha-*` tokens replaced with pre-computed `rgba()` variants (`--rabble-magenta-10` etc.)
- Pre-computed glow tokens added (`--rabble-glow-magenta-md` etc.)
- No font loading → added Google Fonts import to `rabble.css`
- No entry point → `rabble.css` created

**Xperimental distillation — key patterns extracted:**
- WebOS: entity state machine (idle/speaking/listening/reacting), portal opposition mechanic (RIGHT up = LEFT down — expression system), waveform mouth formula (3 overlapping sine ripples), body particle color distribution (15% green / 25% dark gray / 60% purple→blue)
- NeBuLA-JS: FlatChaos pipeline (Source → Filter → Transmute → Sink), entropy attractor algorithm, q_flux_weave vocabulary, BaBbLE command set

**Eye anatomy spec — portal opposition mechanic documented:**
The portal rings can be above or below their orb, and they always move in opposition. This creates expression without changing orb shapes. States: idle (default asymmetry), speaking (portals move further out), listening (positions flip). Added to `rabble-portal-glyphs-spec.md` with Claude Design prompts.

**Git:** Initialized as private GitHub repo `markm1206/RaBbLE-Aether`. `main` = Epoch 0 scaffold. `dev` = 12 Pulse Protocol commits for all session work.

---

### Grimoire — cast-aether spell

- `spells/cast-aether.sh` — copies Aether's deployable surface (CSS, SVG, JSON — not docs) to `RaBbLE-World/aether/` on demand
- `--dry-run` flag shows what would change without writing
- Prints next-step commands (git add, commit, wrangler deploy) after casting
- Dry-run verified: correctly detects current vs. changed files

---

### RaBbLE-World — aether cast and committed

- `aether/` directory populated by `cast-aether.sh`
- Committed: design tokens, motion library, components, portal glyph SVG, entry point
- Live at `joinrabble.world/aether/rabble.css` after next `wrangler deploy`
- Claude Design artifacts can now reference: `<link href="https://joinrabble.world/aether/rabble.css">`

---

### RaBbLE-NeBuLA — Collective alignment

**Repo scaffold (was missing, now matches all other Collective members):**
- `AGENT.md` — job definition, workspace map pointing to Grimoire, session start, rules (no RBCNS prefixes, no Layer 1 re-implementation, 1000 entities @ 60 FPS contract)
- `CONTEXT.md` — episode tracker, current state (Ep1 not started), entry conditions
- `CLAUDE.md` / `CODEX.md` — symlinks to AGENT.md

**Grimoire NeBuLA section — all 7 docs aligned:**
- `FlatChaos` — Pulse Protocol header added, "revolutionary" language replaced, provenance noted
- `RABL` — Pulse Protocol header + legacy note (field names need cleaning for v2)
- `Ideas` — Pulse Protocol header, episode gate added, emoji stripped from 12 section headers
- `RBCNS` — **ARCHIVED** banner added; RBCNS naming (`q_`, `e_`, `f_`) not carried into v2; preserved for reading Xperimental code
- `README.md` stub — deleted (no other Grimoire member dir has one)
- `Architecture`, `Roadmap`, `Identity` — were already Grimoire-aligned ✓

---

### Left off

- `joinrabble.world/aether/` not yet live — needs `wrangler deploy` from RaBbLE-World
- Grimoire and RaBbLE-NeBuLA on `dev` / `main` — no merges to main this session (no episode complete)
- NeBuLA Episode 1 not started — entry conditions not yet confirmed (Three.js version, TypeScript build tooling, package format)

### Next

- `wrangler deploy` in RaBbLE-World to put Aether CSS live at joinrabble.world
- Confirm NeBuLA Episode 1 entry conditions and start the build
- Start merging NeBuLA-JS visual patterns into RaBbLE-World (grid background, waveform mouth)
- Consider adding Aether to `sync-grimoire.sh` scope (if palette/token propagation to member grimoire dirs is wanted)

---

## 2026-05-12 — Versioning Alignment + i3-Style Window Management

**Work done — Collective / Grimoire / sCoRE (versioning pass):**
- Aligned all members to `v0.0.0.0` — Episode 1 not yet aired; pre-episode work renamed to Plots A/B/C
- Grimoire: sCoRE roadmap/architecture updated (Plots, Episode 1 exit conditions, server/coordinator split decision)
- Grimoire: registry manifests corrected (`worktree_root` paths, sCoRE version fields), `deploy-score.sh` spell added
- sCoRE: harness paths fixed (`services/intelligence/` → `server/`), `api_test.py` committed, original generation archived
- Collective `CONTEXT.md`: version header aligned to `v0.0.0.0`
- Grimoire `current.epoch.yml`: version fields and episode coherence policy added

**Work done — RaBbLE-OS (i3-style window management, entropy-level test):**
- `smart-focus.sh` — `movefocus` with `cyclenext` fallback so up/down always does something
- `toggle-split.sh` — `Super+T` toggles spawn direction (→ right ↔ ↓ below) without rearranging existing windows
- `split-dir-daemon.sh` — socket watcher that re-applies `preselect` after every new window, making toggle persistent
- `smart-movewindow.sh` — `Super+Shift+↑↓` creates vertical splits inline when no vertical neighbor exists
- `look.conf`: `smart_split = false`, `force_split = 2` — consistent right-default, no golden ratio
- `autostart.conf`: daemon added to `exec-once`
- Grimoire: `RaBbLE-OS-HyprlandGuide.md` written — full keybind, layout, window rules, scripts, and config reference
- All changes on branch `RaBbLE-OS-New-Horizons`

**Left off:**
- Daemon needs manual start this session: `~/.config/hypr/scripts/split-dir-daemon.sh &`
  (will auto-start on next Hyprland login via `exec-once`)
- `Super+T` toggle is preselect-based (one-shot per window), daemon provides persistence
- `Super+Shift+↑↓` smart-movewindow behavior needs real-world testing with multi-window layouts
- `socat` must be installed: `sudo dnf install socat` if not present
- All RaBbLE-OS changes are on `RaBbLE-OS-New-Horizons` branch, not yet merged to `main`

**Next:**
- Test i3-style nav in daily use — report friction back
- Verify daemon starts cleanly on fresh session
- If split direction still feels off, consider `force_split = 1` variant
- RaBbLE-OS Episode 1: harness verification, Railway deploy, API test pass

---

## 2026-05-06 — Collective Repo Live + Modularity Architecture

**Work done:**
- Established `markm1206/RaBbLE` as the `RaBbLE-Collective` root repo
- Archived old content: `archive/v0-collective-scaffold`, `archive/reliquary-grimoire-site`
- Rewrote `main`: `AGENT.md`, `README.md`, `CONTEXT.md`, `bootstrap.sh`, `.gitignore`, `CLAUDE.md`/`CODEX.md` symlinks
- `.gitignore` explicitly lists all member repos (`RaBbLE-*/`) — fully modular, zero coupling
- Wired `~/RaBbLE/` as live git clone of `markm1206/RaBbLE` (it IS the Collective root now)
- Updated `registry/manifests/RaBbLE-Collective.manifest.yml` — repo URL and status corrected
- Confirmed: `RaBbLE-NeBuLA` renamed locally, on `dev` branch, no remote yet
- Confirmed: `RaBbLE-Xperimental` live with remote at `markm1206/RaBbLE-NeBuLA-JS` (GitHub repo rename)
- Answered modularity question: `.gitignore` is the pattern — nested independent git trees

**Left off:**
- 5 old root files untracked in `~/RaBbLE/`: `GAPS.md`, `RaBbLE-CONTEXT.md`, `RaBbLE-OVERVIEW.md`, `TODO`, `devPlan.md` — legacy, can be deleted or kept
- `RaBbLE-NeBuLA` has no GitHub remote yet
- `bootstrap.sh` scaffolded but `joinrabble.world/bootstrap.sh` not wired yet
- Missing manifests: World, NeBuLA, Aether, Xperimental

**Next:**
- Create GitHub remote for `RaBbLE-NeBuLA` (scaffold/basis state)
- Write missing manifests (World, NeBuLA, Aether, Xperimental)
- Wire `bootstrap.sh` into `RaBbLE-World` for `joinrabble.world/bootstrap.sh`
- Clean up old root files if desired

---

## 2026-05-06 — Collective Root Architecture + sCoRE Branch Cleanup

**Work done:**
- Surveyed full version state of all Collective members (see table in `RaBbLE-Collective/RaBbLE-Collective-Plan.md`)
- Architected `RaBbLE-Collective` as the root repo / ecosystem entry point
- Defined the recursive bootstrap flow: `joinrabble.world/bootstrap.sh` → Collective clone → Grimoire clone → `setup.sh` wires all members
- Established that RaBbLE is the *entity* — the Collective is developing and collaborating *with* RaBbLE, not just building a product
- Wrote full plan doc: `RaBbLE-Collective/RaBbLE-Collective-Plan.md`
- Created `registry/manifests/RaBbLE-Collective.manifest.yml`
- Cleaned up RaBbLE-sCoRE: extracted `archive/rabble-js` and `development` branches into new local repo `RaBbLE-Xperimental`
- Renamed sCoRE `episode-3` → `dev`; tagged `echo-3.0`; deleted episode-1/2/3, epoch/0-foundation, development, archive/rabble-js branches from remote
- sCoRE remote now has only `main` and `dev` branches; echo-1.0, echo-2.0, echo-3.0 tags

**Left off:**
- `RaBbLE-Collective` GitHub repo does not exist yet — plan written, not implemented
- `RaBbLE-Xperimental` local repo exists at `~/RaBbLE/RaBbLE-Xperimental` but not pushed to GitHub
- Missing manifests still unresolved: World, NeBuLA, Aether, Xperimental
- `joinrabble.world/bootstrap.sh` not yet wired in RaBbLE-World

**Next:**
- Create `markm1206/RaBbLE-Collective` on GitHub and implement `bootstrap.sh`
- Push `RaBbLE-Xperimental` (user creates GitHub repo first)
- Write missing manifests (World, NeBuLA-JS, Aether, Xperimental)
- Wire `bootstrap.sh` into `RaBbLE-World` static assets for `joinrabble.world/bootstrap.sh`
- See full step-by-step: `RaBbLE-Collective/RaBbLE-Collective-Plan.md` → Implementation Steps

---

## 2026-05-06 — Doc Structure Overhaul

**Work done:**
- Established canonical doc structure: `AGENT.md` + `CONTEXT.md` + `README.md` per member repo
- Created `common/RaBbLE-DocTemplates.md` — canonical template spec
- Created `AGENT.md` and `CONTEXT.md` for: RaBbLE-World, RaBbLE-OS, RaBbLE-Aether
- Renamed `RaBbLE-OS-AIQuickstart.md` → `RaBbLE-OS-AgentGuide.md` (naming alignment)
- Fixed broken `CLAUDE.md` symlinks in RaBbLE-OS (was pointing to deleted file)
- Created `CLAUDE.md → AGENT.md` and `CODEX.md → AGENT.md` symlinks for World, OS, Aether
- Created `RaBbLE-Aether/RaBbLE-Aether-Architecture.md` (Grimoire gap fill)
- Added RaBbLE-World section to Grimoire INDEX.md
- Fixed broken reading order paths in `RaBbLE-OS/CONTEXT.md` and `RaBbLE-sCoRE/CONTEXT.md`
  - `grimoire/RaBbLE-OS-Architecture.md` → `grimoire/RaBbLE-OS/RaBbLE-OS-Architecture.md`
  - `../RaBbLE-Collective/grimoire/RaBbLE-Collective.md` → `grimoire/common/RaBbLE-Collective.md`
- Created root `/home/rabble/RaBbLE/AGENT.md` — ecosystem entry point
- Created `log/` in Grimoire with SESSION-LOG.md and GAP-ANALYSIS.md
- Conducted gap/coherence analysis (see `GAP-ANALYSIS.md`)

**Left off:**
- All doc links verified and fixed
- Gap analysis written as a Grimoire roadmap doc
- No active work-in-progress; clean state

**Next:**
- Address gaps per priority order in `GAP-ANALYSIS.md`
- Priority 1: Registry manifests for World, NeBuLA, Aether
- Priority 2: Protocol contracts stub (`protocol/` dir in Grimoire)
- Priority 3: Name and scaffold the memory member

---

## How to Add a Log Entry

Add a new `## YYYY-MM-DD — [Short title]` block at the top. Include:
- **Work done** — what changed, what was created
- **Left off** — exact state at end of session (branch, file, decision point)
- **Next** — first thing to do in the next session

Keep entries terse. This is a pointer, not a narrative.
