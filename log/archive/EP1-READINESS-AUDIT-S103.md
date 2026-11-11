# EP1 Readiness Audit & Post-Mortem — Session 103

> Date: 2026-06-15 · Scope: full Collective audit ahead of per-member Release Candidates.
> Companion to `FABLE-GAP-ANALYSIS-S57.md`. This is the canonical record of the EP1
> readiness pass; workstreams spawned from it are tracked in SESSION-LOG.

---

## A. State snapshot

| Repo | Branch | EP1 role | Risk |
|---|---|---|---|
| Grimoire | `new-horizons` | source of truth | doc drift |
| Aether | `new-horizons` | **global platform theme** | artifact duplication |
| World | `world` ⚠️ | EP1 public site | fragmented, off-pattern branch |
| OS | `new-horizons` | substrate | theme jank, reboot QA |
| NeBuLA | `new-horizons` | renderer | ok |
| sCoRE | `new-horizons` | LLM endpoint | Render deploy = Mark's |
| BaBbLE | `new-horizons` | intake/captures | messy root |
| Chrysalis | `main` | archive | n/a |
| Xperimental | `master` ⚠️ | sandbox | inconsistent branch name |

**Headline:** foundation is real and docs are unusually disciplined — but EP1 has three
silent blockers not on the prior "Next" list: **branch inconsistency** (can't tag
`v0.0.0.1` simultaneously across `world`/`master`/`main`/`new-horizons`),
**theme-artifact duplication** (Aether-as-source documented but not enforced), and
**World fragmentation** (20 CSS + 21 JS files, no shared shell).

---

## B. Grimoire — drift found (all small, all real)

1. Root `AGENT.md` calls the root `~/RaBbLE-Collective/`; it is actually `~/RaBbLE-Collective/`, with
   members living *inside* it, not as siblings.
2. **Render/Railway staleness** — `gist/RaBbLE-Episode1-gist.md`,
   `RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md`, `RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md` all
   still say "Railway-deployed." The pivot to **Render** is locked.
3. `RaBbLE-OS/config/gtk-3.0/gtk.css:7` cites palette at `RaBbLE-Grimoire/common/RaBbLE-Palette.md`
   — dead path; correct is `RaBbLE-Agent/RaBbLE-Palette.md`.
4. Token-count inconsistency: Grimoire `AGENT.md` says gist is "~3,660 tokens" in one line
   and "~1,700" in another; `gist/RaBbLE-Gist-Overview.md` says "~1,700."
5. Gist overlap: `RaBbLE-Collective-gist.md` (ecosystem map) and
   `RaBbLE-Collective-Overview-gist.md` (EP1 overview) have distinct sources but overlap in
   onboarding. Evaluate whether both belong in the `cat gist/*.md` path (do not delete a
   canonical gist without confirming).

**Verdict:** onboarding path is genuinely good (gist-first, ~2k tokens, clear session
start/end). The above is ~an hour of cleanup, not a redesign.

---

## C. OS theming — jank is architectural, not cosmetic

**Root cause #1 — duplication.** The 104 KB Kvantum SVG is committed byte-identical (md5
`3b659b8c`) in 3 places: Aether source (`themes/kvantum/`), OS repo
(`config/kvantum/RaBbLE-Aether/`), and `~/.config`. Ansible deploys from Aether, so the
OS-repo copy is a pure orphan. Same trap waiting for VSCodium (lives only in OS) and GTK.

**Root cause #2 — hand-authored base.** The Kvantum theme is a hand-tweaked "KvArcDark
foundation" — not a synthwave base, hence the off feel. Fix: start from a polished
synthwave Kvantum theme and re-skin with the Aether palette rather than hand-editing SVG.
Candidate bases to evaluate: Sweet (closest outrun vibe), Catppuccin-Kvantum (best-structured
SVG for recolor), Graphite/Otto. Recommendation pending research checkpoint.

