# HANDOFF-S298: Pocket provenance record and Open SDK / RaBbLE app split

> Cold start for a fresh agent. Written 2026-11-02 (S298). Mark: "park the session for handoff". Nothing here is committed.

## Where things stand

- **Provenance is audited and written down.** Read `RaBbLE-Pocket/RaBbLE-Pocket-Provenance-Record.md` first. Evidence: `RaBbLE-Pocket/cleanroom/audit-2026-11-02/` (`OVERLAP-REPORT.md`, `TRANSCRIPTS-port.md`, `TRANSCRIPTS-firewall.md`, `scripts/`). Headline: overlap with Meta's Muse Gadget SDK `b139b45` was 59.4% at the port commit (`42ae6d9`) and is 8.0% at HEAD (`0d3d438`), 3.5% after discounting ESP-IDF idioms. No clean-room implementer transcript shows a firewall breach (W2, W6 minor). Gap: `rabble_ui.c`, `rabble_beam_score.c` and the board vtable (`rabble_board.h`) are derived by influence and were never clean-roomed.
- **gitleaks** installed (S298, via `layerctl apply base --packages`; manifest entry plus `roles/core/tasks/packages.yml`). Pocket history scan: 126 commits, no leaks, no tags. Other repos not scanned yet.
- **Plan drafted:** `log/plans/Pocket-Open-SDK-App-Separation-Plan.md` (v0.2). Goal: all Meta ancestry or influence on the Apache-2.0 SDK side with attribution; `app/RaBbLE` Meta-free and Sovereign Accord. **The Opus (QuiBbLE) review has not happened**: it hit the session limit (resets 11:50am ET). Re-run it before any P2 work.
- **Mark's rulings so far:** `rabble_` identifiers and names may stay in the SDK (only brand values and assets leave); BLE is spelled **bLE**; Pocket README gained a "Provenance and attribution" section (uncommitted, in `RaBbLE-Pocket/README.md`; wording must be tightened, it currently says no derived code remains).

## Pending decisions (Mark), with recommendations in the plan

D1 SDK licence Apache from day one; D2 one repo with two licensed trees vs split repos; D3 public SDK name and whether "RaBbLE Pocket" stays; D4 keep full history on publish; D5 sCoRE protocol app-only. Plus lawyer review (NOTICE, PROVENANCE, header-compaction history, trademark).

## Next steps

1. Re-run QuiBbLE (opus) on the plan; fold findings; ask Mark for D1-D5.
2. P0/P1: branch `sdk-split`, signed tag `pre-split`, per-file manifest (`RaBbLE-Pocket-Split-Manifest.md`). GoBbLE fan-out by directory is fine (read-only).
3. Then P2-P4 per the plan. The builder never verifies; any clean-room implementer must be a fresh agent that has not read the SDK or `apache/` history.
4. Tighten the README provenance note once D1 and the file moves are settled.

## Uncommitted state (do not clobber)

Grimoire: new `RaBbLE-Pocket/RaBbLE-Pocket-Provenance-Record.md`, `RaBbLE-Pocket/cleanroom/audit-2026-11-02/`, `log/plans/Open-Layer-and-Positioning-Notes-2026-11-02.md`, `log/plans/Pocket-Open-SDK-App-Separation-Plan.md`, this handoff; index lines in `INDEX.md`, `log/plans/CONTEXT.md`, `log/handoffs/CONTEXT.md`. Pocket: `README.md`. OS: `ansible/packages/manifest.yml`, `ansible/roles/core/tasks/packages.yml`. Other sessions have unrelated dirty files (session logs, token ledger): stage explicit paths only.

## Off-repo assets (back up)

`~/RaBbLE-Cleanroom/` (3.9 GB): clean-room workspaces, 31 archived transcripts, `provenance-audit-2026-11-02/` with the pinned SDK clone (`sdk/`, `b139b45`). Not version-controlled. Claude transcripts of the port: `~/.claude/projects/-home-rabble-RaBbLE-Collective/{35c63c6d…,a5cc84d6…}.jsonl`.

## Gotchas

- `layerctl` layer is `base`, not `core`; the manifest does not drive the `core` role (it has a hand-written package list).
- Overlap numbers depend on the SDK commit: pin `b139b45`.
- Missing transcripts: spec authors for W2, W5, W6 (rev 1 and 2) and the parent-session firewall turns.
