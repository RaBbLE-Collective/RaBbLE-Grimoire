# W1 spec: rabble_text and the caption/console text helpers

> Clean-room spec, wave W1. Author role: S. Files to be replaced: `apache/rabble_text.c`, `apache/rabble_text.h` and `apache/rabble_beam_text.c`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Every function name, type and enumerator below is frozen: all existing callers must compile and behave unchanged. Golden vectors are in `w1-text-vectors/` (see its README); the new code must reproduce them byte for byte.

## 1. Purpose

Two small, pure-text units with no hardware and no tasks of their own.

**Text fitting (`rabble_text`).** The screen's fonts cover ASCII plus a few symbols. Text that comes from elsewhere (model replies, Wi-Fi network names) may hold typographic or accented characters. This unit rewrites such text into plain ASCII where a sensible stand-in exists, deletes characters that would render as blanks or boxes, and leaves everything else alone (notably CJK, which the captions can draw from a fallback font when it is built in). It also classifies characters for line breaking in CJK text.

**Caption and console text (`beam_text` file).** Four helpers used by the sCoRE session code and the serial console:
1. cut a spoken-transcript string down to the last few words that fit one caption line;
2. wrap a reply to the caption page size and return the page that holds the point currently being spoken;
3. print one JSON-ish `@chat` line (or several) to the serial console for typed turns;
4. undo the backslash escapes in a line typed at the console.

## 2. Public interface (complete and exact)

### 2.1 `rabble_text.h` (frozen)

The header must keep C++ linkage guards (`extern "C"`), `#pragma once`-style protection, and include only `<stdbool.h>` and `<stddef.h>`.

```
typedef enum {
    RABBLE_TEXT_NOT_CJK,       /* value 0 */
    RABBLE_TEXT_CJK,           /* value 1: a line may break before or after it */
    RABBLE_TEXT_CJK_CLOSE,     /* value 2: closing punctuation, never starts a line if avoidable */
} rabble_text_cjk_t;

int  rabble_text_ascii(const char *s, size_t *len, char out[4]);
rabble_text_cjk_t rabble_text_cjk(const char *s);
bool rabble_text_has_cjk(const char *s);
void rabble_text_to_ascii(char *s, size_t cap);
const char *rabble_text_showable(const char *text, char *buf, size_t cap);
```

The numeric enumerator values (0, 1, 2) are part of the contract (vectors store them).

### 2.2 Functions of the beam text file (frozen)

These are not declared by a header of their own. Today they are declared in two existing headers, which remain in the tree until wave W3 replaces them:

| Function | Declared in |
|---|---|
| `void rabble_beam_tail_words(const char *src, char *out, size_t cap)` | `rabble_beam_priv.h` |
| `bool rabble_beam_caption_at(const char *text, size_t at, char *out, size_t cap)` | `rabble_beam_priv.h` |
| `void rabble_beam_console(const char *type, const char *text, const char *fields, ...)` with `__attribute__((format(printf, 3, 4)))` | `rabble_beam.h` |
| `size_t rabble_beam_unescape(char *s)` | `rabble_beam.h` |

The clean workspace does not contain those two headers. The implementer therefore adds one new RaBbLE-owned header (suggested name `rabble_beam_text.h`) that repeats exactly these four prototypes, with the printf-format attribute on the console function, and includes it from the new `.c` file. Repeating an identical prototype in the old headers is legal C, so both can coexist until W3. The header must be usable from C++ (guards). The new `.c` file must not include the Meta-derived headers.

The beam text file also needs, from the shared state module (already clean, `accord/rabble_state.h`):
`void rabble_state_page(bool cjk, int *cols, int *lines);` which returns the caption page geometry (characters per line, lines per page). With no CJK page configured it returns the normal page for both kinds of text.

### 2.3 Who uses what (grep of `accord/`, `apache/`, `bsp/`, `main/`)

