# RaBbLE-NeBuLA-EyeStates.md — Idle Eye-State Schema and Tensor Form

```
transcribe ~ grimoire >> idle eye-state schema + first tensor form drafted // %EYESTATES_DRAFT%
```

> **Status: Draft v0.** Source: Mark's 8×8 kernel sessions (Oct 2026) and the kernel editor built from them.
> Scope is the **static glyph** of the Entity at idle. Saccades, blinks and every other continuous motion stay in
> `RaBbLE-NeBuLA-Architecture.md` (eye-system). Colors come from `RaBbLE-Agent/RaBbLE-Palette.md` tokens only;
> any hex in a sketch or editor is a placeholder for `rabble_color_cyan` and `rabble_color_magenta`.

---

## What This Defines

A **cell** is one Entity glyph drawn inside a delimiter. The delimiter is the **set**. What sits inside it is the
**entity** (the interior): two portals, two eyes, one cyan and one magenta.

An 8×8 grid of cells is a **kernel**. Kernels are the unit for RaBbLE visual filters (dither, mask, morph variants).

Invariants carried from the entity design rules:

- No pupils, ever.
- The two pole colors are always opposite each other. Which side is cyan may change.
- Portals sit on a diagonal. Eyes never carry lid cuts.
- The interior is rigid. Portals and eyes never move relative to each other in this schema. They flip together around
  an axis. Anything where an orb slides or recedes into a portal is continuous motion and belongs to the eye-system,
  not to the glyph.
- Idle is the baseline. Every state below is a reflection of it, never a motion away from it.

---

## The Cell Word

Three bits, written `set · MSB · LSB`.

| Bit | Name | 1 means | 0 means |
|---|---|---|---|
| 2 | **set** | `[ ]` | `( )` |
| 1 | **MSB** (interior) | magenta eye on the left | cyan eye on the left |
| 0 | **LSB** (interior) | portals top-left and bottom-right | whole interior mirrored top to bottom |

The set bit does not touch the interior. The interior bits do not touch the set. Which delimiter a state wears carries
no meaning of its own.

### The four interior states

Reading order follows the sketch: top row first, then left to right. Portals and eye heights move together.

| Label | Portals | Left eye | Right eye | Working name |
|---|---|---|---|---|
| `01` | top-left, bottom-right | cyan, low | magenta, high | **Rest** (baseline idle) |
| `11` | top-left, bottom-right | magenta, low | cyan, high | **Swap** |
| `00` | top-right, bottom-left | cyan, high | magenta, low | **Mirror** |
| `10` | top-right, bottom-left | magenta, high | cyan, low | **Swap-Mirror** |

Working names are placeholders. The labels are the schema.

All four are legal idle poses. `01` is the baseline and the identity of the entity layer.

---

## Algebra

The two swipe gestures generate every interior state from Rest.

- **swap** trades the eye colors and leaves positions alone. It toggles the MSB.
- **mirror** flips portals and eyes together, top to bottom. It toggles the LSB.

Both are involutions and they commute, so the interior is the Klein four-group, V₄ ≅ Z₂ × Z₂. With the set bit the
whole cell is Z₂³, eight words, closed under XOR.

Write a group element as `g = (swap, mirror)`, two bits, where 1 means that flip is applied. The label is `g` offset
by the baseline: `label = g ⊕ 01`. That offset is why the identity entity is labeled `01` and not `00`. For example,
swap alone is `g = 10`, and `10 ⊕ 01 = 11`.

The flip graph on the interior is a 4-cycle:

```
01 --swap--> 11 --mirror--> 10 --swap--> 00 --mirror--> 01
```

So 01, 11, 10, 00 is the Gray order of the interior alone. Numeric order (00, 01, 10, 11) is not adjacency order. See
Level Order below for the full 3-bit word.

---

## The Grid

Words are `W[r, c]` for row `r` and column `c`, `0 ≤ r, c < 8`, written in binary as `set MSB LSB`.

**Set plane** `S[r, c]` is bit 2. **Entity plane** `E[r, c]` is bits 1 and 0.

### Reset states

Each reset belongs to one plane and must leave the other untouched.

| Plane | Identity | Dither |
|---|---|---|
| Set | `S = I₈`: `[ ]` on the diagonal, `( )` elsewhere | `S[r,c] = 1` when `(r + c)` is even (checkerboard) |
| Entity | `E = 01` in every cell | `E = 01` on even rows, `11` on odd rows (swap on alternate rows) |

Identity on both planes gives `101` on the diagonal and `001` everywhere else, written `[01]` and `(01)`.

```
101 001 001 001 001 001 001 001
001 101 001 001 001 001 001 001
...
```

Dither on both planes:

```
101 001 101 001 101 001 101 001
011 111 011 111 011 111 011 111
...
```

---

## Tensor Form (v0)

### Cell

Each bit is a 2-vector in the basis `|0⟩, |1⟩`. A cell is the tensor product of three of them:

```
|cell⟩ = |set⟩ ⊗ |MSB⟩ ⊗ |LSB⟩      ∈  ℝ² ⊗ ℝ² ⊗ ℝ²  ≅  ℝ⁸
```

It is one-hot: exactly one of the eight basis vectors is 1. With `X = [[0,1],[1,0]]` and `I₂` the 2×2 identity:

| Operation | Operator | Acts on |
|---|---|---|
| tap (switch delimiter) | `X ⊗ I₂ ⊗ I₂` | set only |
| swipe sideways (swap) | `I₂ ⊗ X ⊗ I₂` | MSB only |
| swipe up or down (mirror) | `I₂ ⊗ I₂ ⊗ X` | LSB only |
| entity operation (general) | `I₂ ⊗ B`, where `B` is any 4×4 operator | interior only |
| set operation (general) | `A ⊗ I₄`, where `A` is any 2×2 operator | set only |

