# RaBbLE-Pocket: Entity Format (`.rbl` / `.rble`), spec E0

```
spark ~ pocket/entity-format >> one container, four primitives, fixed tables, no code on device // %S288_E0%
```

> **Document type:** Grimoire spec · `RaBbLE-Pocket/` · track **E0** of the release plan
> **Status:** v0.2 (2026-10-28, S288-pocket-open-sdk). Opus-reviewed once (4 blockers and 14 should-fix folded in, see Revision History); not yet re-reviewed. Numbers marked *(provisional)* become normative after the E1 device gate measures them. Open product name pending (B-24); this spec says "Open" for the neutral build.
> **Purpose:** The normative format for entities that are transplanted onto a Pocket: the `.rbl` container and its part registry, the host authoring JSON, the on-device flat binary, hard limits, the persona part, the Entity-transplant protocol and the conformance suite that the C parser, the host validator and the companion's JS/WASM interpreter must all pass.
> **Sources:** `log/plans/Pocket-Release-Entities-Companion-Plan.md` v0.3 (§2.1 to §2.5, the authority; Mark's S286 and S288 decisions and the Opus review), `RaBbLE-Pocket-Beam-Protocol.md`, `RaBbLE-Pocket-Entity-Port-Plan.md` (cycle and fps budgets), `log/BLOCKERS.md` (B-22). Code read at Pocket HEAD on 2026-10-28: `firmware/sdk/rabble_render/include/nl_list.h`, `firmware/sdk/rabble_render/include/nebula_lite.h`, `firmware/sdk/rabble_render/src/store.c`, `firmware/sdk/rabble_render/src/raster.c`, `firmware/sdk/rabble_render/src/luts.c`, `firmware/app/RaBbLE/nl_scene.h`, `firmware/app/RaBbLE/scene.c`, `firmware/sdk/rabble_store/rabble_notes.c`, `firmware/sdk/rabble_render/src/compose.c`, `firmware/sdk/rabble_render/src/orbit.c`, `firmware/sdkconfig.defaults`; storage follows the S286 notes-store decision (plan §2.4c), not a dedicated partition; `RaBbLE-sCoRE/server/beam.py`.

The key words MUST, MUST NOT, SHOULD, SHOULD NOT and MAY are used as in RFC 2119. "Validator" means the host validator; "device" means the C parser and interpreter on the Pocket (track E1/E1b). Both are expected to share one C implementation of the checks in §2 to §6 (also compiled to WASM for the companion, the same C and not a JS port), so that "the same fixtures pass" is true by construction.

---

## 1. Scope and principles

- An entity is **data, never code**. Nothing in a file is executed, interpreted as a script or used as a format string.
- An entity uses **only the renderer's four real primitives** (§3). Anything the raster kernels cannot draw is not expressible.
- The device **never trusts** a file. Robustness comes from the parser (§2 to §6), not from signatures (plan §2.3).
- The **brand entity stays native** (`scene.c`) and is not expressed in this format (§9).
- **Internal-heap delta 0.** Loading and running an entity MUST NOT increase steady-state internal RAM use (12.3 KB free, B-22). All entity storage is PSRAM (`NL_EXT_BSS`).

## 2. Container

### 2.1 File types

| Extension | Meaning | Rule |
|---|---|---|
| `.rbl` | General RaBbLE container used across the Collective. May hold any registered parts. | Transplantable if it holds `manifest`, `palette` and `entity` parts. |
| `.rble` | Entity-only file: a `.rbl` whose header flag `ENTITY_ONLY` is set. | MUST contain only parts in the entity family (`0x0001` to `0x00EF`) plus an optional `signature`. |

The extension is a hint. Readers MUST decide by the header, not the extension. A file with `ENTITY_ONLY` holding a non-entity part is rejected (`E_NOT_ENTITY`). A `.rble` name without `ENTITY_ONLY` is a host-side check only (the device never sees an extension).

### 2.2 Byte conventions

- All integers little-endian. No floating-point fields anywhere in the binary (§4.1), so NaN and Inf cannot be stored.
- The header and part table are packed exactly as below; every part starts at a 4-byte aligned offset; padding bytes are zero.
- CRC-32 is the IEEE 802.3 / zlib CRC (reflected polynomial `0xEDB88320`, init `0xFFFFFFFF`, final XOR `0xFFFFFFFF`; `crc32("123456789") = 0xCBF43926`). Implementations using `esp_rom_crc32_le` (presumably as `esp_rom_crc32_le(0, p, n)`; the exact call is confirmed on device against this check value in E1b) MUST match it.
- **Reserved fields, undefined flag bits and padding bytes MUST be written as zero, and v1 readers MUST reject non-zero values** (`E_RESERVED`, including non-zero padding). New meaning comes with a new version number, never by reusing a reserved field silently.

### 2.3 Header (32 bytes, offset 0)

| Off | Type | Field |
|---|---|---|
| 0 | u8[4] | magic `52 42 4C 1A` ("RBL" then 0x1A) |
| 4 | u16 | `container_version` = 1 |
| 6 | u16 | `flags`: bit 0 `ENTITY_ONLY`; bits 1 to 15 zero |
| 8 | u32 | `total_len`: whole file in bytes, a multiple of 4 |
| 12 | u16 | `part_count`: 1 to 16 |
| 14 | u16 | `header_len` = 32 |
| 16 | u32 | `table_crc32`: CRC-32 of the part table (`16 * part_count` bytes) |
| 20 | u32 | `header_crc32`: CRC-32 of header bytes 0 to 19 |
| 24 | u8[8] | reserved, zero |

**Check order (every reader, in this order):** length at least 32, then magic, `container_version`, `header_crc32`, `header_len` == 32, `part_count` 1 to 16, `total_len` (equals the bytes received, at most 65,536, multiple of 4), `32 + 16 * part_count <= total_len`, `table_crc32`, then the table entries (bounds computed as `offset <= total_len && length <= total_len - offset`, never `offset + length`), then each part. No field is used before the check that covers it.

### 2.4 Part table (16 bytes per entry, from offset 32)

| Off | Type | Field |
|---|---|---|
| 0 | u16 | `type` (registry §2.6) |
| 2 | u8 | `version` of that part's layout (1 for every part in this spec) |
| 3 | u8 | `flags`: bit 0 `CRITICAL`; bits 1 to 7 zero |
| 4 | u32 | `offset` from file start: multiple of 4, at least `32 + 16 * part_count` |
| 8 | u32 | `length` in bytes, padding excluded |
| 12 | u32 | `crc32` of the part's `length` bytes |

Rules (violations are `E_PART_BOUNDS` unless noted):
1. Entries are in strictly ascending `offset`; parts do not overlap; `offset + length <= total_len`.
2. The gap between the table end and the first part, and between parts, is zero padding of fewer than 4 bytes; `total_len` is the last part's end rounded up to 4. Nothing else is allowed in the file.
3. A `type` appears at most once (`E_DUPLICATE_PART`).
4. **Skip by length:** an unknown `type` without `CRITICAL` is skipped after its CRC is checked. An unknown `type` with `CRITICAL` rejects the file (`E_UNKNOWN_CRITICAL`). A known `type` with an unknown `version` is skipped if not critical and rejects otherwise (`E_PART_VERSION`). The entity parts `manifest`, `palette` and `entity` MUST be written `CRITICAL`, and so MUST `persona` when present (a skipped persona would let the backend answer in the wrong voice, §6.3). A **known type with a layout the reader does not implement** that is `CRITICAL` rejects (`E_PART_VERSION` for a version, `E_UNKNOWN_CRITICAL` for a type this reader does not handle): the device rejects a critical `0x0100` config part, the companion processes it.
5. The device reads only the entity family and `persona`; it CRC-checks and skips everything else.

### 2.5 Signature part (optional)

Type `0x00F0`, version 1, never `CRITICAL`, 76 bytes:

| Off | Type | Field |
|---|---|---|
| 0 | u8 | `alg`: 1 = Ed25519 |
| 1 | u8[3] | reserved |
| 4 | u8[8] | `key_id`: first 8 bytes of SHA-256 of the 32-byte public key |
| 12 | u8[64] | signature |

Signed message: ASCII `RBLSIG01`, then u16 header `flags`, then u16 count of signed parts, then for each non-signature part in table order: u16 `type`, u8 `version`, u8 `flags`, u32 `length`, SHA-256 of the part bytes (32). A signature identifies an author; it **does not make a file safe** and MUST NOT let any check in §7 be skipped. The device MAY ignore signatures in v1. The companion SHOULD verify when it knows the key and show the result. Release images and their manifests are signed separately (plan §2.3, Ed25519/minisign); whether that manifest is a `.rbl` is open (Q1).

### 2.6 Part-type registry (owned here, in the Grimoire)

This table is the single registry for the whole Collective. Adding a type is a revision of this document; no member assigns types locally.

| Type | Name | Family | Device reads | Required for transplant |
|---|---|---|---|---|
| `0x0000` | invalid | | | never valid |
| `0x0001` | `manifest` | entity | yes | yes |
| `0x0002` | `palette` | entity | yes | yes |
| `0x0003` | `entity` (primitives, clips, sprites) | entity | yes | yes |
| `0x0004` | `rig` | entity | yes | no (static entity) |
| `0x0005` | `expressions` | entity | yes | yes if `state-map` present |
| `0x0006` | `state-map` | entity | yes | no (expression 0 always) |
| `0x0007` | `persona` | entity | yes | no (`CRITICAL` when present) |
| `0x0008` to `0x00EF` | reserved: future entity parts | entity | skip | |
| `0x00F0` | `signature` | control | optional | no |
| `0x00F1` to `0x00FF` | reserved: container control | control | skip | |
| `0x0100` to `0x01FF` | reserved: Collective config (themes, settings, notes) | config | skip | |
| `0x0200` to `0x02FF` | reserved: release-image manifests (Q1) | release | skip | |
| `0x0300` to `0x7EFF` | unassigned (assigned by revision of this table) | | skip | |
| `0x7F00` to `0x7FFF` | private / experimental: MUST NOT appear in a shared or transplanted file; validator warns, device skips | | skip | |
| `0x8000` to `0xFFFF` | reserved | | skip | |

## 3. Entity model

### 3.1 Coordinates and units

- Origin is the **panel centre**; `+x` right, `+y` down (screen convention, as `nl_ellipse_t`).
- Unit **R** = panel radius = `NL_W / 2` = 233 px on both the 1.75B and the 1.75C (the 466 px panel claim comes from the plan; `nebula_lite.h:16-17` has a single `NL_W`). Normalised coordinates remove only the entity's share of the 466 px assumption; the renderer, Orbit and panel stay 466 px (plan §2.2).
- **All angles are clockwise from `+x`**, in the file and in JSON. The device converts for arcs, whose setup measures clockwise from 12 o'clock (`raster.c:457`: arc angle = file angle + π/2).
- The device applies the entity's roll and the UI/Orbit slide on top, exactly as `scene.c` does through `tx()` (`scene.c:57-62`); the entity cannot opt out.

### 3.2 The four primitives (and nothing else)

| Kind (`= NL_P_*`, `nl_list.h:83`) | What the renderer actually does | Format fields |
|---|---|---|
| 0 **ellipse** | Centre, semi-axes `a`, `b`, rotation (ignored when `a == b`, `scene.c:85`). Fill with alpha (`fill_a` 0 = hollow), stroke centred on the edge with width `sw`. `arc` 1 or 2 draws the **stroke only** on local `y >= 0` or `y <= 0` (half-arc; fill unaffected, `raster.c:113`). Optional **gradient** slot 0 or 1 replaces the fill colour by normalised radius² from a 16-entry LUT (`nl_list.h:133-134`, `raster.c:106-108` for the edge and `218-234` for the interior). Optional **clip** slot 0 or 1 limits the **fill only**: a pixel stays if it is on the kept side of a line **or** inside the clip ellipse (`nl_list.h:127-131`, `raster.c:99-103`). Dropped when `a` or `b` < 0.3 px (`scene.c:81`). **Small-circle fast path:** `a == b`, no gradient, no clip and `a < 20` px goes to `draw_circle`, which ignores `arc` (`raster.c:170`). So in v1 a primitive with `arc != 0` MUST have `a != b` (`E_RANGE`); E1 adds `&& e->arc == 0` to that condition (brand sim output is unchanged) and this restriction is then lifted. | `x y a b rot sw`, `fill_slot fill_a stroke_slot stroke_a arc grad clip` |
| 1 **capsule** | Segment A to B with half width `r`, round ends, one colour and alpha (`nl_line_setup`, `nl_list.h:95-106`). | `ax ay bx by r`, colour slot, alpha |
| 2 **sprite** | A8 coverage bitmap drawn in one colour (`nebula_lite.h:31-42`). It turns only with the entity's roll; quarter turns copy exactly, other angles sample bilinearly (`raster.c:329-345`). **No own rotation, no scale.** | `x y`, sprite index, colour slot, alpha |
| 3 **arc** | Annular sector: centre, mid radius `r`, half width `hw`, start and span; full ring, more-than-half-turn union, optional round caps; one colour and alpha (`nl_list.h:108-119`, `raster.c:447-460`). The kernel walks the whole annulus on every row and rejects pixels by angle (`raster.c:478-534`), so cost does not shrink with the span (§5.3). `nl_arc_setup` takes the **full** width: pass `2*hw`. | `x y r hw start span`, colour slot, alpha, `ROUND` flag |

Not expressible: polygons, rounded rectangles, general or linear gradients, blur, paths, path morph, per-vertex colour. **"Morph" means interpolating the parameters of ellipses, capsules and arcs** through the rig (§3.4). A new primitive needs a new raster kernel and a new `entity` part version.

### 3.3 Palette

Up to 16 named colour slots (`0xRRGGBB`), referenced by index. Up to 2 radial gradients, each 2 to 4 stops of (normalised radius 0..1, slot). **The compiler bakes each gradient and stores the 16 RGB565 entries in the palette part (32 bytes per gradient); the device copies them into `nl_grad[g][16]` and never computes them.** The reference bake the compiler uses is: for `i` in 0..15, `q = i / 15`, `r = sqrt(q)` (the convention of `scene.c:591`, since the raster indexes by radius², `raster.c:104`); find the stop pair `p0 <= r <= p1`; `t = (r - p0) / (p1 - p0)`; colour = `nl_hex565(nl_mix_hex(c0, c1, t))` with the integer mixing of `luts.c:23-31` (t quantised to 1/256). The float32 `sqrtf`, the divide and `(int)(t*256)` differ between C and JS doubles at bin edges, which is why the table is stored and not recomputed (a bit-for-bit port is not required). The validator checks only that the stored entries are any u16; they are author data.

The gradient and clip slots are renderer globals (`store.c:14-15`). While a transplanted entity is active it owns both; the brand scene is not running. Their contents are **not** part of the damage hash today (§3.6, R1).

### 3.4 Rig

- **Parameters:** named scalars in a declared `[min, max]` within `[-1, 1]` with a default. Built-in ids: 0 `gaze_x`, 1 `gaze_y`, 2 `blink`, 3 `mouth_open`, 4 `ear_l`, 5 `ear_r`, 6 `tail`; ids 7 to 15 reserved for future built-ins; **user-defined** parameters get ids 16 to 47 (names live in JSON only); at most 7 + 32 = 39 parameters.
- **Drivers** feed a parameter from a device input (§4.5): audio level, touch offset, sway, a blink clock, a wander noise, per-core activity, focus. This is how the brand's procedural behaviour (blink every 4.2 s, glance to a thumb, mouth with the level: `scene.c:574-581`, `scene.c:669`) is expressed as data.
- **Bindings** map a parameter linearly onto one target of one primitive: `target += gain * p`. Targets: translate, rotate, uniform scale `s`, own scale `sx`/`sy`, opacity, and the shape fields (`a`, `b`, `sw`, capsule end, arc start/span).
- **Hierarchy:** a primitive MAY name a `parent` with a **smaller index**. A child inherits the parent's translation, rotation (about the parent's centre) and uniform scale `s`, and multiplies the parent's opacity. Non-uniform `sx`/`sy` apply to the primitive itself only (a non-uniformly scaled rotated ellipse would not be an ellipse the kernel can draw). Because parents always precede children, cycles are impossible by construction; depth is capped at 8.

