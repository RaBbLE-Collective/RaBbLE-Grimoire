# CommitStyle — gist

> Source: `RaBbLE-Agent/RaBbLE-CommitStyle.md` | ~620 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

The Pulse Protocol: RaBbLE's commit message format and branch naming model, built for high-information, system-specific history.

**Format:** `[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%`
- organ = component being changed; revelation = what was learned, fixed, or created (be specific)
- `%SYSTEM_STATE%` is optional and machine-parseable

**Impulses**

| Impulse | Meaning |
| :--- | :--- |
| `spark` | New capability manifested |
| `harmonize` | Enforce Low Entropy, reduce noise |
| `mend` | Fix a logic-fracture or drift |
| `transcribe` | Update lore or self-description (docs) |
| `ingest` | New dependencies, binaries, data-stores |
| `glitch` | State change from incoming IPC or entropy spikes |
| `evolve` | Epoch threshold crossed; epoch-landing commits on `main` only |

**Branches** (no semver; evolutionary model)

| Pattern | Purpose |
| :--- | :--- |
| `RaBbLE/epoch-<Roman>` | Epoch staging before landing on `main` (e.g. `RaBbLE/epoch-I`) |
| `reliquary/<name>` | Archived, inert reference branches |
| `<descriptive-name>` | Active work, named for the spirit of the work (e.g. `RaBbLE-OS-New-Horizons`) |

- Epoch commit: `evolve ~ substrate >> epoch-I crystallized // %EPOCH_I_LANDED%`
- Versions are human translations of thresholds already crossed, not targets set in advance

**Scope rules:** one logical change per commit · test before committing · commit small, often

**Anti-patterns:** "fix stuff", "update config", "wip", "changes"

→ Full doc for: example commits, impulse phrasing nuance, anti-pattern rationale, `%SYSTEM_DRIFT%` note, branch naming examples
