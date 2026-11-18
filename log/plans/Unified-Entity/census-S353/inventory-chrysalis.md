# Inventory: RaBbLE-Chrysalis (read-only survey, branch `main`)

Note: Chrysalis has no CONTEXT.md; only AGENT.md + README.md. All files below are published at **https://chrysalis.joinrabble.world/** (wrangler.jsonc: worker `rabble-chrysalis-web`, assets dir = `Chrysalis-Web/`, custom_domain chrysalis.joinrabble.world). URL = `https://chrysalis.joinrabble.world/<path under Chrysalis-Web/>`.

## 1. Entity-render files already in Chrysalis

| File (under Chrysalis-Web/) | Draws | Last commit | Live duplicate? (md5 prefix) |
|---|---|---|---|
| `ep1/world/RaBbLE-Face.html` | S203 "entity-forward face" (canvas2d entity as the room, chat as input). Never aired; header comment records provenance (World 2434da6/e9728cd, retired S234) | 7e1513d 2026-09-27 S235 | No copy elsewhere (6d9a26cf8c) |
| `ep1/world/js/RaBbLE-face.js` | JS for the above | 7e1513d S235 | Similar name in `RaBbLE-World/world/js/RaBbLE-face.js` but NOT identical (cc0e27ee vs 3105b94e; ~568 diff lines). Not a dup |
| `ep1/world/RaBbLE-NeBuLA.html`, `RaBbLE-NeBuLA-Demo.html`, `RaBbLE-Liminal-Passage.html`, `RaBbLE-Boot.html`, `RaBbLE-Studio.html`, `RaBbLE-Shell.html` (+ `css/RaBbLE-face.css`, `css/RaBbLE-landing-stage.css`) | EP1 World pages that embed/mention the entity/portals (June 2026 world; Liminal passage retired S203) | 5ac288e 2026-06-25 (Aether fix); Liminal 6c57c11 S203 | Not checked in detail; frozen reliquary of old World |
| `world-2026-06/` (index, world/, icons) | joinrabble.world as it stood, frozen at World e7e5b51 (30de4b0, S318) | 30de4b0 | Frozen copy of the old World site |
| `JS-Xperiments/WebOS/js/RabbleEyes.js` | Three.js pair of eyes (RabbleJS v0.0.1-0.1.1), plus `RabbleEyes.jpeg` | ec0a058 2026-06-24 | None (404984cb) |
| `JS-Xperiments/WebOS/js/RabbleCanvas.js`, `Rabble.js`, `rabble.html` | 3D holographic renderer / WebOS | ec0a058 | None |
| `JS-Xperiments/NeBuLA-JS/NeBuLA/core/q_entity.js` + EntropyCanvas, CosmicVessel, EntropyGarden, shaders, examples | NeBuLA-JS ancestor engine ("quantum entity" = pipeline unit, not the RaBbLE face) | ec0a058 | None; ancestor of RaBbLE-NeBuLA |
| `Python-Xperiments/RaBbLE.py/src/animation/eye.py`, `face.py`, `config/face_layout.rabl` | pygame animated face, the first thing that looked like RaBbLE | dd1c0bf 2026-06-24 | Not identical to `RaBbLE-sCoRE/ui/face.py` (a73ed9c6) or `BaBbLE/prototypes/terminal-face/face.py` (214eb157) vs eye/face.py (925ccf14 / befe6f7a). Distinct lineage |
| `Python-Xperiments/RaBbLE-Server/showcase.html` | server showcase page (mentions entity; not a render) | 5efed95 | None |

No file in Chrysalis is a byte-identical duplicate of a live render elsewhere. None of the Pocket mock, rig, Ball, or BaBbLE drifters are in Chrysalis yet (md5s of the drifters: `rabble-pocket-entity.html` Pocket c02f01b4 vs BaBbLE intake 8e55286e DIFFER; `rabble-entity-rig.html` BaBbLE f0abc55b only one found in the Collective outside Xperimental, which was not scanned).

Stray: `RaBbLE-Xperimental/` inside Chrysalis is a nested git repo, gitignored ("separate local surface, not part of Chrysalis"); ignore.