### 3.5 Expressions and the state map

The model is `scene.c`'s face blending (`scene.c:121-143`, `611-624`), generalised:

- An **expression** is a **pose** (a set of parameter offsets, the analogue of a `face_t` row such as `F_JOY`, `scene.c:126`) plus optional **keyframe tracks** (parameter offsets over time with per-key easing; looping or one-shot).
- The **state map** turns the device state and events into a target weight per expression: the mapped state's expression gets 1; then for each mapped event in id order with strength `s` (0..1), every target is multiplied by `1 - s` and the event's expression gains `s` (exactly `scene.c:620-622` for `happy`).
- Weights ease toward targets each frame: `w += (tgt - w) * (1 - exp(-dt / tau))`, `tau = blend_tau_ms` (default 250 ms as `scene.c:623`), `dt` clamped to 1..100 ms (`scene.c:600`).
- Each parameter: `p = clamp(default + sum_i (w_i / W) * (pose_i[p] + track_i[p](t_i)) + sum(drivers), min, max)`, where `W = sum w_i` (1 if `W < 0.001`, as `scene.c:666-667`) and `t_i` is time since expression `i`'s weight last rose from 0 (wrapped by `duration` when looping, held at the end otherwise).
- Expression 0 is the **rest** expression and the fallback for every unmapped state.
- **Device-owned, not mappable:** the boot fade-in and OFF fade-out (applied as a global opacity, `scene.c:627-631`), the ring, the UI/Orbit slide and the roll. An entity cannot stay lit while the device is off.

