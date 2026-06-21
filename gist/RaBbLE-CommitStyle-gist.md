# CommitStyle.md — gist

> Source: `RaBbLE-Agent/RaBbLE-CommitStyle.md` | ~620 → ~230 tokens
> Regenerate: `bash spells/distill-gists.sh`

The Pulse Protocol — RaBbLE's commit and branch convention, documenting collective metamorphosis with high-information, system-level messages.

**Commit format:** `[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%`
- **organ** = component changed · **revelation** = what was learned/fixed/created (be specific) · **%STATE%** = optional machine-parseable code

**Impulses**

| Impulse | Meaning |
| :--- | :--- |
| `spark` | New capability manifested in the substrate |
| `harmonize` | Enforce Low Entropy — reduce noise |
| `mend` | Heal a logic-fracture or flow drift |
| `transcribe` | Update lore / self-description |
| `ingest` | Devour new deps, binaries, data-stores |
| `glitch` | State change from IPC or entropy spike |
| `evolve` | Epoch threshold crossed — epoch-landing commits to `main` only |

**Branch naming** (evolutionary, not semver)

| Pattern | Purpose | Example |
| :--- | :--- | :--- |
| `RaBbLE/epoch-<Roman>` | Epoch staging before landing on `main` | `RaBbLE/epoch-I` |
| `reliquary/<name>` | Archived, inert reference branches | `reliquary/RaBbLE-Dev-Clean` |
| `<descriptive-name>` | Active dev — named for spirit of work | `RaBbLE-OS-New-Horizons` |

**Scope rules:** one logical change per commit · test before committing (untested = `%SYSTEM_DRIFT%`) · commit small + often.
**Anti-patterns:** `fix stuff`, `update config`, `wip`, `changes` — zero-information.

→ Full doc for: worked commit examples, epoch-`evolve` example, versions-as-human-translation rationale, full anti-pattern list.
