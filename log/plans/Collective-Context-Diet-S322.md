# Collective Context Diet and Cohesion Pass (S322, 2026-11-10)

```
harmonize ~ grimoire >> the door costs less, the entity has one page, the loop has a first slice // %S322%
```

**Asked by Mark:** audit and fix the whole Collective; fix drift; make it cohesive, easier to maintain and cheaper in tokens; help the unified entity spec; make RaBbLE more useful as an ambient companion and creature.
**Builds on:** `Collective-Coherency-Audit-S318/` (not repeated here). **Limits:** no member code was run or changed apart from one comment path in sCoRE; Ansible and brand findings from S318 stand untouched; the entity spec itself was not edited (another session may hold it).

## 1. Decisions for Mark

| # | Decision | Recommendation |
|---|---|---|
| M1 | **D3, what replaces Episodes** (section 4) | **RULED and applied S322:** Epochs and Echoes stay; Episodes retired; members carry a `milestone`; Genesis recorded as crossed 2026-11-09 |
| M2 | The 15 `HANDOFF-parked-*` placeholders | **Done S322 (Mark: archive):** moved to `log/archive/handoffs-parked/`; doctor at 0 warnings |
| M3 | Entity spec: adopt the three-file split (section 3) | Yes, after the easing pass; `Unified-Entity-Canon.md` is the seed |
| M4 | Entity: rulings 4 vs 22 and 6 vs 27a (Canon section 9) | **RULED S322:** four legal calm rests (portal flips and eye rotations); curious is a descriptor, calm is idle without emotion |
| M5 | Prune the agent memory index (section 5.1) | **Done S322:** 40 older memories moved to `archive/` (not deleted), hooks shortened; index 21.4 KB to 13 KB |
| M6 | First ambient slice (section 6) | Build A1 to A3 as one vertical slice before any new sensor |
| M8 | Depth over surface (section 8): the stance table, the OS repair order, closing the Pocket clean room | Adopt; it sets what is frozen while accounts lands |
| M9 | Accounts (`Accounts-Formalization-Scope.md`): store, sign-in methods, invite or open | Rule A1 to A3 there to start AC1 |
| M7 | `setup.sh` clones into `~/RaBbLE`; every doc and this machine use `~/RaBbLE-Collective` | **Done S322:** default is `~/RaBbLE-Collective` |

## 2. Done this session

| Change | Before | After |
|---|---|---|
| `log/SESSION-LOG.md` rotated to `log/archive/sessions/YYYY-MM.md` by new `spells/rotate-session-log.sh` (361 entries before and after, none edited) | 824 KB, about 200k tokens | 53 KB |
| `spells/session-start.sh` output: `agent-register.sh status` now counts dead claims instead of printing them; `status --all` and `prune` added | 166 KB, about 40k tokens per session start | 12.6 KB |
| `spells/session-number.sh` floor also reads the archive | would have reissued archived numbers | safe |
| `spells/grimoire-doctor.sh` C4 compared the door with the first "Session N" in the file (reported S215 at S321) | false pass | reads the LATEST box |
| Doctor C2 accepts two-hop reachability: INDEX links a folder hub (`CONTEXT.md`, `README.md`, `PROVENANCE.md`), the hub names the doc | 93 warnings | 15 (the parked placeholders, M2) |
| `INDEX.md`: 29 finished handoff and plan lines removed (listed in their hubs); 8 orphan docs indexed | 51.2 KB | 45.8 KB |
| Plans: 3 superseded plans moved to `log/plans/done/` with a status banner; `log/plans/CONTEXT.md` rebuilt (5 unlisted plans added, Unified-Entity row corrected from "draft 7") | index 6 weeks stale | current |
| Collective `CONTEXT.md` rewritten (was dated 2026-05-22: Fedora 43, dead EP1 doc paths, "gists ~1,700 tokens") | 5.6 KB | 3.7 KB |
| Collective `README.md`: branch table (listed `RaBbLE-OS-New-Horizons`, `ep2/liminal-world`), member table (3 members missing), CDN section (said Pages, `v0.0.0.1`) | wrong | matches the manifests |
| Collective `REFERENCES.md`: memory member named (was "Mnemos, Codex"), Crew, rig, surface added | stale | current |
| `gist/RaBbLE-Entity-gist.md` added; Palette gist synced to the S320 ruling; overview token counts measured | no gist described the body | entity is in the first read |
| `log/plans/Unified-Entity/Unified-Entity-Canon.md` | 65 KB spec, body stale against 22 rulings | one page of rules in force, plus the contradictions |