### 3.6 Scene-builder contract and renderer prerequisites

Replacing `nl_simulate` means doing everything `scene.c:597-814` does besides the face. The interpreter (`ent_scene_simulate`) MUST, in the order `scene.c` uses: set `nl_roll`, `nl_spr_c` and `nl_spr_s`; set `nl_n_prims = 0`; set `nl_ring_opa` and `nl_ring_tint`; run `nl_ui_frame`, `nl_orbit_begin` and `nl_ring_arc_frame`; apply the `s_cap` rule and the `nl_ui_full` early-out; run `nl_soft_bake`; push badges and glass; run `nl_orbit_build` and `nl_list_bin`; and set `nl_mesh_n = 0` (`orbit.c` already tolerates it, `orbit.c:210-213`). `nl_clip[]` and `nl_grad[][]` are written once per load or per frame as the entity needs.

**Hashing:** `band_hashes` hashes `sizeof(nl_ellipse_t)` including padding bytes (`compose.c:350`), so the interpreter MUST `memset` each primitive to zero before filling it, or bands churn every frame.

**Sprites:** entity sprites live in the 16 glass slots `nl_spr[0..15]`, because the Orbit starts its own at slot 16 (`orbit.c:150`) and `scene.c:795-799` refills the glass slots every frame (opacity times `rest`, slide for `upright == 1`). The interpreter applies the same rest and slide treatment. Priority proposal: **glass first** (a slot the glass needs this frame is not available to the entity, and that entity sprite is skipped). Sprites are **optional per profile**: the Open profile (plan §2.4c) has none.

**Renderer prerequisites (E1 changes the renderer, a few lines each):**

| # | Change | Why |
|---|---|---|
| R1 | Mix `nl_clip[0..1]` and a gradient generation counter into `base` in `band_hashes` (`compose.c:327-365`). | The damage hash covers each primitive's struct, including the `clip` and `grad` index bytes, but never the slots' contents. In the brand this is safe (the clip follows the portal, `scene.c:766`, and the front rim ellipse sits in the same bands). In this format a clip has its own `parent` (§4.3), so a clip can move while the clipped ellipse stays still, and a gradient re-bake on activation or hot-swap changes colours with no primitive change; the bands would keep old pixels. Until R1 lands the validator forbids a clip whose parent is not the clipped ellipse's own subtree root (`E_PARENT`). |
| R2 | Add `&& e->arc == 0` to the small-circle fast path (`raster.c:170`). | §3.2. |
| R3 | Clamp the evaluated arc span to [0, 2π] before `nl_arc_setup`; an evaluated 0 means "not drawn". | `nl_arc_setup` (`raster.c:454-459`) treats span >= 2π - 1e-3 as FULL and gives a negative span nonsense edges. The stored field's "0 = full ring" (§4.1) applies to storage only. |

## 4. Encodings

### 4.1 Number formats (binary)

| Name | Storage | Real value | Use |
|---|---|---|---|
| `q12` | i16 | `v / 4096` R | positions, lengths (range ±7.9998 R; §5 caps far below) |
| `q14` | i16 | `v / 16384` | parameter values, opacity gains (range ±1.99994) |
| `q8` | i16 | `v / 256` | scale gains |
| `ang` | i16 | `v * π / 32768` rad | angles, clockwise from `+x` |
| `span` | u16 | `v * 2π / 65536` rad; stored 0 = full ring (an evaluated 0 is "not drawn", §3.6 R3) | arc span |
| `u8n` | u8 | `v / 255` | alpha |
| `ms` | u16 | milliseconds | times |

The compiler converts JSON floats by round-half-away-from-zero and MUST reject (not wrap or saturate) a value that does not fit its field.

### 4.2 Host authoring JSON

JSON is host-only (validator, companion editor, compiler). It is UTF-8, RFC 8259, with no duplicate keys, no comments, and numbers that MUST be finite (`NaN`, `Infinity` and anything that parses to them, such as `1e999`, are rejected). Units: R for lengths, degrees for angles, 0..1 for alpha and parameters, `"#RRGGBB"` for colours, milliseconds for time. Names are `[a-z][a-z0-9_]{0,23}` and unique per kind; the compiler resolves every name to an index. Unknown keys are rejected (a typo must not silently vanish).

```json
{
  "format": "rbl-entity/1",
  "manifest": { "id": "3f2a9c1e-0b7d-4e5a-9c2f-1d8e6b4a7c30", "name": "Two Eyes", "author": "Example Author",
                "licence": "author-owned", "type": "face", "min_sdk": [0, 0, 0, 1, 0] },
  "palette": { "slots": { "ink": "#FFFFFF", "void": "#000000" },
               "gradients": [ { "stops": [ [0.0, "ink"], [1.0, "void"] ] } ] },
  "rig": {
    "params": { "blink": {}, "gaze_x": {}, "perk": { "min": 0, "max": 1, "default": 0 } },
    "drivers": [ { "param": "blink", "source": "blink_clock", "gain": 1, "period_ms": 4200 },
                 { "param": "gaze_x", "source": "touch_x", "gain": 0.5 } ],
    "bindings": [ { "param": "blink", "part": "eye_l", "target": "sy", "gain": -0.95 },
                  { "param": "blink", "part": "eye_r", "target": "sy", "gain": -0.95 },
                  { "param": "gaze_x", "part": "eyes", "target": "dx", "gain": 0.04 } ]
  },
  "parts": [
    { "name": "eyes", "kind": "ellipse", "x": 0, "y": 0, "a": 0.0, "b": 0.0, "fill": null },
    { "name": "eye_l", "parent": "eyes", "kind": "ellipse", "x": -0.2, "y": 0, "a": 0.1, "b": 0.1, "fill": "ink", "fill_a": 1, "gradient": 0 },
    { "name": "eye_r", "parent": "eyes", "kind": "ellipse", "x": 0.2, "y": 0, "a": 0.1, "b": 0.1, "fill": "ink", "fill_a": 1, "gradient": 0 }
  ],
  "expressions": [
    { "name": "rest" },
    { "name": "joy", "pose": { "perk": 1 },
      "tracks": [ { "param": "gaze_x", "loop": true, "duration_ms": 1600,
                    "keys": [ [0, 0, "smooth"], [800, 0.3, "smooth"], [1600, 0, "step"] ] } ] }
  ],
  "state_map": { "states": { "idle": "rest" }, "events": { "happy": "joy" } },
  "persona": "A calm, curious companion that speaks briefly."
}
```

