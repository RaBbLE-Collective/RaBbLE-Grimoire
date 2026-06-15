# RaBbLE-Collective-Registry.md

```
transcribe ~ grimoire >> registry structure documented // %REGISTRY_LOCKED%
```

> **One-line overview:** The registry lives in `RaBbLE-Grimoire/registry/` — one manifest per member, epoch definitions, and the docs propagation reference.

---

## Where Things Live

```
RaBbLE-Grimoire/           ← the Grimoire IS the registry home
├── registry/
│   ├── CONTEXT.md                      ← this workspace guide
│   ├── RaBbLE-Collective-Registry.md   ← this document
│   ├── epochs/
│   │   └── current.epoch.yml           ← active epoch definition
│   └── manifests/
│       ├── _template.manifest.yml      ← copy to register a new member
│       ├── RaBbLE-sCoRE.manifest.yml
│       ├── RaBbLE-OS.manifest.yml
│       ├── RaBbLE-Frontend.manifest.yml
│       └── RaBbLE-WEB.manifest.yml
├── spells/
│   ├── status.sh          ← health dashboard + episode alignment
│   ├── setup.sh           ← clone + wire all registered members
│   └── init-project.sh    ← scaffold a new member
└── RaBbLE-Agent/                ← canonical docs consumed by all members
```

---

## Manifest Format

Each member is declared in `manifests/RaBbLE-{Name}.manifest.yml`:

```yaml
name: RaBbLE-[Name]
slug: RaBbLE-[Name]
description: "One-line project description"
role: substrate | server | frontend | tooling | experimental

repo: git@github.com:RaBbLE-Collective/RaBbLE-[Name].git
branch: main
worktree_root: ~/RaBbLE-Collective/RaBbLE-[Name]

phase: 0
epoch: 0
status: active | scaffold | dormant | experimental | deprecated
release_track: episode | independent   # episode = airs in lockstep on the epoch active_branch; independent = sandbox/archive
palette_version: "1.0"
entity_embedded: true
pulse_protocol: true
```

---

## Registering a New Member

```bash
bash spells/init-project.sh --slug RaBbLE-[Name] --role [type]
```

This scaffolds the repo with AGENT.md, CONTEXT.md, and workspace structure, then adds a manifest entry. Manual step: add the member to `AGENT.md` Member Registry table and push the new repo to GitHub.

---

## Epoch Coordination

`epochs/current.epoch.yml` defines the active epoch's focus, exit conditions, and member phase targets. When an epoch closes:
1. Move `current.epoch.yml` to `epochs/archive/epoch-{N}.yml`
2. Write a new `current.epoch.yml`
3. Commit with `evolve ~ collective >> Epoch {N} closed, Epoch {N+1} opened`

---

## Propagation — decided: reference, don't duplicate (S105)

There is **no doc-push mechanism**. The Grimoire holds all knowledge and members
reference it **directly** — they never carry a copied or linked grimoire. A member's
`AGENT.md` / `CONTEXT.md` point at Grimoire entries (e.g.
`~/RaBbLE-Collective/RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`) to establish working
state, and member-specific documentation lives **in** the Grimoire under `RaBbLE-<Member>/`.

The former `sync-grimoire.sh` and the `grimoire_sync` / `grimoire_path` manifest fields
are retired. (Submodule / published-package options were considered and rejected: a single
referenced source of truth keeps entropy lowest.)

---

```
transcribe ~ grimoire >> registry crystallized // %REGISTRY_LOCKED%
```