Token figures are bytes / 4. The gist path is about 5,000 tokens, not the 2,000 to 3,600 the docs claimed.

## 3. The entity: one definition

Findings (detail in `Unified-Entity/Unified-Entity-Canon.md`):

1. **The spec only grows.** 36 rulings in two days; nine are fully superseded and the body (sections 3.3, 4, 6, 8, 10.1) describes an entity that no longer exists. Any reader, human or agent, has to replay the log to learn what is true.
2. **The entity is defined in at least six places** with no stated order of authority: `RaBbLE-Agent/RaBbLE-Identity.md` (who, voice, `%STATE%` lifecycle), the puppet spec (body), `RaBbLE-NeBuLA/specs/visual-spec.md` and `specs/rig/entity-rig.json` (stale: magenta-left), `RaBbLE-Pocket-Entity-Format.md` (file format, excludes the brand), `RaBbLE-BaBbLE/intake/RaBbLE-Entity-Rig-Spec.md` (stale placeholder colour), and each renderer's own tables.
3. **Four state vocabularies:** Identity's lifecycle, the spec's emotion / state / mood layers, Pocket's `NL_STATE_*`, the TUI's Mood names. The spec maps the last three; the lifecycle is unmapped.

Proposal, in order:

| Step | Action |
|---|---|
| E1 | Mark closes M4 (two contradictions) |
| E2 | Split the spec: append-only `Unified-Entity-Rulings.md`; the canon rewritten in place (seed: the Canon page); numbers move to `registry/entity/rabble.entity.json` |
| E3 | Order of authority, written at the top of each: **Identity** (who) > **Entity spec** (body) > **registry** (numbers) > renderers. Stale docs in finding 2 get a one-line banner pointing up the chain |
| E4 | Add a **condition** layer mapping the `%STATE%` lifecycle to the body, so reported state and shown face cannot disagree |
| E5 | The generator spell with `--check` (spec 10.2) wired into each renderer's tests: drift becomes a failing test, not an audit finding |
| E6 | After E2: `distill-gists.sh` gains an `entity` slug, and sCoRE's chat persona loads the Entity gist so RaBbLE can describe its own body |

## 4. D3 proposal: what replaces Episodes

Mark ruled "move away from Episodes" (S318). Proposal:

- **Keep** Epoch (era, named in hindsight) and Echo (a stable, tagged, reproducible release). Keep the lore names (Genesis, Exodus) as arc names, not gates.
- **Drop** the Collective-wide Episode lockstep, the air checklist as a gate, and the simultaneous `episode-N` tag.
- **Add** one `milestone:` and `milestone_status:` per member manifest (the epoch file's `focus:` block already holds this text). `status.sh` prints it in place of "Episode 1 pending / Episode 1 blockers".
- **Record Genesis as done:** the 2026-11-09 prod deploy from `main` (World PR #2) is the first public release. Version stays `v0.0.0.x`; the fourth slot becomes a per-member release counter.
- **Coherence without lockstep:** the contracts are what must agree (sCoRE protocol version, Aether and NeBuLA bundle versions pinned in World's config, the entity registry). A doctor check on those replaces "all members air together".

Sweep once ruled (each is a mechanical edit): `RaBbLE-Versioning.md` and its gist; `registry/epochs/current.epoch.yml` (141 lines, mostly Episode gating, read on the "before architectural changes" path: cut to about 50); `log/EP1-AIR-CHECKLIST.md` and `gist/RaBbLE-Episode1-gist.md` (archive; remove from `RaBbLE-sCoRE/server/grimoire.py`, which feeds it to the live chat persona today); the Roadmap pair and gist; `status.sh`; `end-session.sh` "Phase:" line; the "Pre-Episode-1, you're..." sentence in six member `AGENT.md` files (Aether, NeBuLA, Grimoire, OS, World, sCoRE); the `episode:` header line in member `CONTEXT.md` files; Grimoire `AGENT.md` branch rule.

## 5. Remaining context cost

| # | Finding | Fix |
|---|---|---|
| 5.1 | Agent memory index (`~/.claude/.../MEMORY.md`): 21 KB, about 5,300 tokens, loaded into every Claude session before any work. More than all gists. About 35 of 122 entries describe finished, retired or EP1-gated work | Prune after confirming each is in the Grimoire (M5). Target under 10 KB |
| 5.2 | Member `CONTEXT.md` files are build histories, not orientation: sCoRE 10 KB of "Plot A / Plot B" from May; NeBuLA 7.5 KB; World 6.6 KB; last reconciled May to August | One template, at most 2.5 KB: what it is, how to run and test, where its Grimoire docs are, current focus as a pointer. History moves to `log/RaBbLE-Development-History.md`. Do it per member, in that member's session |
| 5.3 | `RaBbLE-Agent-Protocols.md` 48.8 KB (about 12k tokens), the largest rules doc | Split: rules an agent must hold (target 6 KB) and the rationale and incident history behind them |
| 5.4 | `log/BLOCKERS.md` 11 KB; printed whole by `session-start.sh`. Entries carry dated commentary inline | `blockers.sh ls --short` (id, title, owner, tags) for session start; commentary stays in the JSONL |
| 5.5 | `SPELLS.md` 30 KB duplicates each script's header | Generate it from the headers, or cut it to a one-line-per-spell table |
| 5.6 | 19 dead claim files in the runtime registry | `bash spells/agent-register.sh prune` (not run: Mark's call) |
| 5.7 | Run `rotate-session-log.sh` monthly | Add to `end-session.sh` when the log passes about 150 KB |

## 6. Toward an ambient companion: the first closed loop

The S57 gap analysis still holds: expression is far ahead of perception. The entity has a face on four surfaces, a voice, a persona and a hosted engine. It observes nothing, remembers nothing between sessions, and never speaks first. The Epoch 1 exit marker is one loop: do something, observed, stored, recalled, expressed, offline.

The Collective already emits clean, structured events. No new sensor is needed for the first slice.

| # | Slice | What it is | Uses what exists |
|---|---|---|---|
| A1 | **Observe** | A local tailer writes one append-only `observations.jsonl` (`ts, source, kind, subject, payload`) | `log/sessions/*.jsonl` (start, commit, end, peers), Pulse Protocol commits (already machine-parseable), `blockers.jsonl`, `token-ledger.tsv`, `mine.sh` dirty-tree data, Hyprland active-window IPC |
| A2 | **Recall** | A digest spell writes `today.md`, at most 300 tokens: what was worked on, what is unfinished (dirty repos, unpushed commits, open handoffs), what is blocked. Template first, no LLM needed | `status.sh`, `blockers.sh`, the session files |
| A3 | **Express** | The `rabble` face greets with the digest at launch; the entity's body reflects one real condition (for example unpushed work = ponder) | the Rust TUI face, the condition layer (E4) |
| A4 | **Speak first, once** | One proactive trigger with a threshold and a cooldown: "work older than 24 h, uncommitted, in a repo with no live session", or "N commits with no remote" (B-23 is exactly this) | Identity's Proactive mode, already specified |
| A5 | **Remember** | Three tiers as Identity describes: session (the JSONL), 30-day (observations, decayed), long (patterns promoted to `log/lessons/` by `promote-insight.sh`, which exists). SQLite FTS before any vector store | EnGrAm architecture doc; build the smallest version |
| A6 | **Consent** | `rabble observed` shows everything captured; one pause switch; nothing leaves the machine | closes the roadmap's open "observation ethics" question before A1 ships |
| A7 | **Context on request** | `rabble context <topic>` (later an MCP tool) returns the smallest doc set: gist, then canon, then full doc. Agents pull instead of `cat` | `server/grimoire.py` already loads gists; `RaBbLE-Collective/RaBbLE-Grimoire-MCP.md` is the concept |
| A8 | **Creature, not dashboard** | Idle life tied to real signals: time of day, how long Mark has been in one window, a build finishing. The swap log (spec 4.4) records what preceded each move so RaBbLE can later propose what a move means | spec section 12, authorship gate |

Order: A6, A1, A2, A3 as one vertical slice (about one session each), then A4. A5 and A7 only when the slice shows what recall needs.

## 8. Depth over surface (added after Mark's S322 notes)

Mark: "I generally have more surface than depth at the moment." The count agrees: 11 repos, 4 entity renderers, 6 public subdomains, 30 plans, 15 open blockers, and one user.

**Mark, S322: unsure on the stance table below; the rule he gave instead is the ship bar: only ship working MVPs that feel semi-ready and polished.** The table stays a proposal, not a ruling. What is ruled: nothing goes to users half-finished.

Proposed stance per surface until accounts and the first closed loop land:

| Stance | Members | Rule |
|---|---|---|
| **Deepen** | sCoRE, World (the door only), the unified entity | accounts (`Accounts-Formalization-Scope.md`), the first loop (section 6), one rig |
| **Repair, then hold** | OS | fix what the S318 audit found, prove one fresh install, then no new layers |
| **Finish the move, then hold** | Pocket | land the core/apps reorg so the tree builds from one layout; no new clean-room waves, no public split work |
| **Maintain** | Grimoire, Aether, NeBuLA | changes only in service of the three threads |
| **Freeze** | ScRiBbLE, Xperimental, Chrysalis, BaBbLE, TaskViSoR, SiGiL, EnGrAm as a separate member | no new work; BaBbLE gets its backup (B-23) and nothing else |

### 8.1 OS Ansible: a repair order

185 YAML files, about 9,500 lines, 11 role groups. The S318 audit (`Collective-Coherency-Audit-S318/audit-ansible.md`) found 1 critical, 10 high, 15 medium. The structural cause is in its M1: `manifest.yml` is described as the source of truth but 51 packages are installed by tasks outside it, so no one place says what a machine gets.

| Step | Action |
|---|---|
| O1 | A check that runs without a VM: `ansible-playbook --syntax-check`, `ansible-lint`, and a script that fails when a task installs a package the manifest does not list. Run it in the pre-commit hook |
| O2 | Fix the install-breaking findings in the audit's order: C1 (RPM Fusion never enabled), H3 (root's HOME under `become`), H1 (`uv` used before it is installed), H5 (llama.cpp), H4 (`layerctl remove` reinstalls) |
| O3 | H2 is half done: S322 pointed `setup.sh` and the kickstart at `~/RaBbLE-Collective`, which is what the roles hardcode. Still derive the path from `rabble_repo_root` so it cannot drift again |
| O4 | One fresh install of the `core` edition in a VM (never on Mark's machine), start to desktop, recorded. That is the OS milestone |
| O5 | Only then: the medium findings, and editions (`OS-Install-Editions-Plan.md`) |

Until O4 passes, no new layer or recipe.

### 8.2 Pocket: reduce the moving parts

Three efforts overlap: the clean room (W0-W11), the licence split (Apache SDK, Accord middleware and app; B-27 D1-D5 open), and the core/apps reorg (R0-R10, partly landed in S314 and S316). Each changes where files live, so each invalidates the others' paths and specs.

Recommendation:

1. **Close the clean room at what is built.** Mark ruled it history and public (S318 D1) and ruled out lawyer review. W8-W11 specs stay as design notes; no further two-team waves.
2. **One layout, licence by directory**, as the reorg plan already says. Finish the reorg in one pass and make the build green from that tree.
3. **Defer the public split** (B-24 name, B-27 D1-D5, open SDK repo) until a second person is running a Pocket. Mark's dad's device is the trigger.
4. **Fix B-22** (dropped voice note) before any of it: it is the one defect a user would meet.

### 8.3 What this buys

Three threads instead of eleven. Each has a stated outcome and an exit: a returning user, one unprompted observation, one entity drawn the same everywhere.

## 9. Verify

```bash
bash spells/grimoire-doctor.sh            # 0 errors, 15 warnings (parked placeholders)
bash spells/tests/anti-clobber.test.sh    # 20 passed
bash spells/rotate-session-log.sh --dry-run
bash spells/session-start.sh --no-heartbeat | wc -c    # about 12.6 KB
```