| Symbol | Callers |
|---|---|
| `rabble_text_to_ascii` | `accord/rabble_state.c` (caption setter, buffer cap 400) |
| `rabble_text_showable` | `apache/rabble_settings_ui.c` (two label helpers, buffer 96 bytes, called with network names and settings strings) |
| `rabble_text_ascii`, `rabble_text_cjk`, `rabble_text_has_cjk` | only the beam text file and the text unit itself. No other caller exists. |
| `rabble_beam_tail_words` | `accord/rabble_beam_score.c` (event emitter, for transcripts of what the user said; output buffer is the event text field) |
| `rabble_beam_caption_at` | `accord/rabble_beam_score.c` (`rabble_beam_turn_caption`, copies up to 4096 bytes of reply, output buffer 400 bytes supplied by `apache/rabble_voice.c`) |
| `rabble_beam_console` | `accord/rabble_beam_score.c` (types `sent`, `text`, `done`, `error`), `apache/rabble_input.c` (types `error` and `ack` with a `"bytes":%u` member) |
| `rabble_beam_unescape` | `apache/rabble_input.c` (console `chat=` / `chat+=` lines) |

The screen in practice is configured 18 columns by 3 lines, and nothing currently sets a separate CJK page, so CJK replies use the normal page. The implementation must still honour a configured CJK page (vectors cover it).

## 3. Behaviour: `rabble_text`

### 3.1 Character decoding (shared by all five functions)

The input is a NUL-terminated byte string that is meant to be UTF-8 but may be damaged. The decoder is deliberately lenient and the leniency is observable, so it is specified exactly.

1. Classify the first byte: `00` to `7F` is a one-byte character; `80` to `BF` is a stray continuation byte; `C0` to `DF` announces 2 bytes; `E0` to `EF` announces 3; `F0` to `FF` announces 4 (so `F8` to `FF` are treated as 4-byte leads).
2. A stray continuation byte is a one-byte unit with no value (invalid).
3. For an announced length N, take the lead's low bits (lead minus the length marker, i.e. 5, 4, 3 payload bits for N = 2, 3, 4; for the F8 to FF leads use 3 payload bits, as an F0 to F7 lead) and then absorb following bytes while they are continuation bytes (`80` to `BF`), up to N-1 of them, 6 bits each. Absorption stops at the first non-continuation byte, which includes NUL.
4. If all N-1 continuation bytes were found, the character is valid and its value is the accumulated number, with **no** checks for overlong forms, surrogates (D800 to DFFF) or values above 10FFFF. Overlong encodings of a value decode to that value. If fewer were found, the unit is invalid and its length is the number of bytes consumed so far (lead plus the continuations that were present). The byte that stopped it is not consumed.
5. Invalid units are therefore 1 to 3 bytes long. A valid unit that decodes to a value below 80 (an overlong ASCII) is treated as "keep as is" everywhere below, with its true encoded length.
6. The consumed length is what callers advance by.

See `ascii-edge.tsv` for the exact consumed lengths on damaged input.

### 3.2 `rabble_text_ascii(s, len, out)`

Looks at the one character starting at `s` and reports what to do with it.

1. `*len` is always written with the character's consumed length from 3.1 (1 for ASCII, for stray bytes, and for a lead followed immediately by a non-continuation).
2. Return **-1** ("keep the original bytes") for: ASCII; any invalid unit; any value below 80; any valid value not covered by the table in 3.3. `out` is not written when -1 is returned.
3. Return the length **L** (0 to 3) of the stand-in otherwise, and write the stand-in's L bytes into `out`, followed by a NUL when L is below 4 (out has room for 4 bytes). L = 0 means "delete the character".
4. No stand-in is longer than 3 bytes.

### 3.3 The mapping (behaviour table, by output)

Code points are hexadecimal Unicode scalar values. Anything not listed returns -1 (kept). The full machine-readable form is `w1-text-vectors/ascii-map.tsv` (every code point from 80 to 10FFFF); where this table and the vectors differ, the vectors win and the difference is a spec bug to report.

**Deleted (stand-in empty):**
- 00AD soft hyphen, 2060 word joiner, FEFF byte order mark;
- 0300 to 036F combining marks (an accent typed after its letter);
- 200B to 200F zero-width spaces, joiners and direction marks;
- 20E3 combining keycap;
- 2600 to 27BF symbols and dingbats, **except** 2713 and 2714 (check marks, become `v`) and 2717 and 2718 (crosses, become `x`), which are mapped. 2715 and 2716 are deleted with the rest;
- 2B00 to 2BFF;
- FE00 to FE0F variation selectors;
- 1F000 to 1FAFF (emoji and pictographs);
- E0000 to E007F (tag characters).

**Spaces (stand-in one space):** 00A0, 2000 to 200A, 2028, 2029, 202F, 205F.

