# HANDOFF-S352: unified entity + NeBuLA, and the encrypt-everything proposal

Date: 2026-11-18. Repos: RaBbLE-Grimoire (docs), RaBbLE-Pocket (read, sim), RaBbLE-NeBuLA (read). Branch `new-horizons`. Nothing committed this session.

## Read first
- `log/plans/Unified-Entity/Unified-Entity-NeBuLA-Unification-Plan.md` (this session's plan, slices U1 to U7)
- `log/plans/Unified-Entity/Unified-Entity-Canon.md` (sections 6, 9, 10)
- `log/plans/EP2-Accounts-Encryption-Spec.md` section 0a (S352 encryption proposal, slices E1 to E7)
- `RaBbLE-Pocket/RaBbLE-Pocket-ZNP-Badge-Research.md`

## State
- Docs written: the ZNP note, EP2 spec section 0a, the unification plan, this handoff, INDEX entries for the first (the other two still need INDEX lines).
- U1 half done. Repro: `cd RaBbLE-Pocket/sim && NO_ORBIT=1 ./build.sh s352_idle 0 6 0.5 0 0 0`; rig via Playwright on a copy of `Unified-Entity-Puppet-Spec.html` with `prop='pocket'` (the page has no UI for proportions). Compare at about 17 degrees with perspective, not 0.
- Playwright is available system-wide (`python3`, chromium installed); the rig page's variables are not global.

## Owed
1. Mark's rulings on the EP2 section 0a proposals (keys as X25519, sealed metadata, client-side search); then a `log/DECISIONS.md` S352 entry for both the encryption and unification rulings.
2. Finish U1; then U2.
3. INDEX.md lines for the unification plan and this handoff; commit (Pulse style, no AI trailer, gitleaks first).
4. Guest transcripts: seal or retire.
