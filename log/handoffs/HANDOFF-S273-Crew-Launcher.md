# HANDOFF-S273 · The Crew: `rabble` wraps Claude Code as RaBbLE

> Written 2026-10-24 at the end of S273 for a cold start.
> Read first: this file, `RaBbLE-sCoRE/RaBbLE-sCoRE-Crew.md` (design, decisions C1–C7, limits), `RaBbLE/Crew/README.md` (roster, frontmatter fields).

## What exists

| Repo | State |
|---|---|
| RaBbLE-Grimoire `new-horizons` | `RaBbLE/Crew/` (README, `_organ.md` preamble, `rabble.md` lead, 8 organs); `RaBbLE-sCoRE/RaBbLE-sCoRE-Crew.md`; S273 section in `RaBbLE-Agent/RaBbLE-Palette-Candidates.md`; INDEX + handoffs CONTEXT lines |
| RaBbLE-sCoRE `new-horizons` | `crew/rabble.py` (Claude Code adapter), `scripts/rabble` (shim), `tests/test_crew_launcher.py` (17 tests; full suite 103 passed / 1 skipped) |
| RaBbLE-OS `new-horizons` | `ansible/roles/ai-harnesses/tasks/claude-code.yml`: links `~/.local/bin/rabble` when sCoRE is cloned, never over a real file. **Applied by Mark** (`layerctl apply claude-code`); link verified. `config/shell/zsh/aliases.zsh`: removed the dead `alias rabble='cd ~/RaBbLE-OS'` that shadowed the launcher, fixed `rabble-apply`/`rabble-dots` paths; deployed with `dotctl apply zsh` |
| Swatch page | https://claude.ai/artifact/Qo1EE3uM3n67AqgcQnjQLX (source in S273 scratchpad only; the hexes are in the candidates file) |

Verified: `rabble --crew-list` / `--crew-print`; reserved positional exits 2; a headless haiku run with the generated lead prompt + `--agents` named itself RaBbLE, Mark as Observer, and listed all 8 agent types. **Not verified:** an interactive session actually spawning teammates (headless `-p` never spawns them).

## Next, in order

1. **Mark:** from the Collective root, `rabble`, and ask for a small build loop on something cheap (e.g. "GoBbLE, map where the beam's reconnect logic lives; QuiBbLE, critique a fix plan"). Check: teammates appear in the agent panel named after organs, models match tiers (GoBbLE haiku, critics opus), read-only organs can't Edit. Default is in-process; tmux panes are opt-in (`RABBLE_TEAMMATE_MODE=tmux`) and drop the organs' default Claude Code prompt.
2. Tune persona bodies from that run (they're short on purpose). Edit `RaBbLE/Crew/*.md` only; the launcher reads them each launch.
3. **Mark:** colour sign-off → promote the S273 candidates into `RaBbLE-Palette.md` + the Ansible `rabble_palette` block (Crew Thread `#31c7d5`, orange `#ff9044`, the deep variants, glimmer). CoBbLE's deep `#aab157` reads olive; offer the light `#f5fbc2` again.
4. Later, not scoped: terminal banner with GoBbLE's morph; Codex/Gemini adapters reading the same specs; Crew colours in Waybar/NeBuLA.

## Gotchas

- **Never launch from inside `RaBbLE-sCoRE/`**: its `.claude/settings.json` denies Bash and Agent (sCoRE's delegate-only identity), so no Crew. The launcher warns.
- Opus review (S273) found 12 issues, all fixed: pane mode dropped tool limits and the default prompt (→ in-process default + `tools` allowlists), untyped SqUaBbLE investigators would inherit the lead's model, shared prompt file raced, `-p` and flag-then-word slipped the guards, Ansible could clobber a real file.
- With agent teams on, *any* named subagent becomes a teammate. That is why teams are enabled only in the `rabble` process env, never in settings.
- `--agent <name>` would replace Claude Code's system prompt; the lead persona must stay `--append-system-prompt-file`.
- `scoped` access (BaBbLE, DaBbLE, the Archivist) is instruction-level only: teammates don't run per-agent hooks.
- `claude -p --tools ""` swallows the next positional; pipe the prompt on stdin for headless smoke tests.
- Names: SqUaBbLE (capital U) is final; CrumBbLE is the accepted exception to the real-word rule.
- An old shell keeps the removed `rabble` alias until `unalias rabble` or `exec zsh`.
