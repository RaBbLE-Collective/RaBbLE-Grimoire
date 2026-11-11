# HANDOFF S323: the Genesis release (every member to `0.1.0` on `main`)

```
spark ~ collective/release >> genesis prepared member by member; main gets its origin // %S323_GENESIS%
```

> **Status:** phase 1 (local preparation) handed to an agent on 2026-11-11. Phase 2 (anything that leaves this machine) waits for Mark.
> **Rules:** `RaBbLE-Versioning.md` sections 2 to 5. **Rulings:** `log/DECISIONS.md`, S323 table.
> **Collective root:** `~/RaBbLE-Collective`; member repos are cloned inside it.

## 1. Goal

Every releasing member lands on `main` at version `0.1.0`, tagged `v0.1.0` and `genesis` on the same commit. The set is written to `registry/releases/genesis.yml`. After that Mark works toward Echo 1, the first stable Echo.

Ruled by Mark (S323): semver per member, start at `0.1.0`, Genesis is the origin and not an Echo, `new-horizons` stays the working branch, `main` is stable.

## 2. Members

| Member | Releases at Genesis | Known facts (2026-11-11) |
|---|---|---|
| RaBbLE-Collective (root) | yes | no manifest of its own; version goes in `registry/manifests/RaBbLE-Collective.manifest.yml` only |
| RaBbLE-Grimoire | yes | `main` 872 behind, 0 ahead; tag `v0.0.0.0.1` is history |
| RaBbLE-sCoRE | yes | `main` 2 commits ahead of `new-horizons`; old tags `echo-1.0` to `echo-3.0` are history; Python server plus a Rust TUI |
| RaBbLE-World | yes | `main` deploys production. Pins CDN bundles in `world/js/RaBbLE-config.js` (`v0.0.0.1-rc.2` Aether, `v0.0.0.1-rc.1` NeBuLA) |
| RaBbLE-Aether | yes | `package.json` says `0.0.0.0`; `main` 1 ahead |
| RaBbLE-NeBuLA | yes | `package.json` says `0.0.0.0`; `main` 1 ahead; build with `npm run build:iife` |
| RaBbLE-OS | yes | version is `rabble_os_version` in `ansible/inventory/group_vars/all.yml`; `rabble_epoch_name` still says "Episode 1 Preview" (Mark picks the new name; do not change it) |
| RaBbLE-Pocket | yes, if it builds | `main` 1 ahead; core/apps reorg in flight; ESP-IDF `PROJECT_VER` |
| RaBbLE-ScRiBbLE | yes | `main` 1 ahead |
| Xperimental, BaBbLE, Chrysalis | no | sandbox, intake (no remote, B-23), archive |

## 3. Phase 1: local preparation (the agent does this)

For each releasing member, in this order: Aether, NeBuLA, sCoRE, ScRiBbLE, Pocket, OS, World, Grimoire, Collective root.

1. `git fetch origin` (read only). Confirm the working tree is clean and on `new-horizons`. If it is dirty, skip the member and report.
2. Record how far `origin/main` is ahead of and behind `new-horizons`, and list the commits only `main` has.
3. `git switch -c release/0.1.0 new-horizons`.
4. If `origin/main` has commits `new-horizons` lacks, `git merge origin/main` into the release branch. If it conflicts beyond the trivial, `git merge --abort`, and report the conflict; do not guess.
5. Set the version to `0.1.0` in the member's one native source (`package.json`, `Cargo.toml`, `pyproject.toml`, ESP-IDF `PROJECT_VER`, OS `rabble_os_version`). Find it; do not add a second source. Update lock files only by the tool that owns them.
6. Run the member's existing build and tests (read its `AGENT.md` and `CONTEXT.md` for the commands). Record the exact command and result. Do not fix failures that predate this work; report them.
7. Commit on the release branch: `harmonize ~ <organ> >> genesis: version 0.1.0 // %GENESIS%`.
8. `git switch new-horizons`. Leave the release branch in place.

Also in phase 1:

- **Grimoire release branch:** set `version: "0.1.0"` in each releasing member's `registry/manifests/*.manifest.yml`, and write `registry/releases/genesis.yml` in the format of `RaBbLE-Versioning.md` section 5 with `commit: PENDING` for every member (the real shas exist only after the merges to `main`).
- **World release branch:** change the two CDN pins to `v0.1.0` paths in one separate commit, clearly labelled. Those bundles do not exist on the CDN yet (see phase 2, step 2).
- **Report:** append a `## Result` section to this file (on Grimoire `new-horizons`, uncommitted): one table row per member with ahead/behind, version file changed, build and test command and outcome, release branch head sha, and anything that blocks the release.

### Hard stops for phase 1

- No `git push`, no pull requests, no tags, no deploys, no `wrangler`, no CDN upload.
- Never check out, merge into, or commit on `main`.
- No history rewriting, no `git add -A`, no force of any kind. Stage by explicit path.
- Do not touch `log/SESSION-LOG.md`, `AGENT.md` state blocks, or the four leftover `log/sessions/*.jsonl` files.
- Colours, docs and code outside the version change are out of scope.

## 4. Phase 2: release (needs Mark's go, step by step)

1. Push `new-horizons` and `release/0.1.0` for Aether and NeBuLA; pull request into `main`; merge; tag `v0.1.0` and `genesis`; merge `main` back into `new-horizons`.
2. Build and deploy the Aether and NeBuLA `v0.1.0` bundles to their CDN subdomains. Confirm both URLs return 200.
3. Only then World: its `main` deploys production, and its release branch pins the `v0.1.0` bundle paths. Merging it before step 2 breaks `joinrabble.world`.
4. sCoRE, ScRiBbLE, Pocket, OS, Grimoire, Collective root in any order, same steps as 1.
5. Fill the real commit shas into `registry/releases/genesis.yml`, Mark verifies the live site and signs `verified_by`.
6. Delete the release branches; update `current.epoch.yml` (Genesis released) and the member statuses.

## 5. After Genesis: toward Echo 1

Echo 1 needs the two open pieces of exit evidence (`setup.sh` on a fresh VM; an OS fresh install after the Ansible audit fixes) and each build reporting its version and commit at runtime (`RaBbLE-Versioning.md` section 2, rule 2). Neither is part of Genesis.
