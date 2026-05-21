# RaBbLE-Agent-Protocols.md — Behavioral Rules for Agents

```
transcribe ~ grimoire >> agent protocols distilled from session memory // %PROTOCOLS_LIVE%
```

> Hard-won rules from sessions with this codebase. Each rule has caused at least one debugging session when broken. Read before touching anything.
>
> Source: distilled from `.claude` session memory across Sessions 13–24.

---

## Doc Management

### Condense, never delete

When asked to clean docs, logs, or audit files: (1) identify the canonical home for each piece of useful content, (2) merge content there, (3) reduce the original to a ~10-line pointer file that says "content moved to X." Do not `rm` or `git rm` without condensing first.

**Why:** Deletion loses context even when content seems redundant. Condensation moves value to permanent homes while keeping the artifact readable as a pointer.

---

## Repo Management

### No worktrees in member repos

Never set up or suggest git worktrees inside member repos. Use branches for isolation.

**Why:** Extra files and duplicate directories clutter the repo. User preference: "I don't like how worktrees create a lot of additional files and new identical directories in a repo."

### Collective root naming

Refer to the top-level workspace as "the Collective root" or "RaBbLE-Collective" — not by a filesystem path. Paths are machine-specific; Collective-relative naming is canonical.

### Grimoire has no self-manifest

The Grimoire does not need a `_template.manifest.yml` entry for itself. It is ensured to exist via `bootstrap.sh` / `setup.sh`. Don't create one.

---

## Grimoire as Documentation Home

All architecture, API, usage, and design docs live in the Grimoire. Member repos contain only source code, tests, build config, and an AGENT.md that points to Grimoire docs.

**Workflow when building:**
1. **Design/document first in Grimoire** — API spec, usage examples, integration patterns, CONTEXT.md progress updates
2. **Implement in member repo** — code follows the Grimoire spec; member AGENT.md points back
3. **Update Grimoire as you learn** — if the spec was wrong, fix it; document edge cases; record trade-offs

**Why:** Members evolve. Docs must stay in one place or they rot. The Collective enforces this: "Members reference Grimoire; never duplicate Grimoire content in members."

---

## Member Responsibility Split

Before writing any visual or styled element in World, apply this split:

| Member | Owns |
|---|---|
| **NeBuLA** | All visual effects and animated rendering — SVG factories, canvas, particle systems. Export under `window.NeBuLA.ui.*` |
| **Aether** | CSS, design tokens, look and feel. Shared component styles. Never hex values in member pages — use Aether tokens |
| **World** | Thin scaffold only — state machines, data, DOM assembly, mounting. No rendering logic of its own |

**Test:** "Is this an effect?" → NeBuLA factory. "Is this a reusable style?" → Aether eventually. "Is this assembly?" → World.

**Why:** Mixing rendering into World or styles into NeBuLA creates coupling that makes members harder to evolve independently.

---

## World Tech Constraints

### Vanilla JS only — no React, no Babel

World uses no bundler, no build step, no frameworks beyond Alpine.js (already loaded for declarative UI). When a component needs adding, write it in vanilla JS.

**Why:** Babel-standalone in-browser transpilation was considered and rejected. World's architecture is deliberately minimal.

**How:** If a design prototype is written in JSX (e.g. from BaBbLE or grimoire-variants.jsx), convert it to vanilla JS before landing it in World. The established idiom is the NeBuLA.ui factory pattern:

```js
// Factory returns { el, ...controls, destroy() }
function createMyComponent(opts) {
  const el = document.createElement('div');
  // ...
  return { el, destroy() { el.remove(); } };
}
```

---

## NeBuLA Build Workflow

### Always build and copy before testing or committing

After **any** change to `RaBbLE-NeBuLA/src/`:

```bash
npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js
```

Do this **before** asking the user to test, and **before** committing World.

**Why:** The World page loads an inlined IIFE bundle directly — `world/js/RaBbLE-NeBuLA.js`. Editing `src/backends/canvas2d-backend.js` or any other source file is invisible until the bundle is rebuilt and copied. This caused a full triage session where fixes appeared to fail because an old bundle was still running.

---

## Dev Environment

### Use dev-serve.sh — never run sub-processes directly

Always start the dev environment with:

```bash
bash RaBbLE-Grimoire/spells/dev-serve.sh
```

**Never run** `node RaBbLE-Grimoire/spells/dev-cdn.js` or `npx esbuild ... --watch` directly.

**Why:** Running the server or watchers manually orphans processes on port 8000. When the user later runs `dev-serve.sh`, it fails with `EADDRINUSE`. This caused a multi-session debugging nightmare where Aether CSS appeared to load (curl returned 200 from the orphaned server) but wasn't actually serving fresh content.

### Aether file names in dev vs prod

| Context | File | Built by |
|---|---|---|
| Dev | `dist/aether.css` | `build:watch` or `build:dev` |
| Production | `dist/aether.min.css` | `build:min` / `build` |

HTML pages link to `aether.css` in dev — **NOT** `aether.min.css`. Linking to the min file means the watcher never updates what the browser loads — a silent failure.

---

## Entity Naming and Spell Vocabulary

- **`RaBbLE`** — always this capitalisation. Informal aliases (`rabble`, `RABBLE`) are tolerated, but RaBbLE knows it was misnamed.
- **`cast`** — spells are **cast**, not summoned. Post-install incantation: `RaBbLE cast <spell>`
- **`summon`** — reserved for summoning an entity. `score summon RaBbLE` is correct. Do not use `summon` for running scripts.
- **Inside the Collective** (pre-install wizard phase): `bash spells/<spell>.sh`. No global `RaBbLE` command yet.

---

## Versioning Protocol

See `RaBbLE-Grimoire/RaBbLE-Versioning.md` and `registry/epochs/current.epoch.yml` for the full Five-Es spec. Key operational rules:

- All package.json: `"version": "0.0.0.0"` (pre-Episode-1), `"0.0.0.1"` (after Episode 1 airs)
- Episodes are **not declared open** — they air retroactively when a stable-ish point is reached
- Episode 1 airs **simultaneously** across all active members — no per-project drift yet
- After Episode 1: per-project pacing allowed, but max divergence ~1-2 episodes toward Echo
- **Epoch 1 is far away.** Near milestone: Episode 1 air → more Episodes → Echo 1 (first broad stable release). Don't conflate Episode with Echo with Epoch.
- **Episode names follow a Biblical arc — intentional lore.** Episode 1 = Genesis (the beginning; entity first breathes). Episode 2 = Exodus (emergence; entity departs concept and enters reality). Don't rename, neutralize, or treat these as placeholders. Future episode names should continue the arc.
- `current.epoch.yml` in `registry/epochs/` is authoritative for Collective position

---

```
transcribe ~ grimoire >> protocols locked // %PROTOCOLS_LIVE%
```
