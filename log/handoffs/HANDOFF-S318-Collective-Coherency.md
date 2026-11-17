# HANDOFF-S318: Collective coherency pass, audit done, cleanup next

> Written 2026-11-09 (S318). Cold start. Source of truth for findings and rulings:
> `log/plans/Collective-Coherency-Audit-S318/Collective-Coherency-Audit-S318.md` (decision table D1-D6, cleanup order).
> Evidence reports alongside it: `audit-plans-roadmap.md`, `audit-web-brand.md`, `audit-ansible.md`.

## Done
- **Audit:** three read-only reports (plans/roadmap/episodes, web/brand, Ansible). Each claim is cited.
- **Pushed, `new-horizons`, fast-forward, gitleaks clean:** Collective, sCoRE (56), Pocket (23, private), OS (2), Grimoire (82, merged with two origin-only eye-state commits, no rewrite). The sCoRE gitleaks hits are synthetic test fixtures.
- **D1:** Mark ruled the Pocket clean room is history and stays public. P-1 hold closed.
- **D4:** June prod build (World `e7e5b51`) archived at `chrysalis.joinrabble.world/world-2026-06/` (Chrysalis `30de4b0`, banner, landing node; `summon`/`account` were already broken on prod and are kept as they were). World `_redirects` 301s `/chrysalis/*` to the reliquary (`d282ea8`). **World PR #2 merged `new-horizons` into `main` (`21b38cc`): first prod deploy from main.** Verified: prod equals dev byte for byte; `/setup.sh`, `/RaBbLE-OS.ks`, `/roadmap` 302; `AGENT.md` no longer public; desktop and phone load with 0 errors; sCoRE `/health` 200. B-19 resolved, B-20 updated.
- **Rollback for prod:** Cloudflare worker `rabble-collective`, version `85a4a5c0-c73d-44dc-99e7-fc51070f3797` (2026-06-20). Credentials: `RaBbLE-Grimoire/.cloudflare/config` (gitignored).

## Next (in order)
1. **D3: retire Episodes.** Mark ruled "move away from episodes"; the replacement is not ruled. Bring Mark one short proposal first (Epochs + lore names kept; per-member milestones; EP1 = one dated web release, arguably the S318 prod deploy), get his ruling, then sweep: `RaBbLE-Versioning.md`, `registry/epochs/current.epoch.yml`, `log/EP1-AIR-CHECKLIST.md`, `log/episodes/`, `RaBbLE-Agent/RaBbLE-Roadmap.md` + `RaBbLE-Post-EP1-Roadmap.md` + gist, the member roadmaps, `status.sh` branch-alignment, `end-session.sh` "Phase:" line, Grimoire `AGENT.md` branch rule ("merge to main only when an episode is complete"), Collective `AGENT.md`. Footprint list: `audit-plans-roadmap.md` section 3.
2. **Roadmap:** one forward-looking roadmap after D3; fix G9/B-17 and the S276 web-only ruling; move history out.
3. **Ansible** (CoBbLE builds, CrumBbLE runs in a VM, never on Mark's machine): C1 RPM Fusion, H3 root under become, H4 `layerctl remove`, H5 llama-server libs, H1/H2, H7/H8. Then a real fresh-install VM run. Details and fixes: `audit-ansible.md`. The fastfetch work in `RaBbLE-OS` (untracked files) belongs to the S319 thread: commit it with its role or KS breaks (M15).
4. **Plans and handoffs archive:** handoffs DONE S320 (18 superseded + 3 complete moved to `done/` with a status banner, none deleted; `log/handoffs/CONTEXT.md` rebuilt, INDEX entries tagged). Still to do: the plans side (3 SUPERSEDED + 1 DONE to `log/plans/done/`, rebuild `log/plans/CONTEXT.md`) and indexing the 26 unindexed handoffs and 6 plans in `INDEX.md`. Delete the 15 `HANDOFF-parked-*` files (400 bytes of `x`) only after Mark says yes.
5. **Logging:** keep LATEST + current month in `SESSION-LOG.md` (815 KB now); earlier months to `log/archive/sessions/YYYY-MM.md`; `session-number.sh` must still read archived numbers for its floor.
6. **Brand:** D5 needs a proper investigation (Mark). D6 RULED S320: Void `#03000b` dropped (swapped to Deep Void across Aether, World, NeBuLA, Xperimental; uncommitted, not deployed), Dimmer kept as decorative-only in Palette.md. After D5, write `RaBbLE-Brand-Mark-Spec.md` per `log/plans/Brand-Asset-Consolidation-PROPOSAL.md`; drop its stale lawyer step.
7. **BaBbLE:** commit the `captures/` to `intake/captures/` move (all 1,045 tracked files are there, plus 205 new); route the 25 loose intake files; clear `tmp/stt-venv` (692 MB). D2 (backup) is deferred to Mark's hard drive.

## Watch
- B-20 leftovers: Render env (DEMO_MODE/DEMO_MODE_PUBLIC), a live guest chat reply on prod, `e56808a` deploy.
- World `main` now deploys prod on every push; `v*` tags also deploy. Branch rule: PR `new-horizons` to `main`, never a direct push. No release tag was cut (Episode tags are retiring).
- `_redirects` comment still says "until EP1 airs"; `/RaBbLE-OS.ks` and `/roadmap` point at `new-horizons` on purpose (OS and Grimoire `main` are stubs/behind).
- Uncommitted work in OS, sCoRE and Grimoire belongs to other sessions: run `bash spells/mine.sh` before staging.
