# Collective Architecture Audit — Implementation Progress

**Tracks:** `Collective-Architecture-Audit-2026-07-04.md` + `sCoRE-Extensibility-Refactor-Plan.md`
**Opened:** 2026-07-05 (S196) · **Status:** Batch 1 (safe doc/drift fixes) in flight; all decisions + restructures deferred

This ledger records which audit findings have been actioned and which are parked. The audit doc proposes;
this doc says what got done. Update the status column as batches land.

**Guiding rule this pass:** only items that are (a) decision-free and (b) cannot move EP1 gates G7/G9 were
implemented. G7/G9 are verification gates (OS Dev-Preview FLOOR on a VM; `setup.sh` fresh-machine bootstrap) —
still ⏳. Per the audit's own guardrail, member-code restructures wait until they clear. Doc/registry
reconciliation and provably-dead-code removal do not touch what G7/G9 verify, so they proceeded.

Legend: ✅ done · 🔄 in flight · ⏸ deferred (needs Mark decision or waits on G7/G9) · — n/a

---

## Batch 1 — safe doc/drift fixes (2026-07-05)

Dispatched as model-pinned sonnet sub-agents, grouped by repo. `dist/` is gitignored in NeBuLA so no bundle
churn; the World re-vendor of the NeBuLA bundle is intentionally held (see deferred).

| Audit ref | Item | Status |
|---|---|---|
| §2.5 | NeBuLA `RaBbLE-NeBuLA-API.md` rewritten against the real `<rabble-entity>` element + `window.NeBuLA.effects` namespace; every `createPuppet()` reference purged | ✅ |
| §2.5 | `effects/effects-ns.js` — added missing `AnimationFilter` export so it appears on `window.NeBuLA.effects`; rebuilt IIFE bundle | ✅ |
| §2.5 | `src/index.js` — corrected stale "P5 stub" comments on doors/deepfield (fully implemented) | ✅ |
| §2.5 | `specs/render-gap-analysis.md` — condensed to a pointer stub (was self-marked superseded) | ✅ |
| SP-1 | NeBuLA `CONTEXT.md` — bonus fix: stale `createPuppet` reference in the reading-path list | ✅ |
| SP-1 / §2.3 | World `CONTEXT.md` — regenerated Structure/pages against real tree (5 live pages, liminal JS, vendored NeBuLA.js) | ✅ |
| SP-1 / §2.6 | OS `CONTEXT.md` — fixed nonexistent `RaBbLE/episode-I` branch → `new-horizons`; removed consolidated-away in-repo `grimoire/` reference | ✅ |
| SP-1 / §2.7 | Xperimental `CONTEXT.md` — "just scaffolded" → real state (on new-horizons since S189, Voice Phase 2/7, 32/32 tests) | ✅ |
| SP-1 / §2.4 | Aether `CONTEXT.md` — deploy status "R2 Pending" → live Workers deploy (with staleness caveat); Structure table regenerated against real `src/entry.css` import chain | ✅ |
| §2.1 / SP-7 | Grimoire registry reconciliation — member lists aligned (incl. TaskViSoR + Collective), 5 manifest branch notes, Xperimental status, epoch blocker-note + `episode_name`→Genesis, SPELLS.md +6 spells, RC1→liminal repointed, dead INDEX link removed, plans indexed, `plans/CONTEXT.md` reconciled | ✅ |

### New findings surfaced during implementation (not in the original audit)