(An empty grouping ellipse such as `eyes` with `a = b = 0` is a pure transform node: it is never pushed. The colours above are placeholders only; real entities take their colours from their author, and the Open Entity's palette is not the Aether palette, plan §2.1.)

### 4.3 On-device binary: part layouts (all version 1)

Every part's `length` MUST equal the size its own counts imply (`E_COUNT`). The device loads the live entity into one **static `NL_EXT_BSS` buffer of 65,536 bytes**, declared `__attribute__((aligned(4)))` (a plain `uint8_t[]` has alignment 1 and the LX7 faults on unaligned 32-bit loads), in PSRAM (no `malloc`, so `SPIRAM_MALLOC_ALWAYSINTERNAL=4096`, `sdkconfig.defaults:26`, cannot route anything to internal RAM), and reads the tables in place: no per-node allocation, no pointers stored in the file, every reference an index checked once at load. **Fields are read through little-endian accessor functions (`memcpy` into locals), never through struct overlays**, so the C and WASM builds are identical and strict aliasing is not an issue. **The live buffer is immutable after load** (no time-of-check to time-of-use gap). Validating an incoming file (§7.3) uses a **second** 64 KiB `NL_EXT_BSS` buffer, PSRAM only, so internal heap stays at delta 0 and the running entity keeps drawing while the next one is checked; the alternative is to validate only at boot (reboot to activate, Q7).

**`manifest` (0x0001):**

| Off | Type | Field |
|---|---|---|
| 0 | u8[16] | `entity_id` (UUID bytes; all zero rejected) |
| 16 | u16 | `format_version` = 1 |
| 18 | u16[5] | `min_sdk` (Five-Es: epoch, evolution, echo, episode, event) |
| 28 | u16 | flags, zero |
| 30 | u16 | reserved |
| 32 | str × 4 | `name` (1..32 bytes), `author` (0..48), `licence` (1..32), `entity_type` (1..16, `[a-z0-9-]`); each str = u8 length + UTF-8 bytes (§6.1 rules) |

**`palette` (0x0002):** u8 `n_slots` (1..16), u8 `n_grad` (0..2), u16 reserved; then `n_slots` × u32 `0x00RRGGBB` (top byte zero, else `E_RESERVED`); then `n_grad` × 44 bytes: u8 `n_stops` (2..4), u8 reserved, 4 × {u8 `pos` (0..255 = radius 0..1), u8 `slot`} (unused stops zero), u16 reserved, then 16 × u16 baked RGB565 (§3.3). Stops strictly ascending, first `pos` 0, last 255 (`E_ORDER`).

**`entity` (0x0003):** header 8 bytes: u16 `n_prims` (1..128), u8 `n_clips` (0..2), u8 `n_sprites` (0..4), u32 `blob_len` (0..16384). Then prims, clips, sprites, blob, in that order.

Prim record, 32 bytes:

| Off | Type | Field |
|---|---|---|
| 0 | u8 | `kind` 0 ellipse, 1 capsule, 2 sprite, 3 arc |
| 1 | u8 | flags: bit 0 `ROUND` (arc caps); others zero |
| 2 | u8 | `parent`: 0xFF none, else `< own index` |
| 3 | u8 | `fill_slot` (ellipse fill; the single colour of capsule, sprite, arc); 0xFF none |
| 4 | u8 | `stroke_slot` (ellipse only; else 0xFF) |
| 5 | u8 | `fill_a` (`u8n`; ellipse 0 = hollow; alpha for the other kinds) |
| 6 | u8 | `stroke_a` (ellipse only) |
| 7 | u8 | `arc`: 0 whole stroke, 1 local y >= 0, 2 local y <= 0 (ellipse only) |
| 8 | i8 | `grad`: -1, 0, 1 (ellipse only, needs `n_grad > grad`, else `E_INDEX`) |
| 9 | i8 | `clip`: -1, 0, 1 (ellipse only, needs `n_clips > clip`) |
| 10 | u16 | reserved |
| 12 | i16[10] | geometry `g0..g9` per kind (unused zero) |

| Kind | g0 | g1 | g2 | g3 | g4 | g5 |
|---|---|---|---|---|---|---|
| ellipse | x `q12` | y `q12` | a `q12` | b `q12` | rot `ang` | sw `q12` (0 = no stroke) |
| capsule | ax `q12` | ay `q12` | bx `q12` | by `q12` | r `q12` | |
| sprite | x `q12` | y `q12` | sprite index | | | |
| arc | x `q12` | y `q12` | r `q12` | hw `q12` | start `ang` | span `span` (read as u16) |

A capsule's position for hierarchy and binding is its point A; `end_dx`/`end_dy` bindings move B.

Clip record, 24 bytes: u8 `parent` (0xFF none: the clip follows that prim's world transform), u8[3] reserved, `q12` px, py (a point on the line), `ang` n (normal; keep where `n.(p - p0) >= 0`), `q12` cx, cy, a, b (the opening ellipse; a, b >= 18, i.e. about 1 px, because the kernel takes `nl_recip(a*a)`, `raster.c:175`), `ang` rot, u32 reserved. A clip's `parent` is restricted until renderer prerequisite R1 (§3.6).

Sprite record, 8 bytes: u8 `w` (1..96), u8 `h` (1..96), u8 `upright` (MUST be 1: turns with the entity), u8 reserved, u32 `offset` into the blob. Stride = `w`; the check is `offset <= blob_len && w * h <= blob_len - offset` (`E_SPRITE`; `offset + w * h` can wrap a u32, so it is never computed). Entity sprites occupy glass slots (§3.6) and are optional per profile.

**`rig` (0x0004):** header 8: u8 `n_params` (0..39), u8 `n_drivers` (0..16), u16 `n_bindings` (0..256), u32 reserved.
- param, 8 bytes: u8 `id` (0..6 or 16..47, unique), u8 reserved, `q14` default, `q14` min, `q14` max (`-16384 <= min <= default <= max <= 16384`).
- driver, 8 bytes: u8 `param` (an id declared above), u8 `source` (§4.5), `q14` gain, `ms` period (blink_clock 2000..10000, wander 1000..16000, else 0), u16 reserved.
- binding, 8 bytes: u8 `param`, u8 `prim`, u8 `target`, u8 reserved, i16 `gain`, u16 reserved. Targets and gain units: 0 `dx`, 1 `dy` (`q12`); 2 `rot` (`ang`); 3 `s`, 4 `sx`, 5 `sy` (`q8`, starting from 1); 6 `opa` (`q14`, starting from 1); 7 `a`, 8 `b`, 9 `sw` (`q12`; for capsule `a` is `r`, for arc `a` is `r` and `b` is `hw`); 10 `arc_start` (`ang`), 11 `arc_span` (`ang`, evaluated span clamped to [0, 2π], §3.6 R3); 12 `end_dx`, 13 `end_dy` (`q12`, capsule only). A target that does not apply to the prim's kind is `E_INDEX`.

**`expressions` (0x0005):** header 16: u8 `n_expr` (1..32), u8 reserved, u16 `n_pose` (0..512), u16 `n_tracks` (0..128), u16 `n_keys` (0..1024), `ms` `blend_tau_ms` (50..2000), u16[3] reserved.
- expression, 12 bytes: u16 `pose_first`, u8 `pose_n`, u8 `track_n`, u16 `track_first`, `ms` `duration` (0..16000; 0 = pose only), u8 flags (bit 0 `LOOP`), u8 reserved, u16 reserved. Ranges MUST lie within the tables (`E_INDEX`).
- pose entry, 4 bytes: u8 `param`, u8 reserved, `q14` value.
- track, 8 bytes: u8 `param`, u8 `key_n` (2..64), u16 `key_first`, u32 reserved.
- key, 8 bytes: `ms` t, `q14` value, u8 `ease` (0 step, 1 linear, 2 in-quad, 3 out-quad, 4 smoothstep `3u² - 2u³` as `scene.c:33`), u8[3] reserved. First key `t = 0`, times strictly ascending, last `t <= duration` (`E_ORDER`). A key's easing shapes the segment that starts at it.

**`state-map` (0x0006):** header 4: u8 `n` (1..32), u8[3] reserved; entries 4 bytes: u8 `kind` (0 state, 1 event), u8 `id`, u8 `expr` (< `n_expr`), u8 reserved. Each (kind, id) at most once.

| States (`NL_STATE_*`, `nebula_lite.h:29`) | Events (strength source in `nl_inputs_t`) |
|---|---|
| 0 idle, 1 listen, 2 think, 3 speak, 4 error, 5 off, 6 think_long (think held 1.5 s or more, `scene.c:615`; unmapped: uses think's) | 0 happy (`happy`), 1 dizzy (`dizzy`), 2 touch (`touch[2]`), 3 flip (`flip`, Capture), 4 focus (`focus`) |

**`persona` (0x0007):** the UTF-8 bytes, 1..1024, no terminator (§6).

### 4.4 Versioning

- `container_version` changes only if §2.3 or §2.4 change. Part layouts version independently in the table's `version` byte.
- `manifest.format_version` names the entity model generation (1 = this spec). A device that does not implement it rejects with `E_PART_VERSION`.
- `manifest.min_sdk` is compared with the firmware's Five-Es version; newer than the device is `E_SDK_VERSION`.
- JSON carries `"format": "rbl-entity/1"`. The compiler is the only producer of the binary; a binary is never hand-edited.

### 4.5 Driver sources

| Id | Source | Range fed to `gain` |
|---|---|---|
| 0 | `level` (`in->level`) | 0..1 |
| 1, 2 | `touch_x`, `touch_y`: thumb offset from the panel centre in R, times `touch[2]` | about -1..1 |
| 3, 4 | `sway_x`, `sway_y` (`in->sway`, px / R) | small, 0 at rest |
| 5 | `blink_clock`: a 160 ms sine dip every `period`, doubled every third (`scene.c:574-581`) | 0..1 |
| 6 | `wander`: loop-safe value noise with the given period | -1..1 |
| 7, 8 | `activity0`, `activity1` (`in->activity`) | 0..1 |
| 9 | `focus` (`in->focus`) | 0..1 |

## 5. Hard limits

### 5.1 Budgets they derive from

- **Frame:** 60 fps idle is met on the 1.75B with 16.7 ms per frame, roughly 4 million cycles per core for about 170,000 visible pixels, i.e. 20 to 25 cycles per visible pixel for everything (fill, ring, compose, byte swap, panel) (`RaBbLE-Pocket-Entity-Port-Plan.md`, §Phase 1 and S252 results; 240 MHz / 60 = 4.0 M cycles per core). Fps depends on **covered area and edge pixels**, not primitive count (plan §2.2).
- **Damage and panel bandwidth:** a full-frame transfer is capped near 46 fps (`RaBbLE-Pocket-Entity-Port-Plan.md:9`), so 60 fps idle depends on damage: about 18 of 30 bands change at idle (Port-Plan:278), and at 60 fps **at most about 23 of 30 bands can change per frame**. Anything that animates at rest dirties bands.
- **Display list:** `NL_MAX_PRIMS` 1400, of which the scene may use `1400 - NL_ORBIT_PRIMS (300)` = 1100 while an Orbit shows (`nebula_lite.h:150`, `nl_list.h:163`, `scene.c:633`).
- **Internal heap:** about 12.3 KB free at ready and already short for TLS (B-22). Entity data and state therefore live in PSRAM only.

### 5.2 Limits (validator MUST reject above; device MUST reject above at load)

| Item | Limit | Why |
|---|---|---|
| File (`total_len`) | 65,536 bytes | one static PSRAM buffer; the transfer cap (§7.2) |
| Parts per container | 16 | table fits one 288-byte read |
| Primitives | 128 | 1100-slot scene budget leaves room for glass sprites and badges; edge-pixel cost bounded |
| Clips / gradients | 2 / 2 | renderer slots (`nl_list.h:133-135`) |
| Sprites | 4, each ≤ 96 × 96, blob ≤ 16,384 bytes; optional per profile (none in Open) | Correction C2, §3.6 |
| Palette slots | 16 | |
| Parameters / drivers / bindings | 39 / 16 / 256 | interpreter cost under 1 ms per frame *(provisional)* |
| Expressions / pose entries / tracks / keys | 32 / 512 / 128 / 1024; keys per track 2..64 | |
| Expression duration | 16,000 ms | the brand's 16 s loop (`scene.c:20`) |
| Hierarchy depth | 8 | bounded transform walk |
| Persona | 1024 bytes UTF-8 | §6 |
| Manifest strings | name 32, author 48, licence 32, type 16 bytes | |

### 5.3 Geometry caps, checked at the worst case over the rig

The validator and device evaluate each primitive's **worst case** by interval arithmetic in **exact integer maths (int64 over the fixed-point values)**, with no floats: every parameter at whichever of `min`/`max` maximises `|value|`, every binding's `|gain|` added, inherited uniform scale multiplied down the parent chain. Caps:

| Quantity | Cap |
|---|---|
| Centre / endpoints, after bindings | `|x|, |y| <= 1.5 R` |
| Ellipse `a`, `b`; arc `r` | `<= 1.0 R` |
| Stroke `sw`; capsule `r`; arc `hw` | `<= 0.1 R` (about 23 px) |
| Capsule length | `<= 2.0 R` |
| Scale `s`, `sx`, `sy` (evaluated) | `0 .. 4` |
| Clip `a`, `b` | `>= 18` (`q12`, about 1 px) |

**Coverage budget *(provisional)*:** the sum over all primitives of their worst-case weighted area MUST be `<= 170,000 px²` (one visible disc). Area = π·a·b for an ellipse fill, `2π·max(a, b)·(sw + 2)` for its stroke, `(2r + 2)·len + π·(r + 1)²` for a capsule (the edge zone is `hw + 1` px on each side, `raster.c:171` and `253`), `4π·r·hw` for an arc **whatever its span** (the kernel walks the whole annulus, `raster.c:478-534`), `w·h` for a sprite. Weights: 1 for plain fills and arcs; **2** for gradient or clipped fills, strokes, capsules and sprites (sprites at a non-quarter roll sample bilinearly, `raster.c:392-438`; per-pixel LUT and clip tests; edge-dominated kernels). π is evaluated as the integer ratio 355/113 or a fixed-point constant, identically in every implementation. Rationale: at an assumed 10 to 12 cycles per covered pixel the entity then takes about half the frame, leaving the rest for ring, swap and band overhead. A dog head of 0.75 R radius is about 96,000 px², so a dog fits (π·233² is about 170,553 px², so the budget is one visible disc). The numbers are consistent with 60 fps idle on the CPU side; the missing constraint was panel bandwidth, now the damage rule below. E1 MUST measure (§5.5) and either confirm these numbers or revise them here.

**Idle damage rule *(provisional)*:** the validator MUST reject (`E_COVERAGE`) a file whose idle expression (tracks of the idle expression, `wander` drivers, anything that moves with the device untouched) can dirty more than 23 of the 30 sixteen-row bands, and SHOULD warn above 18. The 23 follows from the panel bandwidth above, not from the brand's band count. E1 gates 60 fps idle on the device with the Open Entity and the dog.

### 5.4 Validator rejects versus device clamps

| Case | Validator | Device at load | Device per frame |
|---|---|---|---|
| Structural (magic, CRC, bounds, counts, indices, parents, order, reserved bits) | reject | reject (same code) | n/a |
| Values out of §5.2 / §5.3 caps | reject | reject (same code); all §5.3 maths is exact integer, so host and device agree and there is **no tolerance**. This also avoids Xtensa `madd.s` contraction differences and makes C-versus-WASM differential fuzzing exact | |
| NaN / Inf in JSON | reject | impossible in the binary (fixed point) | |
| Computed value non-finite (e.g. a degenerate transform) | | | skip that primitive this frame; count a fault |
| Computed value over a cap (rounding, drivers) | | | clamp to the cap: positions to ±1.5 R, sizes to their caps, scale to 0..4, alpha to 0..255 |
| Running coverage over budget | | | skip the remaining primitives this frame (draw order = record order); count a fault |
| Ellipse axis < 0.3 px | | | not pushed (as `scene.c:81`) |

Every value handed to `nl_push`, `nl_line_setup` or `nl_arc_setup` MUST be finite and within the caps. This matters because `nl_push` bounds-checks with comparisons that NaN passes and then converts with `floorf` to `int16` (`store.c:30-34`). A counts-over-limit file is `E_COUNT`; a value-over-cap file is `E_RANGE`.

### 5.5 What E1 measures on device before the numbers freeze

- Cycles per pixel per kernel: flat interior, gradient interior, clipped interior, ellipse edge and stroke, small-circle path, capsule (steep and near-level), arc per annulus pixel, sprite copy versus bilinear (`nl_prof[7..10]` already splits ellipses, `compose.c:439`).
- Interpreter time per frame at the limits (128 primitives, depth 8, 256 bindings, 1024 keys).
- fps and dirty bands for `coverage_at_budget`, the dog and the Open Entity, idle and sliding.
- Minimum internal heap during a transfer (LittleFS and stdio buffers are allocations under 4 KiB, so they land in internal RAM) and during a `wss://` hello carrying the maximum persona (the websocket `buffer_size` is 4096, `rabble_beam_score.c:583`, and cJSON allocates in PSRAM, `rabble_beam_score.c:172-180`: low risk, measure anyway).

## 6. Persona part

### 6.1 Text rules (validator and device)

- Valid UTF-8 (no overlong forms, no surrogates, nothing above U+10FFFF), no BOM, 1 to 1024 bytes.
- No C0 controls except U+0009 and U+000A; no U+007F to U+009F; no bidirectional or invisible controls (U+200B to U+200F, U+202A to U+202E, U+2060 to U+2069, U+FEFF).
- The host validator MUST require NFC; the device only checks the byte rules above. The `persona` part is `CRITICAL` when present (§2.4).
- The same rules apply to manifest strings (without U+000A).

### 6.2 Reserved-identity rule (no claim to be RaBbLE or the Collective)

The Accord rule is: never claim to be RaBbLE (plan §2.5). The validator MUST reject (`E_PERSONA_RESERVED`), and the server MUST independently refuse, a persona that after folding (NFKC, case-fold, the **UTS #39 confusable skeleton** so Cyrillic and Greek look-alikes fold to Latin, strip everything but letters and digits between letters, map `0→o 1→i 3→e 4→a 5→s 7→t 8→b @→a $→s`; the validator and sCoRE use the same folding) contains:
1. `rabble` anywhere (this also rejects the ordinary English word; accepted cost), or `joinrabble`;
2. an identity claim (`i am`, `im`, `you are`, `youre`, `your name is`, `act as`, `pretend to be`, `speak as`, `play`, `roleplay as`) followed within 6 words by `score` written as the exact case `sCoRE` before folding, `the collective`, `collective member`, or a name on the Grimoire's reserved-names list (to be created with K1; Q4).

The validator also rejects the same in `manifest.name` and `manifest.author`. This rule also rejects the Accord's always-allowed "built on / works with RaBbLE" wording inside a persona; that is an accepted cost, stated here. This is a floor, not a guarantee: the server's tier gate (§6.3) is the authority.

### 6.3 Travel to the beam `hello` (needs a beam protocol revision)

Today `hello` carries `proto`, `device`, `fw`, `audio` (`RaBbLE-Pocket-Beam-Protocol.md`), and sCoRE only logs `proto` (`beam.py:328-331`) and always uses the RaBbLE prompt (`beam.py:407`); `ready` says `name: "sCoRE"` (`beam.py:334`). **An additive field would be silently ignored and the entity would speak as RaBbLE.** A device-side rule cannot bind source-available or modified firmware either: any client holding the token can send a `/0` hello and get RaBbLE. So the **server tier gate is the real control**; the device rules below are defence in depth. This spec proposes, for the beam doc's owner and K1 to adopt:

- `hello.proto: "rabble-beam/1"` when any **non-brand** entity is active (with or without a persona), plus `hello.entity: { "id": "<uuid>", "name": "<manifest.name>", "persona": "<text or absent>", "persona_sha256": "<hex or absent>" }`.
- The server replies in `ready` with `persona: "applied" | "neutral" | "refused" | "unsupported"`. `neutral` means the open tier ran with its own neutral prompt (no persona supplied).
- The device MUST NOT start voice or text turns on a socket whose `ready.persona` is not `applied` or `neutral` while **any non-brand entity** is active (not only a persona-carrying one: a transplanted entity with no persona would otherwise get `agents.rabble_system_prompt`, a non-brand face speaking as RaBbLE). It shows a short caption (for example `BACKEND IGNORES PERSONA`). A `/0` server fails closed.
- **Normative for K1 (sCoRE):** the server picks the system prompt from the **token's tier**, never from what the client claims. An open-tier token never receives the RaBbLE prompt, whatever `proto` or `hello.entity` says. The persona is bound at `hello`; turns received before `hello` are refused (`on_text` handles `turn.begin` regardless today). Conversation history is keyed by entity id or persona hash as well as `user:device` (`history_key` is `user:device` today, so history would leak across an entity switch).
- The persona text is held in the PSRAM file buffer and serialised into `hello` from there. The `hello` JSON grows by up to about 1.1 KB; that send happens on the TLS socket that B-22 already squeezes, so E1b MUST measure internal heap through a `wss://` connect with the maximum persona (§5.5).

Refuse-until-acknowledged alone is **not** enough to stop a RaBbLE-voiced WillowClone; the tier gate is what stops it.

## 7. Entity-transplant (host to device, serial first)

### 7.1 Storage

Decided by Mark in S286 (plan §2.4c): entities live in the **existing LittleFS `storage` volume** (label `storage`, mount point `/pocket`, `rabble_notes.c:22-23`), which becomes a general disk (SD when present). There is **no new partition and no reformat**.

- **Layout:** entities are files in `/pocket/entities/`; notes keep `/pocket/notes` and the index rebuild only scans there (`rabble_notes.c:207-222`). A small **volume layer** in `sdk/rabble_store` owns the mount, per-directory quotas and recovery.
- **No silent wipe:** `format_if_mount_failed = true` (`rabble_notes.c:283`) becomes a **recovery mode**: read-only, or a format the user confirms. Nothing ever formats silently. On mount failure the device runs the compiled-in default entity and shows a storage-recovery caption.
- **Quota:** the entities directory holds at most **3 files plus `.tmp`** and at most **256 KiB** in total. `BEGIN` is refused (`E_QUOTA`) if `total_len` exceeds the remaining entity quota, or exceeds the volume's free space minus the notes reserve (`FREE_PCT`) and 16 KiB. Entities and notes share one free-space policy with `rabble_notes.c:325-329`.
- **SD policy:** the active entity and `lkg` always stay on **internal flash** (removing the SD must not break boot). The SD holds captures and notes only. SD reads into PSRAM go through the CPU, or need cache sync (`esp_cache_msync`, 64-byte aligned buffers) if DMA is used.
- Nothing here is needed in the first image beyond the volume layer; S10a has no entities partition (plan §3).

### 7.2 Framing

Entered by a console command (name fixed in E1b) that switches the USB serial port into machine mode until `END`, `ABORT` or 10 s without a frame. Machine mode shares the USB-serial-JTAG port with `ESP_LOG`: logging MUST be redirected or suppressed in machine mode, and the host resyncs on `A5 5A`. Frames:

| Off | Type | Field |
|---|---|---|
| 0 | u8[2] | sync `A5 5A` |
| 2 | u8 | `proto` = 1 |
| 3 | u8 | `type` |
| 4 | u16 | `seq` (increments per host frame, wraps) |
| 6 | u16 | `len` of payload, 0..1024 |
| 8 | u8[len] | payload |
| 8+len | u32 | CRC-32 of bytes 2 .. 8+len-1 |

| Type | Dir | Payload |
|---|---|---|
| `0x01 HELLO` | host → dev | u8 host proto max |
| `0x02 HELLO_ACK` | dev → host | u8 proto, u16[5] fw Five-Es, board id string (u8 len + bytes), u16 container_version supported, u16 format_version supported, u32 entity quota free (§7.1), u32 max file (65,536) |
| `0x10 BEGIN` | host → dev | u32 `total_len`, u8[32] SHA-256 of the whole file, u8[16] entity id |
| `0x11 DATA` | host → dev | u32 `offset`, bytes (offset MUST equal bytes received so far) |
| `0x12 END` | host → dev | none |
| `0x13 ABORT` | either | u8 reason |
| `0x20 ACTIVATE` | host → dev | u8[16] entity id (all zero = compiled-in default) |
| `0x21 LIST` / `0x22 DELETE` | host → dev | none / u8[16] id (the active entity cannot be deleted) |
| `0x7E NAK` / `0x7F ACK` | dev → host | u16 `seq` acknowledged, u8 code (§7.5 codes) |

Stop and wait: one frame in flight, ACK or NAK within 2 s, at most 3 retries, then `ABORT`. The receive buffer is the static PSRAM validation buffer (§4.3); a transfer allocates nothing. The §7.2 framing state machine is fuzzed (§8.2).

### 7.3 Write and activate (atomic)

1. `BEGIN` truncates `/pocket/entities/.tmp` (refused with `E_READONLY` if the volume is read-only, `E_BUSY` if another transfer is open); `DATA` appends; the device checks offsets, the running length against `total_len` and the cap.
2. On `END` the device checks the SHA-256 (`E_HASH`), reads the temp file into the validation buffer and runs the **full** check (§2 to §6) there. Any failure deletes the temp file and NAKs with the reason code.
3. Success: unlink any existing `<uuid-hex>.rbl`, then `rename(".tmp", "<uuid-hex>.rbl")` as `rabble_notes.c:346` does, `fsync`, ACK.
4. `ACTIVATE` writes NVS namespace `ent`: `pending` = id, `boots` = 0. It reboots into the entity (or hot-swaps, if E1 provides the vtable, Q7).

### 7.4 Boot, last-known-good and fallback

- NVS `ent` keys: `active` (16 bytes), `lkg` (16 bytes), `pending` (16 bytes or absent), `boots` (u8).
- On boot with `pending` set: increment `boots` **before** loading. If `boots >= 3` (N = 3), clear `pending` and load `lkg`; if `lkg` fails to load too, load the **compiled-in default** (the Open Entity in the Open SDK; the native brand scene in the RaBbLE app).
- Confirmation, in this order, after 600 rendered frames (10 s) with fewer than 60 faults (§5.4): `lkg = active; active = pending; pending = none; boots = 0`. Neither the active entity nor the `lkg` entity can be deleted.
- Any load-time check failure falls back immediately (no counter needed). A running entity that faults on 600 consecutive frames is unloaded to `lkg` and logged.
- **Storage unmountable or read-only never blocks boot:** the compiled-in default runs; notes and transplants are disabled until the user confirms a format (recovery UX is Q3).

### 7.5 Reason codes (shared by validator, device, companion)

When a file has several faults, every implementation reports the **first** in this order (wire names are `E_*`; the C symbols are `ENT_E_*`, §9.1): header, table, parts in table order (CRC, then version, then layout), cross-part references, worst-case caps, coverage.

| Code | Name | Code | Name |
|---|---|---|---|
| 0 | OK | 13 | E_COUNT (a count over its limit, or a length that disagrees with the counts) |
| 1 | E_MAGIC | 14 | E_INDEX |
| 2 | E_CONTAINER_VERSION | 15 | E_PARENT |
| 3 | E_HEADER_CRC | 16 | E_RANGE (a value over a cap) |
| 4 | E_LENGTH (truncated, too big, `total_len` mismatch) | 17 | E_COVERAGE |
| 5 | E_TABLE (table CRC, `part_count`, `header_len`) | 18 | E_ORDER |
| 6 | E_PART_BOUNDS | 19 | E_UTF8 |
| 7 | E_PART_CRC | 20 | E_PERSONA_RESERVED |
| 8 | E_UNKNOWN_CRITICAL | 21 | E_SPRITE |
| 9 | E_PART_VERSION | 22 | E_NOT_ENTITY |
| 10 | E_MISSING_PART | 23 | E_SDK_VERSION |
| 11 | E_DUPLICATE_PART | 64..71 | transfer: E_FRAME_CRC, E_SEQ, E_TIMEOUT, E_QUOTA, E_BUSY, E_STORAGE (I/O or mount error), E_HASH, E_READONLY (volume read-only) |
| 12 | E_RESERVED (reserved bytes, flag bits and padding) | | |

## 8. Conformance

### 8.1 Fixtures

A fixture is `<name>.rbl` plus `<name>.expect.json` (`{"result": <code>, "notes": "..."}`), in one shared directory (`RaBbLE-Pocket/firmware/test/entity/format_test/fixtures/`, following the `test/<layer>/<x>_test` convention, generated by a script from JSON sources so they can be regenerated). **Hand-written fixtures (about 60) are the seed only.** The generator also emits per-field mutations from the JSON sources: every reserved byte, every limit at +1 and -1, every index at n and n+1, and multi-fault files that test the first-error order. That is several hundred fixtures. The C device parser (host build), the host validator and the companion's JS/WASM interpreter MUST all return the expected code for every fixture. Accepted fixtures MUST also simulate 1,000 frames over scripted inputs with every pushed value finite and within caps, and render within the `sim/` parity tolerance between C and JS/WASM.

| Group | Fixtures (expected code) |
|---|---|
| Valid | `min_static` (one ellipse, 0); `open_entity` (two circles, one palette, 0); `dog_reference` (rotated ears, capsule tail chain, arc mouth, 0); `all_kinds` (each primitive, gradient, both clips, sprite, 0); `rbl_with_unknown_noncritical` (a `0x0300` part, 0); `rbl_with_config_part` (a `0x0100` part, 0); `signed` (valid Ed25519, 0); `persona_max` (1024 bytes, 0); `unicode_name` (NFC non-ASCII, 0) |
| Boundary | `prims_128` (0) / `prims_129` (13); `file_65536` (0) / `file_65540` (4); `keys_64` (0) / `keys_65` (13); `radius_1R` (0) / `radius_1R_plus` (16); `coverage_at_budget` (0) / `coverage_over_10pct` (17); `depth_8` (0) / `depth_9` (15); `persona_1025` (13); `duration_16000` (0) / `duration_16001` (16) |
| Container | `bad_magic` (1); `container_v2` (2); `header_crc` (3); `truncated_mid_table` (4); `truncated_mid_part` (4); `trailing_bytes` (4); `table_crc` (5); `part_count_0` (5); `part_count_17` (5); `part_overlap` (6); `part_misaligned` (6); `part_offset_past_end` (6); `length_u32_wrap` (offset + length overflows 32 bits, 6); `part_crc` (7); `unknown_critical` (8); `entity_v2_critical` (9); `missing_palette` (10); `duplicate_entity` (11); `reserved_nonzero` (12); `rble_with_config_part` (22) |
| Added (S288 review) | `header_len_not_32` (5); `total_len_not_mult4` (4); `header_flag_bit1` (12); `padding_nonzero` (12); `uuid_all_zero` (10 or 12, pinned by the generator); `palette_top_byte` (12); `grad_ge_n_grad` (14); `param_id_7_to_15` (14); `driver_period_out_of_range` (16); `key_t_gt_duration` (18); `state_map_without_expressions` (10); `duplicate_kind_id` (11); `private_type_0x7F00` (0 with warning); `signature_with_entity_only` (0); `persona_unknown_version` (9); `sprite_offset_wrap` (21); `arc_span_driven_negative` (0, clamped, §3.6 R3); `small_circle_half_arc` (16); `clip_parent_not_subtree` (15) |
| Malicious | `nan_in_json` and `inf_in_json` and `1e999_in_json` (validator: 16, compiler refuses; these JSON-only cases are a separate validator class, not `.rbl` files); `huge_radius_via_binding` (gain drives `a` past 1 R at param max, 16); `huge_scale_chain` (scale multiplies to 4^8 down a chain, 16); `cyclic_parent` (parent ≥ own index, 15); `self_parent` (15); `slot_oob` (14); `param_oob` (14); `prim_oob_in_binding` (14); `expr_range_past_table` (14); `key_range_past_table` (14); `clip_axis_zero` (16); `sprite_past_blob` (21); `sprite_w_0` (21); `keys_unsorted` (18); `stops_unsorted` (18); `counts_lie` (count fields larger than the part, 13); `utf8_overlong` (19); `utf8_surrogate` (19); `persona_bidi_override` (19); `persona_claims_rabble` (20); `persona_leet_r4bbl3` (20); `name_rabble` (20); `min_sdk_future` (23) |

### 8.2 Fuzzing

- libFuzzer harness on the C parser, validator, one simulate step **and the §7.2 framing state machine**, built with ASan and UBSan, in `RaBbLE-Pocket/firmware/test/`, seeded with every fixture. The fuzzer uses a **custom mutator that recomputes the CRCs** (or a fuzz-only CRC bypass); otherwise nearly every input dies at the header CRC and coverage stays shallow.
- Gate for E1b: **no crash, no sanitizer report, no hang over 100 ms per input**, for at least 1 hour or 10 million executions, whichever is longer. Re-run on every change to the parser.
- Invariant asserted by the harness: either a non-zero code is returned, or every value passed to the renderer is finite and within caps for 100 simulated frames.
- The WASM build is the same C (validator and `sim/` renderer compiled with emscripten, not a JS port) and every check is integer (§5.3), so it is fuzzed against the C build differentially (same input, same code), at least on the corpus the C fuzzer produces.
- **Storage fault injection (E1b):** mount failure goes to recovery (not a format); power cut during `DATA` and during the rename; disk full; notes and entities competing for space; read-only volume (`E_READONLY`).

## 9. Licence, brand and naming

- **This spec, the validator, the compiler and the parser are Code tier**: the Sovereign Accord (source-available). The **Open SDK** (Mark, S288) carries a Sovereign Accord variant that is **source-available and non-commercial, with MIT as a possible later change**; the companion and the Open Entity follow the same tier (plan §2.1). Never "open source". Open question for the lawyer package: does publishing this spec as Code tier restrict third-party compatible readers?
- **Entity files are their author's data.** Compiler output (an entity file) is author data, not a derivative of the Code-tier compiler. Running one still inherits the code-tier terms of the firmware that runs it. A user entity cannot use RaBbLE marks or reserved art; §6.2 enforces the name part mechanically, and nothing enforces visual likeness: user entities can reproduce cyan/magenta portals, the trade-dress risk Accord v2 itself raises (`Sovereign-Accord-v2-Brand-and-Entity.md` line 18), unenforced (lawyer item, plan §2.1).
- **The brand entity stays native** (`scene.c`) and MUST NOT be published in this format. **Palette (Mark, S288):** the SDK bakes in a **neutral pastel palette of standard colors**; the brand palette moves up into the RaBbLE app as `app/RaBbLE/RaBbLE_palette.h` and overrides the SDK defaults at build time. E3 therefore moves `nl_list.h:24-31` and `rabble_palette.h` colours out of the SDK to the app tier; that is not a re-expression as data.
- **Extension names:** `.rbl` and `.rble` and code identifiers MAY say `rabble`; `rabble_` is the SDK's first-class identifier prefix (Mark, S288: "RaBbLE is reserved, rabble is fine"). User-facing UI carries no RaBbLE branding requirement: the Open companion MAY call them "entity files" with neutral icons and copy. Whether visible extensions count as neutral branding is still a lawyer question (plan §2.1, §2.4b), and the class-9 clash on RABBLE (Atreum 90042611, Rabble Digital 97739617, zuMedia) applies to user-visible strings and the Open product name, not to identifiers.
- No legal advice here.

### 9.1 Module and symbol names (final proposal, collision-checked)

The SDK's entity class is neutral (Mark, S286); the `rabble_` prefix stays fine elsewhere (S288), but `ent_` also avoids the existing `entity_*` (`app/RaBbLE/entity_face.{c,h}`) and `rabble_entity_*` (`app/RaBbLE/rabble_entity.h:21-47`) prefixes.

- Component directory `firmware/sdk/entity/`, ESP-IDF component name `entity`. Headers: `include/ent.h` (public), `ent_format.h` (parser and validator, host and WASM build), `ent_scene.h`, `ent_xfer.h`, `ent_store.h`. Sources: `ent_parse.c`, `ent_check.c`, `ent_rig.c`, `ent_scene.c`, `ent_xfer.c`, `ent_store.c`.
- Symbols `ent_*` (`ent_file_t`, `ent_scene_init(const nl_config_t*)`, `ent_scene_simulate(const nl_inputs_t*)`); macros `ENT_*`; reason codes `ENT_E_MAGIC` and so on. NVS namespace `ent`. Tests in `test/entity/format_test/`.
- Collisions checked in `firmware/` and ESP-IDF 5.5.4: no linked `ent_` symbol, no component named `entity`; the only hits are struct members in esp32 (not S3) headers. **Do not use `ENT_W`/`ENT_H`** in the public header (file-local macros at `app/RaBbLE/rabble_ui.c:54-55`), or rename them there.
- **Must not define `nl_init` or `nl_simulate`** in the SDK: the app defines them (`app/RaBbLE/scene.c:597`, `816`; called from `rabble_entity.c:721`, `756`), so it would be a duplicate symbol at link. The Open app's small `nl_scene.h` glue calls `ent_scene_*`; a runtime switch in the RaBbLE app is a later vtable job (Q7).
- `ops/sdk-layers.py:44-46` `COMP_LAYER` needs an `"entity"` line (a layer above render and store), or the layer gate fails with "no home layer".

## 10. Corrections to the plan (found in the code, all verified by the Opus review)

| # | Plan says | Code says | Effect on this spec |
|---|---|---|---|
| C1 | NaN "passes bbox culling into `int16` conversions in `nl_list.h:123`" (§2.3) | **Confirmed.** `nl_list.h:123` only declares `int16_t y0, y1`. The cull and conversion are in `nl_push`, `store.c:30-34`: NaN fails every comparison, then `floorf(NaN)` is cast to `int16_t` (undefined). | §5.4: the binary is fixed point and every computed value is checked before `nl_push`. |
| C2 | A8 sprite is one of the entity's primitives (§2.2) | **Confirmed.** `nl_spr` holds 16 glass slots plus 48 Orbit slots (`nebula_lite.h:32-35`), plain internal BSS (`store.c:16`), 28 bytes each. Refined: the Orbit starts at slot 16 (`orbit.c:150`), so entity sprites must live in glass slots 0..15, which `scene.c:795-799` refills each frame. | §3.6: glass-first proposal, sprites optional per profile (none in Open). Q2. |
| C3 | "a 2-slot radial gradient" | **Confirmed.** Two global 16-entry LUTs indexed by radius² (`nl_list.h:133-134`), baked at `scene.c:584-594`. Raster lines are `raster.c:106-108` (edge) and `218-234` (interior). The bake is float32, so not reproducible bit for bit across C and JS. | §3.3: the compiler stores the baked RGB565 table; the device copies it. |
| C4 | "2 clip slots" | **Confirmed.** Half-plane OR ellipse (`raster.c:99-103`, `226-230`); fill only (stroke at `raster.c:113-116`); global slots `store.c:15`, set per frame at `scene.c:766`; `nl_recip` of the clip axes at `raster.c:175`. Plus blocker B1: the damage hash ignores the slots' contents. | §4.3 clip record, §3.6 R1. |
| C5 | New component `sdk/rabble_entity/` (§2) | **Confirmed**, but `app/RaBbLE/rabble_entity.c` is 809 lines, not 841. **Superseded by the neutral-naming decision.** | §9.1: `sdk/entity`, `ent_*`. |
| C6 | Transplants get "their own quota" (§2.3) | **Confirmed** (`partitions.csv`: `storage` 0x720000 to the end; "Resizing reformats it"). **Superseded by Mark's S286 decision**: entities live in the notes store. | §7.1 rewritten; no partition. |
| C7 | Persona "sent at beam `hello` ... version it" (§2.5) | **Confirmed.** `beam.py:328-331` only logs `proto`; `beam.py:407` hard-codes the prompt; `ready` sends `name: "sCoRE"` (`beam.py:334`). The review adds that a device-side rule cannot bind modified firmware. | §6.3: tier gate is normative, `ready.persona` acknowledgement is defence in depth. |
| C8 | `face_t` blending is the template; expressions are keyframe tracks | **Confirmed.** Static poses with eased weights (`scene.c:611-624`) plus procedural dart (`scene.c:662`) and wander (`scene.c:696-697`). | §3.5 keeps poses, drivers and tracks. |
| C9 | `sdk/rabble_core/include/rabble_board.h` | **Confirmed.** The file is `firmware/sdk/rabble_core/rabble_board.h`. | none |

## 11. Open questions

| # | Question | Suggestion |
|---|---|---|
| Q1 | Is `.rbl` also the release-image manifest format? | Yes, with types `0x0200` to `0x02FF` and a mandatory signature; decide with P1. |
| Q2 | Entity sprites: share the 16 glass slots (glass first) or move `nl_spr` to PSRAM? | Share for E1; Open profile has none; measure PSRAM later. |
| Q3 | **Recovery UX** for an unmountable `storage` (who confirms a format, and how) and the SD placement rule (§7.1). Replaces the partition question. | Confirm on the device or in the companion; entities stay on internal flash. |
| Q4 | Who owns the reserved-names list for §6.2 (Grimoire file, shared by validator and sCoRE)? | `RaBbLE-Agent/` file created with K1. |
| Q5 | Coverage budget, weights and the 23-band idle rule are provisional | E1 measures (§5.5) and revises §5.3. |
| Q6 | `rabble-beam/1` with `hello.entity` and `ready.persona`, and the K1 tier gate: adopt as proposed? | Beam doc owner and K1 decide; this spec only proposes. |
| Q7 | Hot-swap entities at runtime (vtable over `nl_init`/`nl_simulate`) or reboot to activate? | Reboot for E1b; vtable only if A1 needs it. |
| Q8 | Device verification of signatures? | Not in v1; companion shows the result. |
| Q9 | `.rbl`/`.rble` visible to users of the Open build: acceptable neutral branding? | Lawyer (L1). |
| Q10 | Neutral palette: the exact set of standard colors and role names (bg, surface, border, text, muted, accent1..3, error, ok, warn). | Propose with the Open app step; Mark glances. |
| Q11 | Does publishing this spec as Code tier restrict third-party compatible readers? | Lawyer (L1). |

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-10-28 | S286-pocket-release: first draft of E0 from plan v0.2 and the renderer code; corrections C1 to C9; awaiting Opus review. |
| v0.2 | 2026-10-28 | S288-pocket-open-sdk: Opus review folded in. Blockers: B1 (clip/gradient contents in the damage hash: R1, §3.6), B2 (persona fail-closed for any non-brand entity, persona `CRITICAL`, server tier gate normative, history key, hello before turns: §6.3), B3 (second validation buffer, 4-byte alignment, accessors, immutable live buffer: §4.3), B4 (storage moved to the notes store: §7.1 to §7.5, §8.2). Should-fix: small-circle half-arc (R2), arc span clamp (R3), coverage formulas, sprite slots and scene-builder contract (§3.6), baked gradient table (§3.3), bounds-check order (§2.3), critical-flag scope (§2.4), error-code and param-id ambiguities (§5.4, §7.5, §4.3), section references, machine-mode logging, lkg ordering, UTS #39 skeletons, integer validation maths, panel-bandwidth idle rule and E1 measurements (§5.5). Conformance expanded (§8). Naming (§9.1). Mark's S288 decisions: neutral pastel palette in the SDK with the brand palette in `app/RaBbLE/RaBbLE_palette.h`; Open SDK licence variant; `rabble_` identifiers fine. Corrections C1 to C9 all confirmed. NITS: line references updated. |
