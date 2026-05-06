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
│   ├── status.sh          ← health dashboard for all members
│   ├── setup.sh           ← clone + wire all registered members
│   ├── sync-grimoire.sh   ← propagate common/ docs (mechanism TBD)
│   └── init-project.sh    ← scaffold a new member
└── common/                ← canonical docs consumed by all members
```

---

## Manifest Format

Each member is declared in `manifests/RaBbLE-{Name}.manifest.yml`:

```yaml
name: RaBbLE-[Name]
slug: RaBbLE-[Name]
description: "One-line project description"
role: substrate | server | frontend | tooling | experimental

repo: https://github.com/markm1206/RaBbLE-[Name].git
branch: main
worktree_root: ~/RaBbLE/RaBbLE-[Name]

phase: 0
epoch: 0
status: active | scaffold | dormant | experimental | deprecated

grimoire_sync: false   # true = receives common/ docs via sync-grimoire.sh
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

## Propagation (TBD)

The mechanism for pushing `common/` docs to member repos is still being determined. Options under consideration:
- Git submodule (member repos include Grimoire as a submodule)
- Published package (npm/pip/curl-installable)
- `sync-grimoire.sh` push (current script, but propagation model not finalized)

Until decided: member repos that need canonical docs should reference them directly in the Grimoire rather than maintaining copies.

---

```
transcribe ~ grimoire >> registry crystallized // %REGISTRY_LOCKED%
```