- **An 11th member exists: `RaBbLE-TaskViSoR`** (Scaffold — Visual State Observer, Layer 1 ships as a World page, no own repo yet). The audit's "10 members" count was itself short one. Added across CONTEXT.md / AGENT.md / INDEX.md.
- **Aether's live CDN bundle is stale** — deployed `aether.min.css` is 30KB vs 50KB local; the current Workers workflow (`deploy.yml` + `wrangler.jsonc`) lives only on `new-horizons`, not `main`, so its push/tag trigger can't fire against current source. Live theme was likely pushed by a manual `wrangler deploy`. Mildly EP1-relevant (it's the theme that ships on air). → deferred with the Aether version/CDN item.
- **README CDN URL is worse than a 404** — `cdn.joinrabble.world` fails DNS entirely. → **Resolved by Mark (S196):** the unified `cdn.joinrabble.world` is **cancelled**; per-member subdomains `aether.joinrabble.world` + `nebula.joinrabble.world` are now permanent canon (not a Phase-2 roadmap target as the docs framed it). Canonical URL pattern per the prod loader (`RaBbLE-World/world/js/RaBbLE-config.js:22-23`): `https://aether.joinrabble.world/{ver}/aether.min.css` and `https://nebula.joinrabble.world/{ver}/nebula.iife.js`. Collective-wide sweep of ~60 stale `cdn.joinrabble.world` refs across ~15 docs done S196 (host/path fix only; version strings untouched — they roll into the deferred Aether version decision). Deep R2/unified-CDN architecture sections reframed as cancelled, not fully rewritten (follow-up).
- The audit's own claim that `OS-ProArt-Power-Stack-Plan.md` is "untracked in git" is **stale** — it's committed at `9454ecb` (S194). Indexed regardless.

**Not committed yet** — commits land per-repo (Pulse Protocol) on Mark's go-ahead; the ledger/agents-json changes in the Grimoire tree belong to the concurrent S195 session and are excluded from these commits.

---

## Deferred — needs Mark's decision (audit's "Open decisions")

These are the forks the audit explicitly left to you. None were touched.

- **sCoRE server refactor** — pick option A (domain packages) / B (ports & adapters) / C (seam-first flat) / staged C→A. See `sCoRE-Extensibility-Refactor-Plan.md` §7 (6 sub-decisions incl. multi-worker caveat, store-unification scope).
- **jane.py / actions.py (P1)** — delete both · keep `actions.py` seam + delete `jane.py` · park both in `integrations/`. 507 lines of orphaned pre-RaBbLE clinic code shipping to Render every deploy.
- **Grimoire — Captures** — register as a member (manifest + epoch row) or finish the S92 fold into BaBbLE (+ fix the OS keybind writing to the stale path).
- **Grimoire — Episode-1-Release-Map** — re-stamp as canonical after refresh, or demote (epoch YAML + BLOCKERS.md now hold live truth).
- **World — NeBuLA delivery** — commit to the vendored bundle (delete dead `RABBLE_NEBULA_URL`/`RABBLE_THREE_URL` flips) or return to CDN (restore a real loader). Both currently documented; one is real.
- **World — serve-the-repo** — is publicly serving AGENT.md/CONTEXT.md/gists on joinrabble.world acceptable, or gate `.assetsignore` to `world/` + `index.html`?
- **World — `.rc-*` retirement timing** — pre- or post-EP1 (touches 3 live pages).
- **Aether — versioning** — is `0.0.0.0` canon until EP1 airs (then README rc-tag + palette JSON walk back)?
- **Aether — invented tokens** — promote `--rabble-void`/`--rabble-dimmer` into Palette.md or purge.
- **NeBuLA — floor/graph unification** — one parameterized element vs two elements over one shared module.
- **NeBuLA — `dist/v0.0.0.1-rc.1/` snapshot** — confirm not CDN-published, then delete (currently a 3-week-old entity if live).
- **OS — manifest fate** — wire Ansible roles to consume it (real SSoT) or demote to "KS-generator input + decision record."
- **OS — Fedora 43 vs 44** — is the KS's F44 jump intentional; move docs + `rabble_fedora_version` now?
- **OS — install root** — converge KS on `~/RaBbLE-Collective`?
- **OS — dotctl waybar agent-config editing** — keep (documented) or extract an explicit `dotctl agents` verb.
- **Xperimental — Voice** — continue toward memberhood after EP1 or park at Phase 2 with the contract preserved in Grimoire.
- **BaBbLE — rfcs/** — create `RaBbLE-Grimoire/rfcs/` or repoint the `_ROUTING.md` table.
- **Chrysalis — Chrysalis-Web** — amend the charter to "archive + memorial site," or move it (Xperimental rablet / World subdomain) to keep the reliquary sealed.

---

## Deferred — restructures (wait on G7/G9, then above decisions)

Audit Part 3 tier 4. Risky, code-touching, gate-adjacent. Do not start before G7/G9 clear.

- sCoRE `server/` refactor (per chosen option) + P1–P4 preconditions (orphans, auth cycle at source, doc the surface, pytest smoke).
- World orphan sweep — reliquary 7 JS (2,526 lines, incl. the 883-line `RaBbLE-floor.js` copied-NeBuLA violation) + 3 CSS, per condense-not-delete.
- World — move the bespoke Canvas2D constellation renderer (`RaBbLE-liminal.js`) into NeBuLA as an effect.
- `.rc-*` retirement across Aether + World's 3 non-index live pages.
- NeBuLA floor/graph unification + palette-module merge + burn down the ~8 hardcoded-hex sites (SP-2/SP-4).
- OS — delete dead dotfiles plumbing (site.yml play, `*_tasks_only` vars, quickshell ghosts); codify the real dotctl/Ansible boundary; reconcile group_vars palette (may close the `#8860aa` KDE bug for free).
- **World re-vendor of NeBuLA bundle** — the `AnimationFilter` fix rebuilt NeBuLA's `dist/`, but `cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js` is held until post-G7/G9 (touches the frozen prod bundle). Additive-only change; low risk when greenlit.

---

## Deferred — regrowth guards (audit Part 3 tier 3)

Cheap, prevent the drift from regrowing. Sequence after the cleanups. Honor low-entropy — one guard at a time.

- `spells/palette-lint.sh` — grep member hex vs Palette.md, allow-list mask/FOUC cases (SP-2).
- `context-freshness` check in `status.sh` — warn on stale CONTEXT.md front-matter (SP-1).
- Per-member highest-leverage test (SP-6): sCoRE pytest route-table smoke · NeBuLA headless render-smoke · World/Aether CI lint-greps.
- Habit (not tooling): absorb/refactor commits that strand files must delete-or-reliquary the same session (SP-3).

---

## Also noted, small (BaBbLE §2.8 — not yet actioned)

- `_ROUTING.md` routes two signals to nonexistent `RaBbLE-Grimoire/rfcs/` (folded into the rfcs decision above).
- `intake/Video.mov` untriaged since 2026-06-22; `tmp/` holds ~20 unswept files. Housekeeping, no decision.
