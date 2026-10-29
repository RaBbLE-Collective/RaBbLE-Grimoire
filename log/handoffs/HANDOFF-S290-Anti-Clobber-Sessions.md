# HANDOFF S290: anti-clobber session mechanism (parked, installed, tested in sandbox)

**State:** built and installed on `new-horizons`; `bash spells/tests/anti-clobber.test.sh` = 13 pass. Not yet exercised by a second live session or a real codex/gemini run. Committed locally, not pushed.

## Why (root causes, with evidence)
1. **Identity guessed from the newest transcript for `$(pwd)`**, in four copies (`end-session.sh`, `agent-register.sh`, `session-start.sh`, `post-commit`). Wrong with 2+ live sessions and wrong when the shell cwd is not the agent's cwd (the 94d4f7e8 "magnet", at least 9 ledger clobbers). Env vars die between tool calls.
2. **Whole-file rewrites of shared files** (ledger awk+mv, LATEST in-place) with no lock and no "is this newer than me" check (S243 LATEST overwrite).
3. **No atomic S-number claim** (S284/S285 taken twice).
4. **Dirty-tree sweep:** a session commits files another live session is still editing. Happened in S290: `edbad98` swept S291's sCoRE work-in-progress, because the live-session check was a `pgrep ... | head` that truncated.
5. **The pre-commit backstop never warned anyone:** its `echo >&2` sat inside a `{ } 2>/dev/null` group. Also 66 tracked registry JSONs churned on every commit.

## What exists now
| Piece | File |
|---|---|
| Exact identity for any harness (claude, rabble, codex, gemini, opencode, aider, antigravity); `confidence` = exact / derived / process / declared | `spells/lib/session-id.sh` |
| Claude/rabble: `~/.claude/sessions/<pid>.json` (sessionId, procStart guards PID reuse). `CLAUDE_CODE_ENTRYPOINT=sdk-py` = rabble. Model from transcript, provider from model id | same |
| One append-only event file per session, `log/sessions/<date>-<harness>-<key8>.jsonl`: start, label, commit, end; each line names harness/provider/model at that moment | `spells/lib/session-log.sh` |
| Atomic S-number claim (`mkdir`), label stored per session | `spells/session-number.sh` (`next`, `claim <topic>`, `show`) |
| Ledger write under `flock`, refuses to drop more than its own row, LATEST never overwrites a newer session, rows now carry `harness provider model` (cols 4-6) | `spells/end-session.sh` |
| post-commit: exact attribution, `commit` event, provisional ledger row; plain-terminal commits record nothing | `spells/hooks/post-commit` |
| pre-commit: warns when staged files predate this session while others are live; warnings now reach the terminal (fd 3) | `spells/hooks/pre-commit` |
| "Which dirty files are mine?" from the session's own transcript (Edit/Write targets + shell text); three classes | `spells/mine.sh` (`--paths` for `git add`) |
| Claims moved out of git to `~/.cache/rabble/agents` (`log/agents/` untracked + ignored); liveness = agent process alive, heartbeat only for declared ids | `agent-register.sh`, `session-start.sh` |
| Tests (sandbox, concurrency, provenance, harness env) | `spells/tests/anti-clobber.test.sh` |

New ritual: `bash spells/session-start.sh "<Repo:path>"... --task "…"` prints who you are (harness / provider / model), your S-number state, and other live sessions; `bash spells/session-number.sh claim <topic>`; before staging, `bash spells/mine.sh`.

## Not done / next (in order)
1. **Run it live with a second session** and with real **codex** and **gemini** processes. The adapters for those are unit-tested (classify, model flags, provider) and env-tested, not process-tested. Codex native id comes from the rollout file the process holds open; the fallback is flagged `derived`.
2. **rabble should emit a `model` event** when `/model` switches (sCoRE `ui/`), so mid-session switches are logged, not just sampled at the next event. Also have rabble call `session-start.sh` for the Crew lead.
3. `mine.sh` shell-text match is by path substring: `.gitignore`-style names can false-positive as mine (never false-negative).
4. Update `RaBbLE-Agent-Protocols` and OS `AGENT.md` ritual text; delete `~/.claude/.../project_registry_spell_gotchas.md` items 3 and "root cause" once a second live session confirms.
5. Optional: `post-commit` could also stamp commits with a trailer (harness/model); not done, Mark's call (Pulse Protocol format).
6. History rebuild (next big task) can read `log/sessions/*.jsonl` from now on; older sessions need transcript mining (`~/.claude/projects/*/*.jsonl`, `~/.codex/sessions`).

## Disclosure
S290's catch-up commits (`edbad98` etc.) swept S291's live sCoRE edits under a wrong message; S291's log entry records it. No work lost. Cause: truncated `pgrep` ("nothing else is running"). `mine.sh` + the pre-commit warning exist to prevent a repeat.

## Also parked (not part of this)
EP1 push (PR new-horizons to main per repo; World `_redirects` repoint; Render env check), B-23 backup bundles, B-21 deep research, sCoRE independent-of-lockstep (DECISIONS.md), licence v2 rewrite.
