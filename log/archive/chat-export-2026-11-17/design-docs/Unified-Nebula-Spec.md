# Unified Nebula: one entity across the Ball, web NeBuLA, Pocket, and the sCoRE TUI

Status: draft, 2026-11-09. Built from a read of RaBbLE-Grimoire, RaBbLE-NeBuLA, RaBbLE-sCoRE, RaBbLE-Pocket (all `new-horizons`), RaBbLE-Xperimental (Ball page), and the project's Entity Rig spec. This is an inventory plus a proposal, not a decision record.

Not read in full: `ui/face.py` (Python TUI predecessor), `face.rs` and `scene.c` implementation bodies (only their tables and headers), the Rust UI plan docs, and the Ethos/Personality doc beyond headings. Treat the inventory as complete for expression names, not for every behavior.

---

## 1. Surfaces today

| Surface | Renderer | Expression model |
|---|---|---|
| Web NeBuLA | Canvas2D `alive-backend.js` (2D, optional 3D) | three layers: Aether state `idle / listening / speaking`, mood `idle / ponder / process / insight / curious`, emotion `calm / joy / sad / angry` |
| Ball (Xperimental drop) | Three.js r128, real 3D portals and mesh | blink/recede only, no state API, everything in one closure |
| Pocket | `nebula_lite` C band renderer, 466 x 466, display list of ellipse / capsule / sprite / arc | `NL_STATE_{IDLE, LISTEN, THINK, SPEAK, ERROR, OFF}`, face rows `F_CALM, F_JOY, F_SAD, F_LISTEN, F_SPEAK, F_PONDER, F_PROCESS` blended by eased weights, plus continuous inputs |
| sCoRE TUI | Rust `rabble-face`, terminal cells (octant glyphs, supersampled) | `Expr {Calm, Joy, Sad, Angry, Listening, Speaking}`, `Mood {Idle, Typing, Streaming, Working, Error, Denied}` mapped to (Expr, saccade speed), `Detail {Full, Mini, Node, Tip}`, provider tint, noise and breaking degrade, 10 x 3 micro mark |
| Entity Rig sketch 08 | Three.js body rig (project doc) | face states `idle / listen / speak / alert / recede / manual`, body states `idle / listen / gesture / wave / alert / rest / manual` |

Pocket continuous inputs: `happy, dizzy, focus, flip, touch, sway, level, activity[2], mic_deg[2], ring_*`, plus device-owned boot and off fades.

## 2. Union of expressions

| Expression | Web | Pocket | TUI | Rig 08 |
|---|---|---|---|---|
| calm | emotion | F_CALM | Expr::Calm (Mood idle, working) | idle |
| joy | emotion | F_JOY, `happy` input, hop | Expr::Joy (no Mood reaches it) | |
| sad | emotion | F_SAD | Expr::Sad (Mood error) | |
| angry | emotion | none | Expr::Angry (Mood denied, 2 s then idle) | |
| listening | Aether state, portals flip | F_LISTEN, NL_STATE_LISTEN | Expr::Listening (Mood typing) | listen |
| speaking | Aether state, portal spread 1.35 | F_SPEAK, NL_STATE_SPEAK | Expr::Speaking (Mood streaming) | speak |
| ponder | mood | F_PONDER | none | |
| process / thinking | mood (legacy "thinking") | F_PROCESS, NL_STATE_THINK | none (Mood working = Calm at 2.5x saccades) | |
| insight | mood | none | none | |
| curious (pointer, touch) | mood | `touch` glance and mesh dent | `set_gaze` external target | look gizmo |
| alert | | | | face + body |
| recede / blink | blink | blink | blink | recede (canon: the only way to hide an eye) |
| error | | NL_STATE_ERROR | Mood error -> Sad | |
| dizzy, focus, flip | | continuous inputs | | |
| typing, streaming, working | | | moods | |
| off / boot | boot sequence | device-owned fades | | |

## 3. Drift to reconcile

