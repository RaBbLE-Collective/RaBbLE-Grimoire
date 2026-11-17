# W1 text golden vectors

Behaviour data for `rabble_text` and the beam text helpers, produced by compiling the original functions on a host and recording what they return. Spec: `../w1-text.spec.md`. The harness that produced them is not shipped (it is tainted by the original source); the specification section 11 says how to build a test vehicle.

## Format

Plain TSV, UTF-8. Lines starting with `#` are header comments and are skipped. Fields are separated by a single tab. Byte strings are lower-case hex with no separators; a lone `-` is the empty byte string (and, in output columns, "no output"). Where a column says otherwise (`@null`, `@empty` in the console file, `00` for an empty string in the unescape file) follow the file's header. Trailing `shown_*` columns are for humans (invalid bytes appear as escaped text, tabs and newlines as `\t` `\n`); do not compare them.

## Files

| File | Function | Rows |
|---|---|---|
| `ascii-map.tsv` | `rabble_text_ascii`, every code point 80 to 10FFFF as ranges | ranges, unlisted = keep (-1) |
| `ascii-edge.tsv` | `rabble_text_ascii` on damaged byte strings: return, consumed length, output | 33 |
| `cjk-map.tsv` | `rabble_text_cjk`, every code point as ranges, unlisted = class 0 | ranges |
| `cjk-edge.tsv` | `rabble_text_cjk` on raw bytes | 10 |
| `has-cjk.tsv` | `rabble_text_has_cjk` | 54 |
| `to-ascii.tsv` | `rabble_text_to_ascii(buf, cap)`: input, cap, result (capacity truncation cases included) | 125 |
| `showable.tsv` | `rabble_text_showable`: which pointer came back (text or buf) and the string | 16 |
| `beam-tail-words.tsv` | `rabble_beam_tail_words` | 69 |
| `beam-caption-at.tsv` | `rabble_beam_caption_at` with explicit page geometry and output cap; false/true and page text | 213 |
| `beam-console.tsv` | `rabble_beam_console`: exact stdout bytes, rows in order, one fresh process (sequence numbers) | 27 |
| `beam-unescape.tsv` | `rabble_beam_unescape` | 16 |

The caption file includes a block of seeded random rows (note `random`) mixing Latin, accents, em dash, ellipsis, emoji, CJK, closing punctuation and newlines at several page sizes and output caps. They are ordinary behaviour data: a correct implementation matches them all.

## Compare rules

Compare the result columns exactly (byte for byte). Never normalise whitespace. For `showable.tsv` the buffer contents are only compared when the pointer column says `buf`. For `beam-caption-at.tsv` compare output only when the returned flag is 1. The console file must be run in file order inside a single process whose sequence counter starts at 1.