## 2. Structure and conventions

- Branches: `main` = readable genesis snapshots + site; `archive/*` = full histories of pre-Collective repos (rabble-py-main, rabble-js, nebula-main, ...; remote also has `archive/world-history`, `archive/nebula-world-perf` not yet in README table); `reliquary/os/*` = sealed OS eras. Tip commit of sealed branches: `archive ~ reliquary >> [name] sealed - reference only // %RELIQUARY_SEALED%`, made by `spells/seal-branch.sh <source-repo> <branch> [target]` (imports via temp remote; source branch then deleted). Branch seals are for whole branch eras; for loose FILES the precedent is a commit onto `main`.
- File precedent on main: S203/S235/S249 freezes under `Chrysalis-Web/ep1/world/` with a long header comment (what it was, built when, source commit hashes, why retired); commit style `transcribe ~ chrysalis >> <what frozen> // %S###_RELIQUARY%`. Frozen pages are kept running (S249 "reliquary renders again", Aether pinned rc.2).
- Index files: `README.md` (genesis tree + branch map tables + "How things end up here"), `AGENT.md`, `Chrysalis-Web/index.html` (node cards: ep1/, world-2026-06/, NeBuLA-JS, WebOS, RaBbLE.py, RaBbLE-Server; each has a `node-path` label). New area = new card + README tree entry.
- Deploy: `_headers` CSP (S333; add any new script/style origin there), no Worker code; `spells/dev-serve.sh` for local; CI deploy workflow in `.github/`.
- Provenance is recorded in: file header comments, commit message, README tables. There is no manifest/JSON and no per-folder README convention yet.
- Rule: "never add new features"; frozen copy stays even if something is revived; reliquary is added to, never edited.

## 3. Proposal: where entity renders land

```
Chrysalis-Web/entity-renders/            (new; one card on index.html, one block in README tree)
  README.md                              provenance table: file | origin repo+path | origin commit/sha | md5 | date moved (S###) | why retired | canonical replacement
  pocket-mock/rabble-pocket-entity.html
  rig-intake/rabble-entity-rig.html
  ball/RaBbLE-Ball.html
  babble-prototypes/{RaBbLE.html, boot/, terminal-face/face.py, alive/body*.js}
  xperimental-drops/<drop-name>/         only drops Mark rules as drifters
```
Dup copies from different origins keep distinct sub-paths only if md5 differs; if identical, keep one and list both origins in the provenance table. Add the `entity-renders` label to any file that has a runtime dependence on CDNs, and update `_headers` if a new origin is needed. The BaBbLE `reliquary/2026-09-26-entity-harness`: it is already a reliquary, so copy to `Chrysalis-Web/entity-renders/entity-harness-2026-09-26/` (or seal as a branch `reliquary/babble/entity-harness` via seal-branch.sh if it has history worth keeping; README promises "reliquary other members (incoming)").
Each moved file gets a header comment in the S235 style (origin path, sha, retired-when, replaced-by); do not alter bodies otherwise (md5 check recorded).

Pointer left in the old place (condense-not-delete): a small `<name>.MOVED.md` (or replace the file with a stub HTML for pages that have a published URL) containing: moved-to path in Chrysalis + published URL `https://chrysalis.joinrabble.world/entity-renders/...`, origin sha/md5, date + S###, canonical replacement (NeBuLA path). For Xperimental drops with a live URL, stub HTML with a meta refresh to the Chrysalis URL, so the link does not 404. Commit pair: Chrysalis `transcribe ~ chrysalis >> entity renders from <repo> frozen // %S###_RELIQUARY%`, origin repo `harmonize ~ <organ> >> drifters pointed at Chrysalis // %S###_STATE%`. Chrysalis commit first so the pointer never dangles; also update the Grimoire index (U12).

Open for Mark: files vs sealed branch for the harness; whether `entity-renders/` should be a Chrysalis subtree or the existing `ep1/`-style dated folder (`entity-renders-2026-11/`) to match `world-2026-06/` naming.
