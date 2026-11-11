# Collective Coherency Audit (S318, 2026-11-06)

```
transcribe ~ grimoire >> collective audit: findings, decisions owed, cleanup order // %PROPOSED%
```

**Status:** audit done, cleanup not started. Nothing below has been changed except the pushes listed.
**Evidence:** `audit-plans-roadmap.md`, `audit-web-brand.md`, `audit-ansible.md` in this folder. Every finding has its citation there.
**Limits:** no playbook was run (Ansible outcomes are reasoned from code and live state); no browser rendering or PNG pixel checks; plan triage came from a scout and should be spot-checked before bulk moves.

## Pushed in S318 (`new-horizons`, fast-forward)

Collective 4, sCoRE 56, Pocket 23 (private), OS 2. gitleaks on each outgoing range: clean, except 4 hits in sCoRE `tests/test_orchestra_narrate.py`, which are synthetic fixtures. The sCoRE proxy deploy workflow did not fire (no watched path changed).

## Not pushed

- **Grimoire, 79 commits.** Public repo. The range holds Pocket clean-room material, and S300 recorded "do not push until Mark decides rewrite vs move to the private Pocket repo". See D1.
- **BaBbLE, 59 commits.** No remote (B-23). See D2.
- **Uncommitted work** in OS (14), sCoRE (11), Grimoire (45): `mine.sh` marks it as other sessions'. Left alone.

## Decisions (Mark's rulings, S318)

| # | Decision | Status |
|---|---|---|
| D1 | Grimoire public push | **DONE.** Mark: the clean room is history and stays public. P-1 hold closed; 82 commits pushed (`73a9ca6`, merged with two origin-only eye-state commits, no rewrite) |
| D2 | BaBbLE backup | **DEFERRED.** Mark backs the whole Collective up to his own hard drive later (B-23). BaBbLE stays remote-less until then |
| D3 | Episode model | **RULED: move away from Episodes.** The replacement is not ruled yet. Proposal: keep Epochs and the lore names (Genesis, Exodus), plan by per-member milestones, and treat EP1 as one dated web release. Implementation is the next job (see HANDOFF-S318) |
| D4 | Web truth | **DONE.** Dev is the source of truth. June prod build archived at `chrysalis.joinrabble.world/world-2026-06/` (Chrysalis `30de4b0`), then World PR #2 merged `new-horizons` into `main` (`21b38cc`), first prod deploy from main. B-19 resolved |
| D5 | Vector master (brand Q2) | **OPEN, needs proper investigation** (Mark). Aether neon SVG vs mono OS/Grimoire SVG are different looks, not copies |
| D6 | Palette: `#03000b` and `#3d3860` | **RULED S320 (Mark): drop Void, keep Dimmer.** Applied S320: `#03000b` swapped to Deep Void in Aether tokens (`--rabble-void` kept as alias), World theme/manifest, NeBuLA eye + rig spec, Xperimental index; Dimmer added to Palette.md as decorative-only. Chrysalis/BaBbLE archives left frozen. Was: `D6-colours.html` in this folder shows them. Void `#03000b` vs Deep Void `#0a0010`: contrast 1.01:1, practically invisible; World uses Void as its page background. Dimmer `#3d3860` as text on the background: 1.9:1, unreadable; fine only for decoration. Recommendation: drop Void (use Deep Void), keep Dimmer but name it decorative-only |

## Cleanup order

1. ~~D1 and D2 first~~: D1 done, D2 deferred (BaBbLE's 59 commits still local only).
2. ~~Prod install path~~: fixed by D4.
3. **Ansible:** C1 (RPM Fusion never enabled, generic NVIDIA aborts every boot), H3 (root under become), H4 (`layerctl remove` runs install tasks), H5 (llama-server libs), then a real fresh-install VM run.
4. **Plans and handoffs:** archive 3 SUPERSEDED plans, 18 SUPERSEDED and 3 DONE handoffs, 1 DONE plan; delete 15 `HANDOFF-parked-*` junk files (400 bytes of `x`, untracked); rebuild the three indexes.
5. **Roadmap:** apply D3, then fix G9/B-17, the S276 web-only ruling, and the Ep2 number collisions in one pass. Target one forward-looking roadmap; move history out.
6. **Logging:** `SESSION-LOG.md` keeps LATEST plus the current month; earlier months go to `log/archive/sessions/YYYY-MM.md`. Update `session-number.sh`, which reads the log for its floor, so archived numbers still count. Also fix duplicates S250, S251, S258, S314.
7. **Brand:** `RaBbLE-Brand-Mark-Spec.md` per the consolidation proposal, after D5 and D6. Drop its stale lawyer step (also in B-21 and Accord v2).
8. **BaBbLE:** commit the `captures/` move, route the 25 loose intake files, clear `tmp/stt-venv` (692 MB).
