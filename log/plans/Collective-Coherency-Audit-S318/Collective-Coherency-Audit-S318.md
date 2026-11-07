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

## Decisions owed (Mark)

| # | Decision | Recommendation |
|---|---|---|
| D1 | Grimoire public push: move clean-room material to the private Pocket repo, or publish it | Publish, no rewrite. Mark, 2026-11-06: it is history and stays in the Grimoire (matches Reorg Plan ruling 12). P-1's reason, holding until a lawyer read it, lapsed with the 2026-11-05 no-lawyer ruling. Awaiting Mark's go on the push itself |
| D2 | BaBbLE backup | Private remote for text and prototypes; `intake/captures/` and `tmp/` onto the B-23 disk backup, not git |
| D3 | Episode model | Keep Epochs and lore names; drop Episode as a planning unit in favour of per-member milestones; EP1 becomes one dated web release |
| D4 | Web truth | Dev becomes the source for prod; one deploy closes W1 and W2 |
| D5 | Vector master (brand Q2) | Aether SVG is the master for the neon look; mono OS/Grimoire version becomes a named variant |
| D6 | Palette: `#03000b` and `#3d3860` | Add to the Palette or swap (`#0a0010` is the S234 decision of record) |

## Cleanup order

1. **D1 and D2 first.** 138 commits have no backup off this machine.
2. **Prod install path:** `setup.sh`, `RaBbLE-OS.ks` and `/roadmap` return 404, so the one-liner in `README.md:12` and `AGENT.md:42` fails.
3. **Ansible:** C1 (RPM Fusion never enabled, generic NVIDIA aborts every boot), H3 (root under become), H4 (`layerctl remove` runs install tasks), H5 (llama-server libs), then a real fresh-install VM run.
4. **Plans and handoffs:** archive 3 SUPERSEDED plans, 18 SUPERSEDED and 3 DONE handoffs, 1 DONE plan; delete 15 `HANDOFF-parked-*` junk files (400 bytes of `x`, untracked); rebuild the three indexes.
5. **Roadmap:** apply D3, then fix G9/B-17, the S276 web-only ruling, and the Ep2 number collisions in one pass. Target one forward-looking roadmap; move history out.
6. **Logging:** `SESSION-LOG.md` keeps LATEST plus the current month; earlier months go to `log/archive/sessions/YYYY-MM.md`. Update `session-number.sh`, which reads the log for its floor, so archived numbers still count. Also fix duplicates S250, S251, S258, S314.
7. **Brand:** `RaBbLE-Brand-Mark-Spec.md` per the consolidation proposal, after D5 and D6. Drop its stale lawyer step (also in B-21 and Accord v2).
8. **BaBbLE:** commit the `captures/` move, route the 25 loose intake files, clear `tmp/stt-venv` (692 MB).