**Letters of the Latin-1 Supplement and Latin Extended-A (00C0 to 017F), by plain letter:**

| Output | Code points |
|---|---|
| A | 00C0 to 00C5, 0100, 0102, 0104 |
| a | 00E0 to 00E5, 0101, 0103, 0105 |
| C / c | 00C7, 0106, 0108, 010A, 010C / 00E7, 0107, 0109, 010B, 010D |
| D / d | 00D0, 010E, 0110 / 00F0, 010F, 0111 |
| E / e | 00C8 to 00CB, 0112, 0114, 0116, 0118, 011A / 00E8 to 00EB, 0113, 0115, 0117, 0119, 011B |
| G / g | 011C, 011E, 0120, 0122 / 011D, 011F, 0121, 0123 |
| H / h | 0124, 0126 / 0125, 0127 |
| I / i | 00CC to 00CF, 0128, 012A, 012C, 012E, 0130 / 00EC to 00EF, 0129, 012B, 012D, 012F, 0131 |
| J / j | 0134 / 0135 |
| K / k | 0136 / 0137, 0138 |
| L / l | 0139, 013B, 013D, 013F, 0141 / 013A, 013C, 013E, 0140, 0142 |
| N / n | 00D1, 0143, 0145, 0147, 014A / 00F1, 0144, 0146, 0148, 014B |
| O / o | 00D2 to 00D6, 00D8, 014C, 014E, 0150 / 00F2 to 00F6, 00F8, 014D, 014F, 0151 |
| R / r | 0154, 0156, 0158 / 0155, 0157, 0159 |
| S / s | 015A, 015C, 015E, 0160 / 015B, 015D, 015F, 0161, 017F |
| T / t | 0162, 0164, 0166 / 0163, 0165, 0167 |
| U / u | 00D9 to 00DC, 0168, 016A, 016C, 016E, 0170, 0172 / 00F9 to 00FC, 0169, 016B, 016D, 016F, 0171, 0173 |
| W / w | 0174 / 0175 |
| Y / y | 00DD, 0176, 0178 / 00FD, 00FF, 0177 |
| Z / z | 0179, 017B, 017D / 017A, 017C, 017E |
| x | 00D7 |
| `/` | 00F7 |

Letters with two-letter stand-ins: 00C6 `AE`, 00E6 `ae`, 00DE `Th`, 00FE `th`, 00DF `ss`, 0132 `IJ`, 0133 `ij`, 0152 `OE`, 0153 `oe`, 0149 `'n`.

Every character in 00C0 to 017F is covered by the two tables above. In 0080 to 00BF only the ones named in the punctuation table below are mapped; the rest (for example the C1 controls 0080 to 009F, 00A4, 00A8, 00AA, 00AC, 00AF, 00B6, 00B8, 00BA) are kept.

**Punctuation, symbols and marks, by output:**

| Output | Code points |
|---|---|
| `!` | 00A1 |
| `c` | 00A2 |
| `GBP` | 00A3 |
| `Y` | 00A5 |
| `\|` | 00A6 |
| `S` | 00A7 |
| `(c)` / `(R)` / `TM` | 00A9 / 00AE / 2122 |
| `<<` / `>>` | 00AB / 00BB |
| `o` | 00B0 |
| `+-` | 00B1 |
| `2` / `3` / `1` | 00B2 / 00B3 / 00B9 |
| `'` | 00B4, 02BC, 2018, 2019, 201B, 2032 |
| `u` | 00B5 |
| `.` | 00B7, 2024 |
| `1/4`, `1/2`, `3/4` | 00BC, 00BD, 00BE |
| `?` | 00BF |
| `^` | 02C6, 2191 |
| `~` | 02DC, 2248 |
| `-` | 2010, 2011, 2012, 2013, 2027, 2212 |
| `--` | 2014, 2015 |
| `\|\|` | 2016 |
| `,` | 201A |
| `"` | 201C, 201D, 201E, 201F, 2033 |
| `+` | 2020 |
| `*` | 2022, 2217 |
| `>` / `<` | 2023, 203A / 2039 |
| `..` / `...` | 2025 / 2026 |
| `!!`, `??`, `?!`, `!?` | 203C, 2047, 2048, 2049 |
| `/` | 2044, 2215 |
| `EUR` | 20AC |
| `<-`, `->`, `<->` | 2190, 2192, 2194 |
| `v` | 2193 (down arrow), 2713, 2714 |
| `<=` | 21D0, 2264 |
| `=>`, `<=>` | 21D2, 21D4 |
| `!=` | 2260 |
| `>=` | 2265 |
| `x` | 2717, 2718 |

