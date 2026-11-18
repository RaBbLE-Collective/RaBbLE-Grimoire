# NeBuLA Effects Support Table

> Generated file. Do not edit by hand.
> Source: `RaBbLE-Grimoire/registry/entity/rabble.entity.json` (registry version 0.1.0).
> Regenerate: `RaBbLE-Grimoire/registry/entity/.venv/bin/python RaBbLE-Grimoire/registry/entity/gen/support_table.py`

Per-effect, per-surface support taken from the entity registry. Contract: `RaBbLE-Grimoire/registry/entity/RaBbLE-Entity-Registry-Schema.md`.

## Legend

- **full**: the effect runs with its base parameters on that surface.
- **reduced**: the same idea at a lower cost, using the effect's `reduced` overrides.
- **none**: skipped on that surface without error.
- **Priority**: 0 = defining (never yields, eyes and portals), 1 = key expression, 2 = expressive, 3 = ambient, 4 = decor. Lower numbers yield last; priority 0 never yields.
- **Cost tier**: trivial, low, medium or high (registry estimate; device cost is filled only from measurement).

## Group: aura

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `aura.bolts` | Bolts | 3 | low | full | full | reduced | reduced | none | none | full |
| `aura.embers` | Embers | 3 | low | full | full | full | reduced | none | none | full |
| `aura.flashes` | Flashes | 3 | low | full | full | reduced | reduced | none | none | full |
| `aura.lens` | Lightning lens | 3 | medium | full | full | reduced | reduced | none | none | full |
| `aura.motes` | Motes | 3 | low | full | full | full | reduced | none | none | full |
| `aura.rings` | Event rings | 3 | low | full | full | reduced | reduced | none | none | full |
| `aura.sparks` | Sparks | 3 | low | full | full | reduced | reduced | none | none | full |
| `aura.sphere` | Sphere wireframe and orbit rings | 3 | medium | full | full | reduced | reduced | none | none | full |

## Group: backdrop

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `backdrop.bokeh` | Bokeh | 4 | high | full | full | reduced | full | none | none | full |
| `backdrop.databits` | Data bits | 3 | low | full | none | none | full | none | none | full |
| `backdrop.grid` | Space-time grid | 3 | medium | full | full | none | reduced | none | none | full |
| `backdrop.haze` | Pole hazes | 3 | medium | full | full | reduced | full | none | none | full |
| `backdrop.meridians` | Meridian ellipses | 3 | trivial | full | none | none | full | none | none | full |
| `backdrop.stars` | Stars | 3 | low | full | full | full | full | none | none | full |
| `backdrop.void` | Void fill | 3 | trivial | full | full | full | full | full | none | full |
| `backdrop.wash` | Nebula wash | 3 | low | full | reduced | reduced | full | none | none | full |

## Group: body

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `body.bars` | Spectral bars | 2 | low | full | none | none | full | none | none | full |
| `body.lens` | Lens body fill | 3 | high | full | none | none | full | none | none | full |
| `body.outline` | Lens outline strands | 3 | medium | full | none | none | reduced | none | none | full |
| `insight.burst` | Insight burst | 2 | low | full | none | none | reduced | none | none | full |
| `speak.waves` | Speak waves | 2 | low | full | none | none | full | none | none | full |

## Group: core

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `eyes` | Eyes | 0 | low | full | full | full | full | full | reduced | full |
| `infinity` | Infinity flow | 1 | medium | full | full | full | none | none | reduced | full |
| `portal.back` | Portal back | 0 | low | full | full | full | full | full | none | full |
| `portal.front` | Portal front | 0 | low | full | full | full | full | full | none | full |

## Group: field

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `deepfield.constellation` | Deep field constellation | 3 | low | full | none | none | full | none | none | full |
| `deepfield.streaks` | Deep field streaks | 3 | low | full | none | none | full | none | none | full |
| `field.ambient` | Ambient field | 3 | medium | full | none | none | reduced | none | none | full |
| `field.attractor` | Entropy attractor | 4 | medium | none | full | full | none | none | none | full |
| `field.entropy_shader` | Entropy shader | 4 | high | none | full | reduced | none | none | none | full |
| `filter.animation` | Animation filter | 3 | trivial | none | full | full | none | none | none | full |

## Group: glass

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `glass.badges` | Glass button badges | 2 | low | none | none | none | full | full | none | full |
| `glass.caption` | Glass caption | 2 | low | none | none | none | full | full | none | full |
| `glass.clock` | Glass clock | 2 | low | none | none | none | full | full | none | full |
| `glass.reflections` | Glass reflections | 4 | low | none | none | none | full | none | none | full |
| `glass.sheen` | Glass sheen | 4 | low | none | none | none | full | none | none | full |
| `glass.status` | Glass status icons | 2 | low | none | none | none | full | full | none | full |
| `glass.vignette` | Glass vignette | 4 | low | full | none | none | full | none | none | full |

## Group: glow

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `glow.halo` | Portal and eye halos | 4 | medium | full | full | reduced | full | none | none | full |
| `glow.soft` | Soft glow pass | 4 | high | full | none | none | reduced | none | none | full |

## Group: listening

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `mic.bloom` | Mic bloom | 3 | medium | full | none | none | full | none | none | full |
| `strands.absorb` | Absorption sparks | 2 | low | full | none | none | full | full | none | full |
| `strands.mic` | Mic strands | 2 | high | full | none | none | full | full | none | full |
| `strands.mouth_bloom` | Portal mouth bloom | 2 | medium | full | none | none | full | none | none | full |

## Group: mesh

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `mesh.edges` | Mesh edges | 1 | high | full | full | reduced | full | full | none | full |
| `mesh.nodes` | Mesh nodes | 1 | medium | full | full | reduced | full | full | none | full |
| `mesh.orbit_handoff` | Mesh to Orbit hand-off | 1 | low | none | none | none | full | full | none | full |
| `mesh.signals` | Mesh signals | 1 | medium | full | full | reduced | full | full | none | full |
| `mesh.touch_dent` | Mesh touch dent | 1 | low | full | none | none | full | full | none | full |

## Group: overlay

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `boot` | Boot | 1 | low | full | full | full | full | full | reduced | full |
| `orbit` | Orbit drawer | 1 | medium | none | none | none | full | full | none | full |
| `ui.slide` | UI slide | 2 | low | none | none | none | none | full | none | none |

## Group: ring

| Effect id | Label | Priority | Cost tier | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ring` | Colour ring | 1 | low | full | reduced | full | full | full | none | full |
| `ring.drain_arc` | Ring drain arc | 2 | low | none | none | none | full | full | none | full |
| `ring.tint` | Ring tint and dim | 2 | trivial | full | none | none | full | full | none | full |

## Moves

| Move | Duration (s) | web | web3d | ball | pocket_web | pocket_hw | terminal | studio |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `turn` | 1.4 | full | full | full | full | full | reduced | full |
| `portal_swap` | 1.45 | full | full | full | full | full | reduced | full |
| `blink` | 0.16 | full | full | full | full | full | none | full |
| `withdraw` | 1.45 | full | full | full | full | full | none | full |
