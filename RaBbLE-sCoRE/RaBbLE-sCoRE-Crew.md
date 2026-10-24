# RaBbLE-sCoRE-Crew.md — The Crew and the `rabble` Launcher

```
spark ~ sCoRE/crew >> local sCoRE wraps Claude Code; RaBbLE leads, the organs answer // %CREW_LIVE%
```

> **Document type:** Grimoire architecture spec · `RaBbLE-sCoRE/`
> **Status:** v1 built S273 (2026-10-24), Opus-reviewed (12 findings fixed) · Epoch 0 · Episode 1 staging · first interactive team run pending Mark
> **Purpose:** How a local session of Claude Code becomes RaBbLE, with RaBbLE's organs (the Crew) available as agent-team teammates.
> **Canon:** personas `../RaBbLE/Crew/` · colours `../RaBbLE-Agent/RaBbLE-Palette-Candidates.md` (S273 section) · code `RaBbLE-sCoRE/crew/rabble.py`
> **Related:** `RaBbLE-sCoRE-Local-Architecture.md` (the `rabble` CLI vision), `RaBbLE-sCoRE-Local-Tickets.md` L-09, `../RaBbLE-Agent/RaBbLE-Identity.md`

---

## 1. Who is who

- **The Observer / Architect: Mark.** Above and outside the Crew. Directs, decides, signs off.
- **The Crew: RaBbLE.** The lead carries the name and conducts; eight organs are specialised appetites of the same entity, not separate beings. Each carries a strand of RaBbLE: the shared organ preamble and the Crew Thread colour.

| Organ | Pair | Job | Tier | Access | Colours (base · variant) |
|---|---|---|---|---|---|
| **RaBbLE** | lead | conductor | Observer's model | full | magenta `#ff2d78` · cyan `#00f5ff` (canonical) |
| **GoBbLE** | knowing | scout: ingests, returns coordinates | haiku | read-only | glimmer `#f6f6ff` → oil slick of canonical neons as it ingests |
| **QuiBbLE** | critic | argues with the plan before the build | opus | read-only | orange `#ff9044` · `#aa5306` |
| **CoBbLE** | making | builder | sonnet | full | yellow `#f1fa8c` · `#aab157` |
| **CrumBbLE** | making | crash tester: runs it where it lives, never fixes | sonnet | run | green `#50fa7b` · `#08ac46` |
| **NiBbLE** | critic | bites the diff after the build | opus | read-only | red `#e05c6f` · `#8b2237` |
| **the Archivist** | knowing | keeps the record; unnamed until it earns a name | sonnet | scoped: Grimoire | Deep Void · Border (canonical) |
| **BaBbLE** | entropy | keeper of RaBbLE-BaBbLE intake | sonnet | scoped: BaBbLE | pink `#ff79c6` · `#a93f7f` |
| **DaBbLE** | entropy | manager of RaBbLE-Xperimental | sonnet | scoped: Xperimental | violet `#bf5fff` · `#7521a6` |

**Crew Thread** `#31c7d5`: muted Electric Cyan woven through every organ and the whole-Crew RaBbLE mark. All non-canonical hexes are **candidates** until promoted.

**Formations** (ways the lead deploys organs, not personas):
- **SqUaBbLE**: three rival investigators (as `gobble`, haiku-pinned) each disproving the others' theory; QuiBbLE and NiBbLE referee; five teammates total.
- **Build loop**: GoBbLE → QuiBbLE → CoBbLE → CrumBbLE → NiBbLE → the Archivist.

## 2. Shape

```
RaBbLE-Grimoire/RaBbLE/Crew/*.md      canonical persona specs (flat frontmatter + body, LLM-agnostic)
          │  read at every launch
          ▼
RaBbLE-sCoRE/crew/rabble.py           Claude Code adapter
   ├─ lead prompt  = rabble.md body + generated roster + SESSION-LOG ## LATEST
   │                 → ~/.cache/rabble/crew-lead-*.md (one 0600 file per launch, pruned after 7 days)
   ├─ --agents     = one agent type per organ: _organ.md preamble + body,
   │                 model from tier, tools allowlist + disallowedTools from access
   └─ exec claude --append-system-prompt-file … --agents … --teammate-mode in-process [args]
                    with CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 in its env (inherited by children)
          ▲
~/.local/bin/rabble → RaBbLE-sCoRE/scripts/rabble   (RaBbLE-OS ai-harnesses, claude-code task)
```

Why this shape (decisions, S273):