**Kept (examples, all return -1):** every CJK, Hangul, kana and fullwidth form; Greek, Cyrillic, Arabic, Hebrew, Thai; Latin Extended-B and later (0180 onwards) except the modifier letters named above; general punctuation not listed (for example 2021, 2030, 2031, 2034, 203D); currency signs other than the euro, pound and yen; arrows and math symbols outside the listed ones (for example 2195 to 21CF and 2200 to 2211).

### 3.4 `rabble_text_cjk(s)`

Classifies the one character at `s` for line breaking. Empty string, ASCII, damaged input and every value outside the ranges below are `NOT_CJK`. Otherwise:

1. **CLOSE (2)** for exactly these values: 3001, 3002, 3009, 300B, 300D, 300F, 3011, 3015, 3017, 3019, 301B, 30FB, 30FC, FF01, FF09, FF0C, FF0E, FF1A, FF1B, FF1F, FF3D, FF5D, FF60.
2. **CJK (1)** for values in 2E80 to 9FFF, AC00 to D7AF, F900 to FAFF and FF00 to FFEF that are not in rule 1. (This deliberately includes the ideographic space 3000, opening brackets such as 300C, and fullwidth Latin letters.)
3. Everything else is NOT_CJK, including emoji and Latin.

The close-check wins over the range check. Full ranges: `cjk-map.tsv`.

### 3.5 `rabble_text_has_cjk(s)`

True when any character of the string is class CJK or CLOSE (damaged units are skipped by their consumed length). False for the empty string. Decides which page geometry the caption uses.

### 3.6 `rabble_text_to_ascii(s, cap)`

Rewrites `s` in place. `cap` is the size of the buffer holding `s`, including the terminating NUL. Caller contract: the string is shorter than `cap` on entry (strictly less). Behaviour with a longer string is not specified and not tested.

1. Walk the characters from the start. For each character use 3.2: a -1 character stays exactly as it was; a stand-in replaces the character; a length-0 stand-in deletes it. The replacement text is never re-examined.
2. Capacity rule (exact; this differs from the simple reading in the W0 state spec, see 3.9): before replacing a character that has a stand-in (including a one-for-one replacement such as an accented letter and including a deletion), compute the length the **entire string** would have after that replacement, counting everything already converted, the stand-in, and the **rest of the string after this character exactly as it currently is (unconverted)**. If that length is at least `cap`, the string is cut off at this character: nothing from this character onwards is kept, the earlier converted part stays, the NUL goes there, and the function returns. Kept (-1) characters never trigger this check.
3. Consequently the result is always shorter than `cap`, and the check is conservative: later shrinkage (later accents becoming plain letters, later emoji vanishing) is **not** anticipated, so text can be cut that would eventually have fit. Vectors `to-ascii.tsv` ("later shrink not anticipated") pin this.
4. Pure ASCII and strings with only kept characters are returned unchanged.
5. Damaged bytes are kept and do not stop the walk; the walk advances by the consumed length.

### 3.7 `rabble_text_showable(text, buf, cap)`

Gives the caller a string that is safe to draw.

1. If `text` has no byte with the top bit set, return `text` itself (the same pointer), without touching `buf`.
2. Otherwise try to copy the whole of `text` into `buf` (capacity `cap`, including NUL). If it does not fit completely (including when `cap` is 0 or 1 and `text` is non-empty), return `text` itself, unconverted. The content of `buf` is then unspecified.
3. If it fit, convert the copy in place with the rule in 3.6 (so the converted copy may still end early if an expansion would not fit) and return `buf`.
4. The returned string is valid until the caller changes `buf` or `text`. `buf` is never returned unless the whole input fitted. A non-ASCII input with no stand-ins (for example CJK) is returned in `buf` unchanged.
5. `cap` equal to 0 is allowed: nothing is written to `buf`.

### 3.8 Threading and resources (text unit)

All five functions are pure with respect to their arguments: no static state, no allocation, no locks, no I/O. Reentrant, callable from any task. Not for ISR use (no requirement either way). Typical stack use small (a few dozen bytes). Cost is linear in the string length (two passes at most).