"Sets only act on sets" and "entities only act on entities" is the statement that every operator factors this way.
The three generators are permutation matrices and commute pairwise.

### Grid

Two equivalent forms.

- **Bit-plane tensor** `B ∈ {0,1}^(8×8×3)`, with `B[r, c, :] = (set, MSB, LSB)`. Compact. XOR with a kernel is the
  group action: `B′ = B ⊕ K`.
- **One-hot tensor** `T ∈ {0,1}^(8×8×2×2×2)`, with one 1 per `(r, c)` slice. Rank 5. Operators from the table above
  apply along the last three axes. Use this form when a filter needs linear algebra (blends, soft states).

Reset states in bit-plane form:

```
set identity:     B[:, :, 0] = δ[r, c]
set dither:       B[:, :, 0] = 1 − ((r + c) mod 2)
entity identity:  B[:, :, 1] = 0,        B[:, :, 2] = 1
entity dither:    B[:, :, 1] = r mod 2,  B[:, :, 2] = 1
```

### Reference check (numpy)

```python
import numpy as np
from functools import reduce

I2, X = np.eye(2, dtype=int), np.array([[0, 1], [1, 0]])
kron = lambda *m: reduce(np.kron, m)

TAP, SWAP, MIRROR = kron(X, I2, I2), kron(I2, X, I2), kron(I2, I2, X)

# one-hot index of a word w = (set << 2) | (MSB << 1) | LSB is w itself
e = lambda w: np.eye(8, dtype=int)[w]

assert (TAP @ e(0b001) == e(0b101)).all()      # ( )01 -> [ ]01, interior untouched
assert (SWAP @ e(0b001) == e(0b011)).all()     # Rest -> Swap
assert (MIRROR @ e(0b001) == e(0b000)).all()   # Rest -> Mirror
assert (SWAP @ MIRROR == MIRROR @ SWAP).all()  # the swipes commute

# Gray cycle on the interior: 01 -> 11 -> 10 -> 00 -> 01
w = 0b001
for op in (SWAP, MIRROR, SWAP, MIRROR):
    w = int(np.argmax(op @ e(w)))
assert w == 0b001

# Z2^3: the eight products of the generators are distinct
mp = np.linalg.matrix_power
group = {tuple((mp(TAP, a) @ mp(SWAP, b) @ mp(MIRROR, c)).flatten())
         for a in (0, 1) for b in (0, 1) for c in (0, 1)}
assert len(group) == 8
```

---

## Level Order

A signal becomes words by quantizing to 8 levels (3 bits) and looking each level up in an **order**: a list of the
eight words from level 0 to level 7.

| Level | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| **Binary** | 000 | 001 | 010 | 011 | 100 | 101 | 110 | 111 |
| bits changed from previous | | 1 | 2 | 1 | 3 | 1 | 2 | 1 |
| **Gray** (reflected) | 000 | 001 | 011 | 010 | 110 | 111 | 101 | 100 |
| bits changed from previous | | 1 | 1 | 1 | 1 | 1 | 1 | 1 |

Binary averages 1.57 bits per step with a worst step of 3 (011 to 100 changes the delimiter and both interior bits at
once). Gray changes exactly one bit per step, and the last level is one bit from the first, so it is a cycle.

Gray walks the four interior states with `( )`, taps to `[ ]`, then walks them back: Mirror, Rest, Swap, Swap-Mirror,
then `[ ]` Swap-Mirror, Swap, Rest, Mirror. In a gradient every boundary is one visible change. In binary some
boundaries redraw the whole glyph.

The Filter lab in the Kernel Editor renders the same input through both orders side by side.

---

## Filters

A **filter** is a rule that turns a signal into a kernel, or a kernel into a changed kernel. Prototyped in the lab:

1. **XOR filter.** `B′ = B ⊕ K`, with `K` tiled over the field. Fully defined by the group action above.
2. **Selector filter.** A scalar field `x[r, c] ∈ [0, 1]` picks each cell's word. `level = round(7x)`, or
   `floor(7x + t)` with an 8×8 Bayer threshold `t` for ordered dither, then `word = order[level]`.

Not yet defined:

3. **Soft filter.** The one-hot tensor `T` is blended with weights instead of switched. Needs a rule for what a
   half-swapped or half-mirrored entity looks like at idle.

---

## Open Questions

1. **Level order.** Binary or Gray for turning a signal into words. Both are built in the Filter lab so they can be
   compared on the same input. Undecided until Mark has played with them.
2. **Continuous idle.** The four states are discrete poses. How eyes drift between or around them (saccade, blink) is
   the NeBuLA eye-system's job. Does a filter ever read that motion?
3. **The Void.** The editor draws the eyes in `rabble_color_cyan` and `rabble_color_magenta`. Ink and paper are the
   sketch's black on white, which are not palette tokens. A version on `rabble_color_bg` (Deep Void) needs a decision on
   how portals read when they cannot be black.

Settled: the brackets in the labeled state sketch were arbitrary, so set is independent of the interior. The interior is
rigid (see Invariants).

---

## Where This Lives

- Renderer: `RaBbLE-NeBuLA` (`<rabble-entity>`), see `RaBbLE-NeBuLA-API.md`.
- Entity rules: `RaBbLE/` and `RaBbLE-Agent/RaBbLE-Identity.md`.
- Reference tool: the Kernel Editor artifact (8×8 live grid, swipe and tap, SVG export, and the Filter lab).
