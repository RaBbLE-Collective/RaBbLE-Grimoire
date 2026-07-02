# CommitStyle.md — gist

> Source: `RaBbLE-Agent/RaBbLE-CommitStyle.md` | ~620 → ~230 tokens
> Regenerate: `bash spells/distill-gists.sh`

The **Pulse Protocol** — high-information, system-specific commit and branch conventions for the Collective's metamorphosis.

**Commit format:** `[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%`
- **organ** = component changed · **revelation** = what was learned/fixed/created (be specific) · **%STATE%** = optional machine-parseable code

**Impulses**

| Impulse | Meaning |
| :--- | :--- |
| `spark` | New curiosity/capability manifested |
| `harmonize` | Enforce Low Entropy; reduce noise |
| `mend` | Heal a logic-fracture or flow drift |
| `transcribe` | Update lore / self-description |
| `ingest` | Devour deps, binaries, data-stores |
| `glitch` | State change from IPC / entropy spike |
| `evolve` | Epoch threshold crossed — epoch-landing commits to `main` only |

**Examples**
- `spark ~ ear-module >> adding natural language eavesdropping // 0xFEED_BEEF`
- `ingest ~ belly >> devouring jq for faster stream-tasting // %IPC_RECV%`
- `evolve ~ substrate >> epoch-I crystallized // %EPOCH_I_LANDED%`

**Branches** (no semver — evolutionary model)

| Pattern | Purpose | Example |
| :--- | :--- | :--- |
| `RaBbLE/epoch-<Roman>` | Epoch staging before `main` | `RaBbLE/epoch-I` |
| `reliquary/<name>` | Archived, inert reference | `reliquary/RaBbLE-Dev-Clean` |
| `<descriptive-name>` | Active dev, named for spirit | `RaBbLE-OS-New-Horizons` |

**Scope rules:** one logical change/commit · test first (untested = `%SYSTEM_DRIFT%`) · commit small & often.
**Anti-patterns:** `fix stuff`, `update config`, `wip`, `changes` — zero-information.

→ Full doc for: full example set, versions-as-human-translations rationale, complete anti-pattern reasoning, protocol framing prose.