### 3.9 Correction to the W0 state spec, section 3.5 rule 3

That rule says the function "drops characters it has no stand-in for". This is wrong. Characters without a stand-in (CJK, Cyrillic, Greek, damaged bytes and many symbols) are **kept**. Only the listed sets in 3.3 (combining marks, zero-width, dingbats and symbols, selectors, emoji, tags, soft hyphen, word joiner, BOM) are removed. The statement "if an expansion would not fit in the buffer, the text ends there" is correct, but the exact trigger is the whole-string length rule in 3.6.2, which applies to one-for-one replacements as well. With the state module's use (400-byte buffer, strings up to 399 bytes) the difference matters only for strings near the limit. Everything else the W0 spec assumes (cap 400, in place, result NUL terminated, ASCII unchanged, no effect on the caller's version logic) is correct. The state module itself needs no change, because it only relies on the entry-point contract; a state test vector that expects CJK to vanish would be wrong.

## 4. Behaviour: `rabble_beam_tail_words(src, out, cap)`

Produces the short tail of a long transcript so a one-line caption can show what the user is saying now. `cap` is at least 1.

1. The caption fits 32 bytes (not characters) across. If `src` is 32 bytes or shorter, the start is `src` itself.
2. If longer, the candidate start is the position 32 bytes before the end of `src`. Look for the first space inside that final 32-byte window. If one exists, it has at least one byte after it, and it lies fewer than 12 bytes from the window start (offset 0 to 11), move the start to the byte after that space. Otherwise keep the window start. (Offsets 12 and up, and a space that is the very last byte, do not qualify; see the "window space at offset" vectors.)
3. Then, whichever way the start was chosen, skip forward over UTF-8 continuation bytes (80 to BF) so the text does not begin in the middle of a character. The skip also applies when the start was moved to just after a space.
4. Then skip any spaces (only the space character, not tabs).
5. Copy the rest of `src` to `out`, truncated to `cap - 1` bytes plus NUL. The truncation is bytewise and may split a multi-byte character; this is accepted. If `cap` is 0 nothing is written.
6. An all-space or empty `src` gives the empty string. When `src` is 32 bytes or fewer only step 4 applies (leading spaces are removed, nothing else is trimmed, trailing spaces stay).

## 5. Behaviour: `rabble_beam_caption_at(text, at, out, cap)`

Wraps `text` into lines of the screen's page size and returns, in `out`, the page that contains byte offset `at`. `cap` is at least 1. Returns true when a page was produced (even an empty one), false when `text` has no printable content.

### 5.1 Geometry

1. Ask the state module for the page with `cjk` = whether the whole text contains any CJK/CLOSE character (3.5): `cols` characters per line, `lines` lines per page. The state module returns the normal page unless a CJK page with a positive column count is configured and the text has CJK.
2. No validation is applied here. Zero or negative `cols` behaves as "one character per line" (a line always takes at least its first character; see 5.2.2). `lines` of 0 or less produces an empty page (true with an empty string) as long as the text has at least one line.

### 5.2 Line wrapping

Lines are built one after another from the start of the text. For each line:

1. **Leading whitespace.** Spaces and newline characters at the start of a line (that is, between lines) are skipped. Tabs, carriage returns and other control bytes are ordinary characters. If nothing remains, there is no further line.
2. **Width of each character** is the number of columns it takes as the screen shows it: the length of its ASCII stand-in per 3.2 (an ellipsis counts 3, an em dash 2, an accented letter 1, an emoji 0), or 1 for kept characters, including CJK, damaged bytes and ASCII. Every character is measured on its own; widths are not otherwise adjusted. A line always accepts its first character regardless of width (so a width of 3 on a 2-column page still lands on a line).
3. **Hard end.** A newline character ends the line (it is not part of it). The text is also exhausted at its end. A line ends early when the next character does not fit: the running width plus the character's width would exceed `cols`, and the line already has at least one character.
4. **Break opportunities** (positions where a line may be ended instead of splitting through a word):
   - before any space (the space itself is dropped from the line end and then skipped as leading whitespace of the next line);
   - between characters when CJK allows it: immediately before a character C that is not first on the line, C is not CLOSE, and either C is CJK or the character before it (on this line) was CJK or CLOSE. In words: CJK text can break between any two characters, and CJK can break from adjacent Latin text, but a break is never put before closing punctuation.