**Resolution (Mark's directives):**
- **Aether = global platform theme; holds themed apps/engines as subdirectories.** Aether
  grows `themes/{gtk3,gtk4,kvantum,qt,firefox,vscodium,waybar,...}/`, each a self-contained
  themed-app artifact, authored only in Aether.
- **VSCodium theme moves Aether-ward:** `RaBbLE-OS/config/vscodium/extensions/RaBbLE-Aether-theme/`
  → `RaBbLE-Aether/themes/vscodium/`; OS gets one Ansible task to install it, mirroring the
  existing Kvantum/GTK tasks in `qt-gtk-theme.yml`.
- **OS keeps only selectors:** `settings.ini`, `qt5ct.conf`, `qt6ct.conf`,
  `kvantum.kvconfig` (the `theme=` pointer), env vars. No artifacts. Delete the orphaned
  `OS/config/kvantum/RaBbLE-Aether/`.

---

## D. World — unifying liminal + grimoire browser + landing for EP1

**Current reality:** three standalone pages, no shared shell. Landing (`index.html`) is the
most evolved — a full WM/window-manager shell (`landing-shell/stage/panels/login` +
Alpine.js + `RaBbLE-bg.js`) that already embeds the grimoire (`RaBbLE-Grimoire-Data.js` +
`RaBbLE-Grimoire.js`). Liminal and Grimoire-Graph are separate.

**Synthesis (visitor journey):**
1. **Liminal** as the atmospheric cold-open / hero.
2. Dissolve into the **landing WM shell** — RaBbLE desktop-in-the-browser, demonstrates the platform.
3. **Grimoire browser** as a window within the shell — introduces the Entity (lore/identity).
4. **Summon ceremony** (`summon.html` exists) as the call to action — join, get a personal entity.

This is consolidation, not new construction. Real work: (a) shared CSS/JS foundation so 20
stylesheets collapse toward Aether tokens + a small per-surface set; (b) one coherent
navigation/transition model. Largest single EP1 effort.

**Branch:** give World the `main`/`new-horizons` treatment in line with the Collective —
`main` = readme/license stub, `new-horizons` = full 102-commit history rebased on top
(history retained per Mark's instruction). Backup-tag first.

---

## E. BaBbLE + screenshot spells

- `captures/` is well-taxonomized (Aether, World/Pages, Entity-UI, NeBuLA, OS-IDE…). The mess
  is two things:
  1. `visual-screenshot.sh` writes `captures/visual-TIMESTAMP.png` to the *root* → loose
     files. Fix: write to `captures/_inbox/` staging dir; file from there.
  2. BaBbLE root has overlapping buckets (`assets/`, `visual/`, `sketches/`, `prototypes/`,
     `historical/`, `design-system/`, `character/`, `behavior/`) — consolidate against `_ROUTING.md`.
- 124 capture images are git-tracked. Decide intentionally: curated captures tracked,
  `_inbox/` gitignored so raw dumps don't bloat history.

---

## F. Cross-cutting gaps blocking a clean EP1 (post-mortem)

1. **Branch inconsistency** — World `world`, Xperimental `master`, Chrysalis `main`, rest
   `new-horizons`. Simultaneous `v0.0.0.1` tagging is impossible until harmonized. #1 unlisted blocker.
2. **Aether-as-source not enforced** — documented, violated (Kvantum dup). Mark's "Aether holds
   themed apps" directive is the fix.
3. **sCoRE Render pivot undocumented in canon** — 3 docs still say Railway.
4. **No RC mechanism exercised** — `publish-rc.sh` exists but untested before per-member RC push.
5. External blockers (already tracked): OS reboot QA, CF Pages, Render deploy (Mark's).

---

## G. Workstreams (this session)

- **Tier 1 — EP1 unblockers:** Grimoire drift fixes + re-distill; World `main`/`new-horizons`
  branch treatment.
- **Tier 2 — Aether platform theme:** Aether as global theme home; Sweet/Catppuccin synthwave
  Kvantum base; move VSCodium in; OS → selectors-only; Ansible install approach.
- **Tier 3 — World unification:** liminal → shell → grimoire → summon as one experience.
- **Tier 4 — BaBbLE:** fix screenshot spell target (`_inbox/`), consolidate root, decide tracking.