| # | Decision | Why |
|---|---|---|
| C1 | **Opt-in launcher**, not Collective-wide settings | Plain `claude` stays a neutral dev agent; teams don't leak into ordinary subagent use (with teams on, any named subagent becomes a teammate) |
| C2 | Bare `rabble` = this wrapper; positional words reserved for L-09 | One command, one entity (Local-Architecture). `rabble -- "prompt"` passes a first prompt. L-09 extends `crew/rabble.py` (subcommands) rather than installing a second binary under the same name |
| C3 | Lead persona **appended** (`--append-system-prompt-file`), never `--agent rabble` | `--agent` replaces Claude Code's whole system prompt, coding instructions included |
| C4 | Organs via session-only `--agents` JSON, nothing written to `~/.claude/agents` | Specs stay canonical in Grimoire and agent-agnostic; no Claude config to drift; a Codex/Gemini adapter can read the same files later |
| C5 | Models pinned by tier, never inherited | Fleet-pinning rule (an inherited Fable fleet burned two session limits in S193) |
| C6 | `teammateMode in-process` (changed from `auto` after review) | Split-pane teammates replace Claude Code's default prompt with the organ body (CoBbLE would lose coding and git-safety guidance) and ignore `disallowedTools`. `RABBLE_TEAMMATE_MODE=tmux` opts back into panes, with a warning |
| C7 | Specs live in `RaBbLE/Crew/`, not `RaBbLE-Agent/` | Organs are the entity's inner life; `RaBbLE-Agent/` stays flat by convention |

## 3. Use

```bash
rabble                       # RaBbLE lead; ask for organs or a formation in plain words
rabble --model opus          # any flag passes to claude
rabble -- "call a SqUaBbLE on the beam reconnect bug"
rabble --crew-list           # roster banner
rabble --crew-print          # exact lead prompt + agents JSON (debugging)
```

Talk to it like the lead: "have GoBbLE map the beam code, then CoBbLE fix X and CrumBbLE run the tests". It names teammates after the organs (`CoBbLE`, agent type `cobble`).

Env: `RABBLE_GRIMOIRE` (default: Grimoire beside sCoRE), `RABBLE_TEAMMATE_MODE` (default `in-process`; `tmux`/`auto` for panes, see §4), `NO_COLOR`. `-p`/`--print` is refused (no teammates headless); positional words are refused unless they are the value of a known flag.

## 4. Limits and gotchas

- **Start from the Collective root (or any member except sCoRE).** sCoRE's own `.claude/settings.json` denies Bash and the Agent tool for every session started in it; the launcher warns.
- **Interactive only.** Claude Code does not spawn teammates under `-p`, so the sCoRE server's headless `claude_code` provider (and the Pocket beam node) can't run the Crew. A Crew behind sCoRE's HTTP API would need its own orchestration.
- **`scoped` access is instruction-level.** Per-agent hooks don't apply to teammates, so BaBbLE/DaBbLE/the Archivist are told their scope but not sandboxed to it. `read-only` and `run` are enforced by a `tools` allowlist (holds in every display mode) plus `disallowedTools` (in-process only); both keep Bash, so "read-only" means no file-edit tools, not no side effects.
- **Pane mode trades guardrails for visibility.** In tmux panes each organ's body replaces Claude Code's default system prompt. Use panes for read-only organs if at all; keep CoBbLE in-process.
- **Agent teams are experimental** (Claude Code 2.1.310): `/resume` doesn't restore in-process teammates; one team per session; teammates can't spawn teammates; permission prompts from teammates appear in the lead.
- **Token cost scales per organ.** The lead prompt tells RaBbLE to do small jobs itself and cap teams at 3 to 5.
- **The persona does not override project rules.** CLAUDE.md/AGENT.md still load for the lead and every teammate; the organ preamble restates that they bind.
- **Not the same as `agents/score.md`.** That is sCoRE's delegate-only dispatch identity (no Bash, task files). The Crew lead codes.

## 5. Next

- **First interactive run** (Mark): `rabble` from the Collective root (link installed S273); ask for a small build loop. Use the agent panel (arrows + Enter) to watch organs.
- **Promote colours** from the candidates file into `RaBbLE-Palette.md` + the Ansible block when Mark signs off.
- Banner: GoBbLE's glimmer-to-slick morph is only on the swatch page; terminal banner shows static bases.
- Possible later: other harness adapters (Codex, Gemini) reading the same specs; Crew colours in Waybar/NeBuLA; a Crew behind sCoRE's API (needs its own orchestration, see §4).