5. **When the next character does not fit**, choose where to end the line:
   - if the character that does not fit is a space, end the line before it;
   - else if a break before this very character is allowed under the CJK rule of 5.2.4, end the line before it;
   - else if the character is CLOSE punctuation and no break opportunity has been recorded earlier on this line: end the line before the most recent character that is neither CLOSE nor the first character of the line, so that character travels with the punctuation to the next line (see vector "close after latin word": `abcd。` at 4 columns splits as `abc` and `d。`). If the line has no such character, end it before the punctuation, which then starts the next line (vector "cjk close punct never starts line");
   - else if any break opportunity was recorded earlier on this line, end the line before the **latest** one (the last space or last permitted CJK break). Earlier spaces in a run of spaces stay on the line, so a line may end with a trailing space when two or more spaces separated the words (vector "multiple spaces wrap");
   - else (a single long word with no opportunities) split hard at the character that does not fit.
6. A line is never empty: it contains at least its first character, except that no line is produced when only whitespace remains. Zero-width characters at the start of a line therefore still make a line (it prints as empty).
7. After a line, the next line begins right after the last character kept (the break space or newline is consumed by rule 5.2.1 on the next line).
8. Lines are slices of the **original** text. The returned page contains the original bytes (an ellipsis remains an ellipsis); only the width accounting uses the stand-in lengths.
9. Spaces inside a line are kept as written (runs of spaces are not collapsed). Trailing spaces at the end of the text remain on its last line. No hyphenation is ever inserted.

### 5.3 Choosing the page

1. Number the lines from 0. The target line is the **first** line whose end (the offset one past its last kept byte, excluding the dropped break space) is greater than `at`. Offsets inside the whitespace between lines, or on a dropped break space, therefore select the next line.
2. If no line ends beyond `at` (at is at or past the end), the target line is the last line.
3. If there are no lines at all (empty or whitespace-only text), return false and leave `out` untouched.
4. Pages **overlap by one line**: with `lines` per page, pages start at line indexes 0, `lines-1`, `2*(lines-1)`, and so on, and the page holding the target line is the one whose start is the largest multiple of `lines-1` not above the target line. This means the last line of one page is the first line of the next, and the page turns as that line begins to be spoken. When `lines` is 1 the page is exactly the target line; when `lines` is 2 pages advance one line at a time (this does not use the multiplication form when lines is 1 or less, where the page start is the target line itself).
5. The page contains the lines from the page start up to `lines` lines, joined with a single newline character (no trailing newline). It stops early at the end of the text (the final page may have fewer lines).

### 5.4 Output buffer

1. `out` is always set to the empty string first when true is returned.
2. Lines are appended whole. Before appending a line the function checks that the output so far, one separator byte, and the line's bytes would stay **strictly below** `cap` (i.e. the total stays at most `cap - 1` including the separator slot even for the first line). When a line does not fit, it and all later lines of the page are dropped; there is no partial line. This check is conservative by one byte for the first line: a first line of `cap - 1` bytes is dropped (vector "out too small: first line does not fit").
3. True is returned even when the page ends up empty because of this rule or because `lines` is not positive.
4. The text is only read, never modified. `out` and `text` must not overlap.

### 5.5 Performance and resources

Called from the voice task whenever it refreshes the caption (several times a second) with replies of up to 4096 bytes: complexity linear in text length per call, with no allocation and a stack footprint of well under 200 bytes. The unit scans the text from the beginning on each call (no cache is required or promised).

## 6. Behaviour: `rabble_beam_console(type, text, fields, ...)`

Prints one or more lines to the serial console (standard output) in the format `@chat {...}` followed by a line feed. Used for typed turns, acknowledgements and errors, and read by host tooling, so the byte format is exact.

### 6.1 Line format

A line is, in this order, with no spaces anywhere other than inside text:

1. the characters `@chat {"seq":` followed by the sequence number in decimal;
2. `,"type":"` followed by `type` copied verbatim (not escaped; callers pass plain words) and a closing quote;
3. if `fields` is not NULL: a comma, then `fields` formatted as printf formats it with the remaining arguments (the caller supplies JSON object members such as `"bytes":12`, no braces, no leading comma);
4. if `text` is not NULL: `,"text":"`, then an escaped piece of the text (6.2), then a closing quote;
5. `}` and a line feed.

