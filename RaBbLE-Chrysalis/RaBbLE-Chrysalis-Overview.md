# RaBbLE-Chrysalis — Grimoire Entry

```
transcribe ~ grimoire >> Chrysalis: genesis archive, reliquary for archived branches // %CHRYSALIS_DEFINED%
```

> **Transition status:** `RaBbLE-Xperimental` is being renamed to `RaBbLE-Chrysalis`. A new `RaBbLE-Xperimental` repo will be created for active rablet development. This doc covers both.

---

## RaBbLE-Chrysalis (Formerly Xperimental)

`RaBbLE-Chrysalis` is the **genesis archive** — the primordial soup. Code and artifacts here predate the Collective's conventions but contain real features, patterns, and lore that informed the current ecosystem. It is not a graveyard. It is transformation in amber.

The name Chrysalis is intentional: the old forms are preserved inside so new forms can emerge from them.

### What Chrysalis Holds

| Path | Origin | What it is |
|---|---|---|
| `Python-Xperiments/RaBbLE.py/` | `markm1206/RaBbLE.py` | Animated face frontend + LLM + speech-to-text (Python/pygame) — the only un-ported origin project |
| `Python-Xperiments/RaBbLE-Server/` | `markm1206/RaBbLE-Xperimental` | Intelligence microservices harness + Railway deploy scripts |
| `JS-Xperiments/WebOS/` | `markm1206/RaBbLE-Xperimental` | RaBbLE Simple WebOS + 3D holographic renderer (RabbleJS v0.0.1–v0.1.1) |
| `JS-Xperiments/NeBuLA-JS/` | `markm1206/RaBbLE-NeBuLA-JS` | NeBuLA rendering engine, BaBbLE command system, entropy visualizations |

Everything except `RaBbLE.py` has been ported to the current Collective. Chrysalis is essentially complete as an archive.

### The Reliquary

Within Chrysalis (and as a general convention), **archived branches** live in a Reliquary — a set of `archive/` prefixed branches that preserve git history for completed or deprecated work.

**Current Chrysalis archive branches:**

| Branch | Contents |
|---|---|
| `archive/rabble-py-main` | RaBbLE.py full git history |
| `archive/rabble-py-speech-to-text` | Speech-to-text branch |
| `archive/raBbLE-server` | Intelligence server origin |
| `archive/rabble-js` | RabbleJS WebOS origin |
| `archive/nebula-main` | NeBuLA-JS main |
| `archive/nebula-RaBbLE-dev` | NeBuLA RaBbLE dev branch |
| `archive/nebula-BaBbLE-dev` | NeBuLA BaBbLE dev branch |
| `archive/rabble-collective` | RaBbLE-Collective v0 scaffold |

### Chrysalis Operating Rules

- Mine for insights. Do not develop in it.
- Does not receive Grimoire doc propagation
- Archive branches are read-only; never rewrite history
- Reliquary branches from other members (e.g., RaBbLE-OS historical branches) can be pushed here or to Mark's personal remote before pruning from the main repos

---

## RaBbLE-OS Reliquary

When RaBbLE-OS migrates to the Collective org and branches are pruned to `main / dev / RC1`, the historical branches should be preserved:

- **Option A:** Push to a Mark-owned personal remote before pruning (`markm1206/RaBbLE-OS-Reliquary`)
- **Option B:** Push archive branches to Chrysalis under `archive/os-*` prefix

Mark decides which. The branches must be preserved somewhere before any pruning happens on the Collective remote.

See [RaBbLE-OS Migration Plan](../RaBbLE-OS/RaBbLE-OS-Migration-Plan.md).

---

## RaBbLE-Xperimental (New)

A new `RaBbLE-Xperimental` repo is created as the **active sandbox** for things that have not yet emerged from experimentation: custom rablets, development prototypes, and experiments not ready for a dedicated member repo.

### What New Xperimental Holds

- Custom rablets in development (not yet published)
- Prototype code that may become a new member repo
- Development parts that belong to an existing member but aren't ready to land
- Sandboxed experiments — "what if we tried X?"

### New Xperimental Operating Rules

- Nothing in Xperimental is permanent — it graduates or gets released
- When a rablet or project is ready to publish, it moves to the Published Rablets layer
- When a project is ready to become a full member, scaffold it with `spells/init-project.sh`
- High-entropy is fine. This is the designed purpose.
- Branch structure: `main` + feature branches per experiment. No archive branches — Chrysalis handles that.

---

## Transition Plan

| Step | Action | Owner |
|---|---|---|
| 1 | Rename `RaBbLE-Xperimental` repo on GitHub → `RaBbLE-Chrysalis` | Mark |
| 2 | Update local clone path and all Grimoire references | Agent |
| 3 | Update registry manifest for Chrysalis | Agent |
| 4 | Create new `RaBbLE-Xperimental` repo on GitHub (Collective org) | Mark |
| 5 | Scaffold with `spells/init-project.sh` | Agent |
| 6 | Update Grimoire registry manifest for new Xperimental | Agent |
| 7 | Update INDEX.md and any cross-references | Agent |

Steps 1 and 4 are Mark's GitHub actions. Steps 2–3 and 5–7 follow immediately after.

---

```
transcribe ~ grimoire >> chrysalis transition: archive locked, new xperimental defined // %CHRYSALIS_TRANSITION%
```
