# registry/entity

The RaBbLE entity registry: the one place an entity number lives. Contract: `RaBbLE-Entity-Registry-Schema.md`.

| File | What |
|---|---|
| `rabble.entity.json` | the registry, v0.1.0: vocabulary, aliases, base (rig numbers), 55 effects, ordered layers, timelines, 7 surface profiles. No hex; colours are Palette names. Canonical format (sorted keys, 2-space indent, trailing newline). |
| `rabble.entity.schema.json` | machine shape (JSON Schema 2020-12). |
| `validate.py` | checks V1-V12 plus V6b (turn and portal_swap never `none`). |
| `tests/` | pytest suite: the real registry must pass; one mutation fixture per check must fail with its own code. |

## Setup and run

```bash
cd RaBbLE-Grimoire/registry/entity
uv venv .venv && uv pip install jsonschema pytest
.venv/bin/python validate.py                 # validates rabble.entity.json; exit 1 on any error
.venv/bin/python validate.py other.json --palette ../../RaBbLE-Agent/RaBbLE-Palette.md
.venv/bin/python -m pytest -q tests
```

Errors fail the run. Warnings do not: V11 lists `pocket_hw` `full` effects with no `cost.device.measured`; V5 lists parked seed poses (joy, sad, angry) that put an eye past its portal plane at rest. A measured effect over `budget_ms` is a V11 error.

## Checks in brief

V1 schema · V2 vocabulary closure and alias hygiene · V3 Palette (parsed from `RaBbLE-Agent/RaBbLE-Palette.md`, no hex anywhere, schema colour pattern matches the Palette) · V4 envelope and rest portal Y 1.00 · V5 no-touch at rest forms and every 1/60 s through `portal_swap`, `turn` and blink (portal-portal, eye-eye, eye vs other portal with a depth test; eye tip not past its own plane; lower-role near rim not over its eye) · V6 effects, support entries, core group order, eyes never disabled · V6b move support · V7 drives · V8 timelines (targets: `layer:<id>.<param>`, `mood.<id>`, a base path, or `body.eye.sx|sy|blink`, `body.portal.sy`, `body.dim`, `body.recede`) · V9 expression limits · V10 profile overrides · V11 device budget · V12 canonical format.

## Fixtures

`tests/fixtures/*.json` are small mutation files (`check`, `description`, `ops`: set or delete a path, or `serialize: indent4`) applied in memory to the real registry, so they never drift from it. Edit the registry, then rerun the tests.