### 6.2 Escaping and splitting

1. The text is escaped character by character: `"` becomes `\"`, `\` becomes `\\`, line feed `\n`, carriage return `\r`, tab `\t`; any other byte below 20 hex becomes `\u` plus four lower-case hex digits (`\u0001`); byte 7F and everything else is copied raw. A byte of 80 or above is copied together with up to three following continuation bytes (80 to BF) as one unit, so a UTF-8 character is never split across lines. This grouping is by byte pattern only: stray continuation bytes group with their successors up to four bytes in all (vector "stray continuation bytes").
2. A line carries at most **239 bytes** of escaped text, always a whole number of escaped units (an escape sequence such as `\n`, `\"`, `\u0001`, or a grouped UTF-8 unit is never cut). If the next unit would take the escaped text of the line to 240 bytes or more, the line ends before it.
3. If the text is longer than one line allows, further lines are printed immediately, repeating the type and fields, each with the next piece of text, until all text has been printed. Each line gets its own sequence number. An empty text string (not NULL) prints exactly one line with `"text":""`. A NULL text prints no `text` member.
4. The fields member is formatted afresh for every line.
5. Lines are bounded: type plus fields plus 239 bytes of text always stays well below 400 bytes (callers pass short fields). If `fields` expands to something absurdly long (more than about 140 bytes) it is cut; this is a never-happens guard and is not tested.

### 6.3 Sequence number

