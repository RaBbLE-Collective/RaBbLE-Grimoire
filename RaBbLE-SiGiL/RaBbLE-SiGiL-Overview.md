# RaBbLE-SiGiL — Visual Asset Store

```
spark ~ sigil >> bytes stay home, the index travels // %SIGIL_SCAFFOLD%
```

> **Status:** scaffold · named by Mark 2026-10-27 (S282) · ingest spell live, R2 mirror not built.
> **Rule:** a grimoire holds sigils, so SiGiL lives in the Grimoire. Git tracks only the **index** (`index/` sidecars); the art bytes sit beside it in `store/`, which `.gitignore` excludes. Nothing in `store/` ever enters a commit.

## Provenance (the primary axis)

Every asset declares where it came from. This decides its folder, its required metadata and its default rights.

| Provenance | What it is | Extra sidecar fields | Default rights |
|---|---|---|---|
| `human` | Hand-made: ink, paint, sculpture photos, hand-built logos | `medium`, `made` | `collective-original` |
| `captured` | Screenshots, renders, recordings taken from the running system | `captured_from` (page, app, session) | `collective-original` |
| `ai` | AI-generated, including AI-assisted | `model`, `prompt`, `human_edited` | `ai-generated-review` |

A provenance label is a claim. If unsure, hold the file in `_inbox/` and ask; do not guess. `ai-generated-review` means rights and disclosure are unresolved until Mark settles them (see `RaBbLE-Collective/RaBbLE-Brand-and-Entity-Policy-DRAFT.md`).

## Layout

```
RaBbLE-Grimoire/RaBbLE-SiGiL/
  index/{human,captured,ai}/<id12>-<slug>.yml   TRACKED: one sidecar per asset (source of truth)
  RaBbLE-SiGiL-Index.md                  TRACKED: generated browse table, never hand-edit
  RaBbLE-SiGiL-Overview.md               TRACKED: this doc
  store/                                 GIT-IGNORED: the bytes
    _inbox/{human,captured,ai}/          drop new art here
    {human,captured,ai}/<year>/<id12>-<slug>.<ext>
```

`id12` is the first 12 hex chars of the file's sha256, so the same file can never be indexed twice and a missing or corrupt file is detectable.

## Adding art

```bash
# Easiest: drop files in the right _inbox/<provenance>/ folder, then
bash spells/asset-ingest.sh inbox   # drains RaBbLE-SiGiL/store/_inbox/

# Or direct (copy by default; --move to relocate; --dry-run to preview)
bash spells/asset-ingest.sh ingest ~/Art/new/ --provenance human --medium ink --role sketch
bash spells/asset-ingest.sh ingest shot.png --provenance captured --source "world/index @ dev"
bash spells/asset-ingest.sh ingest gen.png --provenance ai --model <model> --prompt "<prompt>"
```

New sidecars start as `status: draft`. `bash spells/asset-ingest.sh pending` lists drafts with absolute paths; a vision-capable agent opens each, proposes title, role, tags and description, and Mark confirms by setting `status: reviewed`. `verify [--deep]` checks the index against the store; `reindex` rebuilds the browse table.

Roles: logo, wordmark, entity, scene, ui, texture, marketing, study, sketch, photo, icon, other.

## Open items

- **Genesis migration:** 10 hand-made Genesis images are indexed as `human` (copied, originals still tracked in `RaBbLE/Genesis/visual/`). Three look like renders and wait on Mark's provenance call: `entity-scene-3d-base.png`, `entity-scene-3d-glitch.png`, `study-entity-wireframe-animated.gif`. Removing the tracked originals from git, and repointing `RaBbLE-Genesis-Visual-Catalog.md`, is a separate decision (condense, not delete).
- **R2 mirror and backup:** sidecars carry the hash, so a mirror needs no index change. A fresh clone gets the index but not the art, so until the mirror exists back up `RaBbLE-SiGiL/store/` yourself. `RABBLE_ASSETS=/path` relocates the store (e.g. to a bigger disk) without touching the index.
- **Captures:** `RaBbLE-BaBbLE/captures/` is not yet indexed; `captured` is its natural home.
- **Consumers:** World, NeBuLA and the press kits should resolve assets by id through the index, not by path.