1. **Listening disagrees.** Rust `Listening` moves the portals by +/-252 (a full end swap, like the web "flip"). Pocket `F_LISTEN` moves them +/-40 with scale 1.1 and has a separate `flip` input. The visual spec says portals flip while listening.
2. **Joy and Sad poses match numerically** between `face.rs` and `scene.c`, so they likely share a coordinate space. Pocket rows carry extra channels (`tilt, dim, squint, hop`) the Rust `Pose` lacks. Angry exists on web and TUI only.
3. **Names.** Web "thinking" vs mood "process"; Pocket THINK vs F_PONDER / F_PROCESS; TUI has Working as speed, not as a pose.
4. **Palette.** At least four cyan/magenta pairs: Pocket and Ball renderer poles `#00f5ff / #ff2d78`; Ball CSS and point lights `#5cc8ec / #ea4f9b`; Rig 08 `#4fe3f0 / #ec4c96` (marked placeholder); TUI reads `rabble_theme::Palette`. The canonical Aether magenta is still an open item in the rig spec.
5. **Seeds.** Ball's mesh uses an LCG seeded 1206; the TUI uses SplitMix64 with its own seeds. I did not check Pocket's. A given entity will not show the same constellation on two surfaces.
6. **Brand entity is native by rule.** The Pocket Entity Format says the brand entity stays native (`scene.c`) and must not be published in `rbl-entity/1`. Any unification has to respect that.

## 4. Proposal

Principle: unify the data and the contracts first, keep each surface's native scene builder, and only then decide whether to share renderer code.

### Layers
- **L0 Genome:** seed, pole pair, mesh seed. Same genome gives the same mesh layout on every surface.
- **L1 Registry** (one file in the Grimoire, which already owns the part-type registry): parts (eye L/R, portal L/R), channels (`dx dy rot sx sy` plus `tilt dim squint hop`), expressions (pose plus optional tracks), a state map from Aether state x mood x emotion x events to weights, drivers (blink, saccade, gaze, level, touch), and the canon rules (no pupils, opposed poles, recede-only hiding, legal and unstable 4-bit interior states).
- **L2 Dynamics:** weights ease with a time constant and blend normalized by total weight, as Format section 3.5 already specifies and `scene.c` implements. Rust `blend_pose` and Pocket both do linear blends today, so this is mostly naming.
- **L3 Scene builders** stay per surface.
- **L4 Backends** declare which tiers they draw: core (eyes, portals), aura (mesh, orbit rings, embers, mic strands), environment (haze, grid, infinity mirror).

### Degrade ladder
Ball (WebGL, full) -> web Canvas2D -> Pocket nebula_lite (core, mesh, strands, ring) -> TUI Full -> TUI Mini / Node -> 10 x 3 micro mark. The TUI's `Detail` and noise/break degrade already behave like the lower rungs.

### Decision (Mark, 2026-11-09): shared data model, native renderers
One shared data model (registry, interior state, genome, palette); each surface keeps its own native renderer. Generate the per-surface tables from the registry and prove parity with cross-surface golden tests (`rabble-face` already has goldens against the Python face). Every emotion and expression in the registry must be renderable on every surface.

Considered and not chosen: compiling `nebula_lite` to WASM and a Rust FFI so all surfaces draw the same pixels. It remains an option later if parity tests show drift that data alone can't fix.

### Growth plugs in here
The Entity Format already has a `persona` part (0x0007) and supports up to 32 expressions and 128 tracks. Temperament scales pose gains, blink period, `Life.speed`, and mesh activity; learned gestures are new expressions with tracks; the validator clamps drift. The persona record described earlier compiles into registry deltas, not into per-surface code.

## 5. Plan

- **P0:** registry file and schema in the Grimoire; generator for `face.rs` poses, `scene.c` face rows, and web style tables; resolve section 3 items; golden tests across surfaces.
- **P1:** expose the Ball's rig (`window.rabbleRig`: state, targets, snapshot) and have it read the registry.
- **P2:** conformance: every registry expression renders on every surface (ponder, process, insight, curious to the TUI; angry to Pocket; insight and curious to Pocket) and the TUI mood map is extended.
- **P3:** interior state channel (section 7) in the registry, with the recede-swap-emerge transition on each surface.
- **P4:** persona evolution writes registry deltas through the validator.

## 6. Open questions

1. Canonical Listening: with the interior-state reading in section 7, the portal flip is the Mirror state (a stable interior form), so Listening may reduce to the spread pose (+/-40) plus the flip bit. Needs your call.
2. Resolved: all emotions and expressions render on all surfaces.
3. Which cyan/magenta pair is canonical (Aether palette)?
4. Resolved: shared data model, native renderers.
5. Does the registry live beside the part-type registry in the Grimoire's Pocket Entity Format doc, or as its own file?
6. What causes interior state shifts (section 7)? Which axis does each pair track, and where does Joy live?

