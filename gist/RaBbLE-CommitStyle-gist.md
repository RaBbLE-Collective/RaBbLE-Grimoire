# RaBbLE-CommitStyle — gist

> Source: `common/RaBbLE-CommitStyle.md` | ~620 → ~150 tokens
> Regenerate: `bash spells/distill-gists.sh`

**Pulse Protocol format:**
```
[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%
```

**Impulses:**
| Impulse | Use when |
|---|---|
| `spark` | New capability manifested |
| `harmonize` | Reducing entropy, cleanup, tuning |
| `mend` | Fixing a bug or logic fracture |
| `transcribe` | Updating docs or lore |
| `ingest` | Adding dependencies or data |
| `glitch` | High-entropy unexpected state change |
| `evolve` | Epoch threshold crossed — `main` only |

**Branch naming:** Descriptive names for active work. `RaBbLE/epoch-<Roman>` for epoch staging. `reliquary/<name>` for archived branches. `main` always stable.

**Rules:** One logical change per commit. Test before committing. Small and often — no monolithic dumps.

**Anti-patterns:** `"fix stuff"` · `"update config"` · `"wip"` · `"changes"` — zero information, useless history.

→ Full doc for: examples, scope rules, branch model detail
