# RaBbLE-Grimoire

```
transcribe ~ grimoire >> soul made legible // %GRIMOIRE_OPEN%
```

> The soul of the Collective. One grimoire. All knowledge.

The canonical knowledge layer of the [RaBbLE Collective](https://joinrabble.world): identity, ethos, lore, conventions,
member architecture and roadmaps, the member registry, and the spells that coordinate it all. Member repos hold code;
they reference the Grimoire and never duplicate it.

---

## Start Here

| You have | Read |
|---|---|
| 2 minutes | [`gist/`](gist/RaBbLE-Gist-Overview.md): every key doc distilled (~3,000 tokens for all of it) |
| 10 minutes | [`CONTEXT.md`](CONTEXT.md) (current state) · [`RaBbLE-Agent/RaBbLE-Roadmap.md`](RaBbLE-Agent/RaBbLE-Roadmap.md) (where everything stands) |
| a task | [`RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md`](RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md): reading paths and jump-to-task table |
| a specific doc in mind | [`INDEX.md`](INDEX.md): every document, by section |

Who RaBbLE is: [`RaBbLE-Agent/RaBbLE-Identity.md`](RaBbLE-Agent/RaBbLE-Identity.md). How the Collective fits together:
[`RaBbLE-Agent/RaBbLE-Collective.md`](RaBbLE-Agent/RaBbLE-Collective.md).

---

## Structure

```
RaBbLE-Grimoire/
├── gist/                # Distilled orientation (also served at grimoire.joinrabble.world)
├── RaBbLE-Agent/        # Cross-member canon: identity, palette, commit style, roadmap, protocols
├── RaBbLE/              # The entity's inner life: ethos, genesis, worldbuilding, PRD
├── RaBbLE-Mythos/       # Fiction and creative writing
├── RaBbLE-Collective/   # Ecosystem-level plans: deployment, Cloudflare, membership, secrets
├── RaBbLE-<Member>/     # Per-member architecture + roadmap (OS, sCoRE, World, NeBuLA, Aether, ...)
├── registry/            # Member manifests + current epoch (machine-readable state)
├── spells/              # Coordination scripts (see SPELLS.md)
├── log/                 # Session log, air checklist, blockers, plans/, handoffs/, decisions
├── CONTEXT.md           # Current state and active tracks
├── INDEX.md             # Full document index
└── RaBbLE-Versioning.md # The Five Es: Event, Episode, Echo, Evolution, Epoch
```

---

## Contributing

- [`RaBbLE-Agent/RaBbLE-CommitStyle.md`](RaBbLE-Agent/RaBbLE-CommitStyle.md): the Pulse Protocol
- [`RaBbLE-Agent/RaBbLE-BranchStrategy.md`](RaBbLE-Agent/RaBbLE-BranchStrategy.md): branch topology
- New docs go where `AGENT.md` § Adding New Docs says, and get a line in `INDEX.md`.

The Grimoire evolves through `transcribe` and `spark` impulses. One logical change per commit.

Licensed under the Sovereign Accord (source-available): see [`LICENSE`](LICENSE).

---

```
transcribe ~ grimoire >> README crystallized // %GRIMOIRE_OPEN%
```
