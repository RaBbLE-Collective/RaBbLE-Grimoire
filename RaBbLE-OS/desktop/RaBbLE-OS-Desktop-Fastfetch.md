# RaBbLE-OS-Desktop-Fastfetch.md — System Identity Display

```
transcribe ~ grimoire >> fastfetch graphics system: portals, wordmark, fx layers // %EP1_IDENTITY%
```

> **Canonical palette reference:** `../../RaBbLE-Agent/RaBbLE-Palette.md`
> **Files live in:** `RaBbLE-OS/config/fastfetch/` + `RaBbLE-OS/spells/fastfetch-fx.py`
> **Deployed by:** Ansible role `desktop/fastfetch` → `~/.config/fastfetch/`

This doc explains the whole fastfetch graphics system in one place, written so a
small agent can make a targeted change without reverse-engineering the files.

---

## What Appears On Screen

Two portal "eyes" (cyan left, magenta right — RaBbLE's gaze), a half-block
"RaBbLE" wordmark fading cyan→magenta to match the eyes, an "Episode 1 Preview"
footer, and an info column whose key colors run the same cyan→violet→pink→magenta
gradient top to bottom. A ◆ palette strip closes the info column.

The portal pair is **symmetric under a 180° flip**: the dotted arc above the
cyan portal is mirrored as a dotted arc below the magenta portal. One blank
line of breathing room separates the portals from the wordmark.

---

## The Files (and which one you may edit)

| File | Role | Edit by hand? |
|---|---|---|
| `config/fastfetch/rabble-portals.base.txt` | **Source art** — portals, wordmark, footer. Clean, no effects. | **Yes** |
| `spells/fastfetch-fx.py` | Layer compositor — applies effects to the base | Yes (it's the effects code) |
| `config/fastfetch/rabble-portals.txt` | **Generated output** fastfetch displays | **Never** — regenerate it |
| `config/fastfetch/config.jsonc` | Modules, key colors, palette strip | Yes |

The one-line mental model: **base + layers = displayed logo.**

```bash
cd RaBbLE-OS
python3 spells/fastfetch-fx.py                    # compose with all fx layers
python3 spells/fastfetch-fx.py --layers none      # compose clean (fx off)
python3 spells/fastfetch-fx.py --layers particles # one layer only
python3 spells/fastfetch-fx.py --seed 7           # reshuffle the dust
```

Output is deterministic per seed — rerunning with the same flags produces a
byte-identical file, so git diffs only when something really changed.

---

## Effect Layers

Effects are optional layers composited over the base — they can always be
turned off (`--layers none` restores the untouched art). Current layers:

| Layer | What it does | Look |
|---|---|---|
| `particles` | Scatters ~12 dust motes in empty space around the portals. Mostly muted `·`, occasional cyan/magenta `·`, rare violet `✦`. | Space dust |
| `glow` | Places one bright `·` glint in the first free diagonal beside each ◆ diamond. In-ring eye diamonds are usually blocked on all diagonals, so only the floating diamonds and the wordmark accent glint — this is intentional and automatic. | Sparkle |

Hard rules the compositor enforces (keep them if you add layers):

1. **Never overwrite art** — effects go only into empty cells.
2. **Never widen the logo** — fastfetch sizes the logo column by its widest
   line (trailing spaces count!), so effects stay within the base canvas width.
3. **Palette only** — colors come from the table below.

**Adding a new layer:** write a `layer_<name>(grid, rng)` function in
`fastfetch-fx.py` that mutates the `(char, color)` grid, register it in the
`LAYERS` dict, done — it is automatically toggleable by name via `--layers`.

---

## Palette Mapping (256-color indexes)

Approximations of `RaBbLE-Palette.md` hex values in the 256-color cube:

| Palette role | Hex | 256 index | Escape |
|---|---|---|---|
| Electric Cyan | `#00f5ff` | 51 | `38;5;51` |
| Soft Violet | `#bf5fff` | 135 | `38;5;135` |
| Outrun Pink | `#ff79c6` | 205 | `38;5;205` |
| Hot Magenta | `#ff2d78` | 197 | `38;5;197` |
| Muted | `#6b6880` | 60 | `38;5;60` |
| Bright white (portal cores) | — | — | `97` (ANSI bright white) |

**Gotcha (the one with teeth):** fastfetch config color values (`keyColor`,
`display.color.*`, `percent.color.*`, `{#...}` in formats) are **raw SGR
parameters**. A bare `"135"` emits `\e[135m`, which terminals silently ignore —
it renders default white and nobody notices because bold masks it. Always write
`"38;5;135"`. Verify with `fastfetch --logo none --pipe false | cat -v` and
grep for `[38;5;`. (Also recorded in `RaBbLE-Agent/RaBbLE-Agent-Protocols.md`.)

---

## Anatomy of the Base Art

`rabble-portals.base.txt` is a plain ANSI text file, 28 lines:

| Lines | Content |
|---|---|
| 1 | Dotted arc above the cyan portal |
| 2–18 | Portal pair (cyan ring left, magenta ring right, bright-white cores, violet `-` inner ring marks, ◆ eye + floater diamonds) |
| 19 | Dotted arc below the magenta portal — the 180°-flip mirror of line 1 |
| 20 | Blank — breathing room |
| 21–24 | "RaBbLE" half-block wordmark, per-column gradient 51→135→205→197, ◆ accent |
| 25–27 | Divider, "Episode 1 Preview", tagline |

Max content width is 37 columns — keep it there. If you widen any line, the
whole info column shifts right.

## Info Column (`config.jsonc`)

16 modules in four gradient bands of four — keys walk the same cyan→magenta
path as the wordmark:

| Band | keyColor | Modules |
|---|---|---|
| Cyan `38;5;51` | OS · Host · Kernel · Uptime |
| Violet `38;5;135` | Packages · Shell · Display · WM |
| Pink `38;5;205` | Terminal · CPU · GPU · Memory |
| Magenta `38;5;197` | Swap · Disk · Battery · IP |

The bottom row is a **custom module**, not fastfetch's `colors` module: five ◆◆◆
groups in cyan/violet/pink/magenta/muted. The stock `colors` module shows the
*terminal's* ANSI colors; the custom strip shows *RaBbLE's* palette regardless
of terminal theme.

---

## Workflow: Change → Compose → Deploy → Verify

```bash
cd RaBbLE-OS
$EDITOR config/fastfetch/rabble-portals.base.txt   # 1. edit source art (or config.jsonc)
python3 spells/fastfetch-fx.py                     # 2. compose rabble-portals.txt
cp config/fastfetch/{config.jsonc,rabble-portals.txt} ~/.config/fastfetch/  # 3. deploy
fastfetch                                          # 4. eyeball it
```

Step 3 mirrors the Ansible role `desktop/fastfetch` (plain copies); the role is
the durable deploy path, the `cp` is the fast loop. fastfetch is **not** a
dotctl bundle.

**Headless visual verification** (for agents without a terminal to look at):
run fastfetch inside a python `pty` with a `TIOCSWINSZ`-sized window, feed the
output to `pyte`, emit per-cell HTML spans, screenshot the `file://` page with
`spells/visual-screenshot.sh --playwright`. Don't feed full fastfetch output
through pyte at the wrong width — its cursor-positioning escapes scramble.
Packages queries can take >5s; use a long read timeout.

---

```
transcribe ~ grimoire >> the gaze composited in layers, dust optional // %EP1_IDENTITY%
```
