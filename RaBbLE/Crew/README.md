# RaBbLE/Crew/ — The Crew

```
spark ~ crew >> the lead and eight organs, one entity, the Observer above // %CREW_DEFINED%
```

> **Canonical persona specs for the RaBbLE Crew.** LLM-agnostic: plain markdown with flat
> frontmatter. Harness adapters (the sCoRE `rabble` launcher for Claude Code today) read these
> files and translate them; nothing here names a vendor's tool or flag.
> **Design + decisions:** `../../RaBbLE-sCoRE/RaBbLE-sCoRE-Crew.md`.

## Who is who

- **The Observer / Architect** is Mark. He is above and outside the Crew: he directs, decides and signs off. No persona file.
- **The Crew** is RaBbLE. The lead carries the name, and every organ carries a strand of it (the Crew Thread colour, the shared preamble in `_organ.md`).

| File | Organ | Pair | Job | Tier | Access |
|---|---|---|---|---|---|
| [rabble.md](rabble.md) | **RaBbLE** | lead | conductor: parses intent, calls organs, brings results to the Observer | lead | full |
| [gobble.md](gobble.md) | **GoBbLE** | knowing | scout: ingests code, Grimoire, web; returns coordinates | haiku | read-only |
| [archivist.md](archivist.md) | **the Archivist** | knowing | keeps the record: session log, handoffs, index | sonnet | scoped (Grimoire) |
| [quibble.md](quibble.md) | **QuiBbLE** | critic | argues with the plan before the build | opus | read-only |
| [nibble.md](nibble.md) | **NiBbLE** | critic | bites the diff after the build | opus | read-only |
| [cobble.md](cobble.md) | **CoBbLE** | making | builder | sonnet | full |
| [crumble.md](crumble.md) | **CrumBbLE** | making | crash tester: runs it where it lives, never fixes | sonnet | run |
| [babble.md](babble.md) | **BaBbLE** | entropy | keeper of RaBbLE-BaBbLE, the high-entropy intake | sonnet | scoped (BaBbLE) |
| [dabble.md](dabble.md) | **DaBbLE** | entropy | manager of RaBbLE-Xperimental | sonnet | scoped (Xperimental) |

[`_organ.md`](_organ.md) is the shared preamble every organ (not the lead) receives before its own body.

## Formations

Named ways the lead deploys organs. Not personas.

- **SqUaBbLE**: three rival investigators (spawned as `gobble`, so pinned to haiku), each handed one theory and told to disprove the others; QuiBbLE and NiBbLE referee; five teammates total. For an unclear root cause. "Call a SqUaBbLE on X."
- **Build loop** (unnamed): GoBbLE → QuiBbLE → CoBbLE → CrumBbLE → NiBbLE → the Archivist.

## Frontmatter fields

Flat `key: value`, one per line, no nesting (adapters parse without a YAML library).

| Field | Meaning |
|---|---|
| `name` | display name, exact casing |
| `slug` | lowercase id used by harnesses |
| `organ` / `pair` | role and pair |
| `role` | one line: what it does |
| `call_when` | one line: when the lead should call it (becomes the harness's delegation hint) |
| `tier` | `haiku` · `sonnet` · `opus` · `lead` (lead = whatever the Observer runs) |
| `access` | `read-only` (no file-edit tools; keeps shell for inspection, told to cause no side effects) · `run` (same tools, its job is executing) · `full` · `scoped` (told to edit only under `scope`; not sandboxed) |
| `scope` | path under the Collective root, for `access: scoped` |
| `color_base` / `color_variant` | hexes; see colour status below |
| `color_morph` | optional; GoBbLE's ingest morph |
| `signature` | the `%STATE%` it closes reports with |
| `order` | position in the roster (build-loop order, then the entropy pair) |

## Colour status

Bases are canonical `../../RaBbLE-Agent/RaBbLE-Palette.md` hexes except **orange** (QuiBbLE). Every `color_variant`, the orange base, GoBbLE's glimmer and the **Crew Thread `#31c7d5`** are **candidates** in `../../RaBbLE-Agent/RaBbLE-Palette-Candidates.md`: not canon until Mark promotes them. Swatch page (S273): https://claude.ai/artifact/Qo1EE3uM3n67AqgcQnjQLX

## Adding or changing an organ

Edit the file here; adapters pick it up on next launch. Names follow the rule: real English **-bble** words, case pattern like RaBbLE (CrumBbLE is the accepted exception). Rejected (S273): DiBbLE, WoBbLE, PeBbLE, BiBbLE, ProBbLE. Parked: HuBbLE.