## 7. Interior state (matrix builder) and what could shift it

Source: `RaBbLE-Xperimental/Xperimental-Web/drops/20261106-rabble-matrix-builder/index.html`. The builder only authors cells. I found nothing in the files I read that drives a live entity from it, so the causes below are a proposal.

### What the builder defines
Four bits, digits read EL ER PL PR: eye colors (0 cyan, 1 magenta) and portal heights (0 bottom, 1 top). A pair is balanced when its two digits differ. That gives 4 stable forms and 12 unstable ones:
- **Stable:** Rest (cyan left, magenta right, left portal on top), Swap (eye colors exchanged), Mirror (portals exchanged), Swap-Mirror (both). Labels in the builder are EL then PL: 01, 11, 00, 10.
- **Unstable, one pair out of balance:** 8 states.
- **Unstable, both pairs out of balance:** 4 states. Your working names: 0000 cold, very sad; 1111 angry, alarmed; 0011 and 1100 "odd".
- Eye position (sliding, receding) is render-only and not part of the word. A snap function relaxes any word to its nearest stable form by keeping the left slot of each pair.

### The two flips already exist elsewhere
- Eyes flip = pole swap: rig parameter `entity.poleSwap`, Rig 08 `swapPoles()`.
- Portals flip = Mirror: rig parameter `portal.flip` (the visual spec says portals flip while listening), and Pocket's `flip` input, which is 1 in Capture and makes the eyes withdraw halfway while the portals swap ends.

### Proposed causes
1. **Stable-to-stable shifts are discrete events tied to modes.** Portals flip on listen or capture (already true on web and Pocket). What the eye flip means is undecided: candidates are an identity or provider handoff, or a polarity change in attention.
2. **Unstable states are collapsed opposition.** Read each pair as an energy budget: balanced means one high, one low (sum 1). Both low is a deficit (sum 0), both high an excess (sum 2). Then the eyes pair tracks temperature (cold cyan to hot magenta) and the portals pair tracks openness (bottom to top). Your two named states fit: 0000 is cold and low, 1111 is hot and high. The odd ones would be 0011 (cold and high, fear or dread?) and 1100 (hot and low, smolder or warmth?). These last two names are guesses.
3. **Triggers:** accumulators for temperature and arousal fed by the existing inputs (`energy`, audio level, shock and lightning events, `dizzy`, error and denied moods). Past a threshold a pair collapses; with hysteresis and a dwell time it relaxes back to its prior stable orientation. The side-specific events in the visual spec (a lightning strike makes that side's eye flinch) map to flipping a single slot, like the builder's long swipe.
4. **Emotions stay a continuous pose layer** (the `dx dy rot sx sy` offsets) on top of the discrete interior word. Only extreme intensity pushes the word into an unstable state.

### How a shift renders without breaking canon
Hiding is only allowed by receding, so every flip uses recede, swap, emerge: the affected eye or eyes slide into their portal, the bit flips while hidden, and they come back out. Pocket already does this for the portal flip. The eye-color flip needs the same treatment on each surface.

### Persona link
Temperament sets the baselines and thresholds, so one entity collapses easily and another rarely. Growth can widen how far an entity lets itself go, within validator limits.

## Sources (in repos)

- `RaBbLE-sCoRE/tui/rabble-face/src/{face,driver,micro,degrade}.rs`
- `RaBbLE-Pocket/firmware/entities/RaBbLE/{nebula_lite/include/nebula_lite.h, nebula_lite/include/nl_list.h, src/scene.c, src/entity_face.h, src/rabble_entity.h}`
- `RaBbLE-NeBuLA/{specs/visual-spec.md, specs/rig/entity-rig.json, src/backends/alive-backend.js}`
- `RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md`, `log/plans/NeBuLA-Pocket-Puppet-Rendering-Pipeline.md`
- `RaBbLE-Xperimental/Xperimental-Web/drops/20261020-rabble-ball/index.html`
- Project doc `claude/RaBbLE-Entity-Rig-Spec.md`