A process-wide counter shared by all callers and all tasks, starting at 1 for the first line printed after boot. Every printed line, including continuation lines, takes the next number. The increment must be atomic (two tasks may print at the same time; numbers are unique and increasing, with no gaps within one call's single-threaded lines). It wraps naturally at 2^32.

### 6.4 Writing

Each line leaves in a single write followed by a flush, so lines from different tasks (and ordinary log lines from other tasks) interleave between lines, never inside them. Task context only. The function may block briefly in the stdio layer. It must not need more than about 500 bytes of stack beyond the callee's own library use. It never allocates.

## 7. Behaviour: `rabble_beam_unescape(s)`

Edits `s` in place, replacing escapes typed at the console, and returns the new length (which is never longer than the old).

1. A backslash followed by any character other than NUL consumes both and yields one character: `n` yields line feed, `r` carriage return, `t` tab, and any other character yields itself (so `\\` yields a backslash, `\"` a quote, `\q` a `q`, `\0` the digit `0`, `A` becomes the five characters `u0041`).
2. A backslash that is the last character of the string (followed by NUL) stays as a literal backslash.
3. All other bytes, including raw line feeds and bytes of 80 and above, pass unchanged. The string is processed left to right with no re-scanning of produced characters (`\\n` yields a backslash followed by `n`).
4. The result is NUL terminated. The empty string returns 0.

## 8. Edge cases summary

| Case | Result |
|---|---|
| Stray continuation byte, truncated sequence, FF byte, surrogate, value above 10FFFF in the input | Kept as bytes by `ascii`; class NOT_CJK; never stop a walk. See 3.1 and `ascii-edge.tsv`. |
| Overlong encodings | Decode to their value; 2-byte `C3 A9` and 3-byte `E0 83 A9` both fold to `e`. |
| `to_ascii` with a long expansion at the tail | Text is cut there; earlier conversions stay (3.6.2). |
| `showable` with cap 0 or 1 | Returns `text` unconverted if non-ASCII. |
| `tail_words` with window space at offset 11 versus 12 | 11 jumps, 12 does not. |
| Caption for empty or whitespace-only text | false; `out` untouched. |
| Caption with `at` past the end | Last page. |
| Caption with `cols` 0 or negative | One character per line. |
| Caption with emoji only text | Lines of zero width characters appear as lines of raw bytes. |
| Console text of exactly 239, 240 and 241 bytes | 1, 2 and 2 lines respectively (the 240 case carries 1 byte on line two). |
| Unescape of a trailing backslash | Kept. |

## 9. What these units may call

Allowed: the C library (string functions; a safe bounded string copy may be provided by the platform or written locally; formatted output and stdio for the console function), `rabble_state_page` from the shared state module, and the unit's own functions. The beam text file may call the text unit. Not allowed: LVGL, FreeRTOS APIs other than what an atomic increment needs, ESP-IDF drivers, logging macros, NVS, any other `rabble_*` module, or any Meta-derived header. No heap allocation. No global mutable state other than the console sequence counter.

## 10. Device checklist

On target hardware after the swap (Pocket on a USB cable with the serial monitor):

1. Boot: no link errors for the nine symbols; the settings screen draws.
2. Settings, Wi-Fi list: a network whose name has an accent, a curly apostrophe or an emoji shows the folded ASCII (or without the emoji), no boxes. A plain name is unchanged.
3. Settings, sCoRE URL and token pages: strings render unchanged; a very long string (near 96 bytes) is cut, not corrupted.
4. Talk to sCoRE by voice: the transcript caption while speaking shows the last words only, starting at a word boundary, not mid-character, with no leading blank.
5. Reply caption: a multi-sentence reply pages in 18 by 3 lines; the page turns when the last line of the page starts being spoken and no line is skipped or repeated more than the one overlap line. A reply with an ellipsis and em dashes wraps within 18 columns as counted in section 5.2.2.
6. A reply containing CJK (with the CJK font build) wraps between characters and never begins a line with closing punctuation unless unavoidable.
7. Console: send `chat=hello` (via the host tool): `@chat` lines `ack` (with bytes), then `sent`, `text` pieces (multiple lines for long replies), `done`. Sequence numbers increase by one per line. Text with quotes, tabs and non-ASCII appears correctly escaped. A reply over 239 bytes arrives in several `text` lines whose concatenation equals the reply.
8. Console with `chat+=` / `chat=` pieces containing `\n`, `\t` and `\\` arrive with the escapes undone.
9. No reboot or watchdog during a 4 KB reply captioned for a full spoken turn.

## 11. Host test vehicle

The implementer builds a host harness (not shipped to the device) that links the new files only, with these stubs:
- `rabble_state_page` supplied by the harness from the row being tested: returns (`cjk_cols`, `cjk_lines`) when `cjk` is true and `cjk_cols` is positive, else (`cols`, `lines`);
- a bounded string copy if the host C library lacks one.

For each file in `w1-text-vectors/` (formats in its README), the harness reads rows, skips `#` lines, decodes hex fields, calls the function and compares **exactly** the result columns (the trailing human-readable columns are ignored):

| Vector file | Function |
|---|---|
| `ascii-map.tsv` | `rabble_text_ascii`: for every code point 80 to 10FFFF encoded as ordinary UTF-8, check return value, consumed length and output; unlisted means -1 and consumed length equal to the encoded length |
| `ascii-edge.tsv` | `rabble_text_ascii` on raw damaged bytes |
| `cjk-map.tsv`, `cjk-edge.tsv` | `rabble_text_cjk` (unlisted code points 1 to 10FFFF are class 0) |
| `has-cjk.tsv` | `rabble_text_has_cjk` |
| `to-ascii.tsv` | `rabble_text_to_ascii` |
| `showable.tsv` | `rabble_text_showable` (returned pointer identity and returned string) |
| `beam-tail-words.tsv` | `rabble_beam_tail_words` |
| `beam-caption-at.tsv` | `rabble_beam_caption_at` (set the stub geometry per row; compare the returned boolean, and the output only when true) |
| `beam-console.tsv` | `rabble_beam_console`, rows executed **in file order in one fresh process**, standard output captured per call and compared byte for byte (sequence numbers included) |
| `beam-unescape.tsv` | `rabble_beam_unescape` (return value and result) |

Pass criterion: zero mismatches across all files. The harness also runs under an address sanitizer with buffers allocated exactly at the stated sizes (input buffers of at least `max(cap, length + 1)` bytes for `to_ascii`) to catch overruns, and the implementation is compiled once as C and once with the header included from C++. Test vectors for the console file must be run with a stdout that is not the harness's own result channel.

## 12. Ambiguities and decisions for the reviewer

1. `rabble_text_ascii` returning `-1` for valid values under 80 (overlong ASCII) is preserved because the vectors exercise it; harmless on real input.
2. The 4-byte treatment of lead bytes F8 to FF is a quirk, kept because damaged input exists in practice (vectors cover it). A stricter decoder would change consumed lengths and fail the vectors.
3. Conservative by-one output check in the caption page (5.4.2) is odd but observable; the vectors pin it.
4. The W0 state spec wording is corrected in 3.9; no code change in the state module is needed.
