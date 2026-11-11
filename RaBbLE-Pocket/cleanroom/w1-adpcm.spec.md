# W1 spec: rabble_adpcm (4-bit ADPCM codec)

> Clean-room spec, wave W1. Author role: S. Files to be replaced: `apache/rabble_adpcm.c` and `apache/rabble_adpcm.h`. The new files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen. Golden data: `w1-adpcm-vectors/` (see its README and `manifest.tsv`).

## 1. Purpose

A small, pure, stateless-between-calls codec that squeezes 16-bit mono PCM to 4 bits per sample (4:1) and back, so the voice task can keep its pre-roll audio ring in a quarter of the RAM on boards without PSRAM. The module owns no memory, no task and no global state: every byte of codec state lives in a small struct that the caller owns and passes in.

## 2. Standard to implement from

Implement the well-known **IMA / DVI ADPCM** algorithm from the public standard (the IMA Digital Audio Focus Group recommendation, as documented in many public references). Its 89-entry step-size table and its 8-entry index-adjustment table are public data: take them from the standard, not from this repository. Everything below says where this module follows the standard's core and where it makes a choice the standard leaves open. The golden vectors decide any doubt: if your output differs by one byte, you differ from the module, not the other way round.

## 3. Public interface (complete and exact)

Header `rabble_adpcm.h`, `#pragma once`, including `<stddef.h>` and `<stdint.h>` only. `extern "C"` guards are allowed and harmless.

### 3.1 Type

`rabble_adpcm_t`, a struct typedef with exactly these members, in this order:

| Field | Type | Meaning |
|---|---|---|
| `pred` | `int16_t` | The predictor: the decoder's current reconstructed sample value. |
| `index` | `int8_t` | Position in the step-size table, valid range 0 to 88. |

Field names, types and order are part of the interface: tests build states with `{ pred, index }` and read the fields. Callers in the firmware never touch the fields (they only declare, zero-initialise, copy by value and pass the address), but they rely on the struct being **copyable by plain assignment** and **small** (it is embedded in every 20 ms pre-roll chunk). Do not add members. Two zeroed states (`{0,0}`, which is what a `static` object or `= {0}` gives) are the defined starting point.

### 3.2 Functions (2, no exported globals, no macros)

| Prototype | Summary |
|---|---|
| `void rabble_adpcm_encode_block(rabble_adpcm_t *s, const int16_t *pcm, size_t n, uint8_t *out);` | Encode `n` samples to `n/2` bytes, advancing `*s`. |
| `void rabble_adpcm_decode_block(rabble_adpcm_t *s, const uint8_t *in, size_t n, int16_t *pcm);` | Decode `n` samples from `n/2` bytes, advancing `*s`. |

Both return nothing and report no errors. In both, **`n` counts samples** (not bytes) for the PCM side.

### 3.3 Who uses what

Only `apache/rabble_voice.c` (voice task) includes the header. Total public names: 1 type, 2 functions.

| Use | Detail |
|---|---|
| Sample rate / chunking | 16 kHz mono (`RABBLE_AUDIO_RATE`), always calls with `n = RABBLE_AUDIO_CHUNK = 320` samples (20 ms) in, 160 bytes out. |
| Encoder object | one `static rabble_adpcm_t` in the voice module, zero at boot, never reset afterwards, continuous across all chunks (it keeps running while idle). |
| Per chunk | before encoding a chunk the caller copies the encoder state into the chunk record; then encodes the chunk. |
| Decoder | to read a chunk back, the caller copies that saved start state into a local, decodes the 160 bytes into 320 samples, and discards the state. So **a chunk must decode correctly alone from its saved start state** (section 4.5, rule 4). |
| When | only when the build is low-memory (`RABBLE_LOW_MEM == 1`, boards without PSRAM, ring of 16 chunks = 320 ms). On the current gadget (PSRAM) `RABBLE_LOW_MEM` is 0, so the calls compile out and the module is linked but idle. |
| Wire | not used on the beam today. The Beam Protocol only reserves codec byte 1 for ADPCM in a later version; if that happens the raw stream defined here has **no header and assumes a zero starting state** at the start of a turn. |

## 4. Behaviour

### 4.1 Format

1. Mono only. One 4-bit code per sample, no stereo, no interleave, no block or frame header, no sync word, no embedded predictor or index. The byte stream is pure codes.
2. **Nibble order:** within each byte the first sample of a pair is in the **low** nibble (bits 0 to 3) and the second sample in the **high** nibble (bits 4 to 7). Decoding mirrors this exactly.
3. **Code layout (the standard's):** bit 3 is the sign (1 = the sample is below the predictor), bits 0 to 2 are a 3-bit magnitude.
4. Compression is exactly 4:1: `n` samples (even) are `n/2` bytes.

### 4.2 The shared state update (the standard's)

One rule moves the state forward for a code, and **the encoder and decoder both use it**, which keeps them in lockstep:

1. Look up the step size for the current `index`.
2. Build the difference magnitude as one eighth of the step (integer shift, truncating), plus the whole step if magnitude bit 2 is set, plus half the step if bit 1 is set, plus a quarter of the step if bit 0 is set. Halves and quarters are integer shifts of the step (truncating), taken from the step, not from a running remainder.
3. Subtract that from the predictor if the sign bit is set, otherwise add it. Do the arithmetic in at least 32 bits, then **saturate** the result to the int16 range -32768..32767 and store it as the new `pred`.
4. Move `index` by the standard adjustment for the magnitude (magnitudes 0 to 3 decrease it by one; 4, 5, 6, 7 raise it by 2, 4, 6, 8) and **clamp** it to 0..88. The adjustment uses the magnitude only; the sign bit is ignored.

The decoder's output sample for a code is the new `pred` after this update. There is no smoothing, no dither, no rounding offset beyond what step 2 says.

### 4.3 Encoder (the standard's truncating quantiser)

For each sample, in order:

1. `diff = sample - pred` in at least 32-bit arithmetic (the range is -65535..65535, so it does not fit in 16 bits).
2. Sign: if `diff < 0` set bit 3 and use `-diff`; a difference of exactly zero is **positive** (sign bit clear).
3. Magnitude: compare against the current step size, then step/2, then step/4, in that order, each with `>=`. If the remaining difference is at least the step, set bit 2 and subtract the step; then if at least the (truncated) half step, set bit 1 and subtract it; then if at least the (truncated) quarter step, set bit 0. Quantisation is truncation, not rounding to nearest.
4. Apply the shared update (4.2) with the finished code, so the encoder's `*s` always equals what a decoder would hold after the same codes. Nothing else is stored.
5. Pack: the code of the first sample of a pair is the low nibble, the second the high nibble of byte `i/2`.

The encoder never looks at future samples and never searches.

### 4.4 Decoder

For each byte, extract the low nibble and apply the shared update (4.2); the result is the next output sample; then the high nibble, the same way. Output sample `i` and `i+1` come from byte `i/2`.

### 4.5 State across calls

1. The initial state is whatever the caller passes in. The module does not reset, validate-and-repair or remember anything between calls.
2. Calling with state carried over is exactly equivalent to one long call: encoding 320 samples then 320 more with the same state object gives the same bytes and the same final state as one 640-sample call. The same holds for decoding. (Pair boundaries must line up, so the split points are even; see 4.6.)
3. The state after a call is the state after the last **processed pair**.
4. **A chunk decodes alone:** decoding a chunk from a copy of the encoder state saved just before that chunk was encoded reproduces the same samples a continuous decoder would produce for that chunk. This is what pre-roll relies on, and it follows directly from rules 1 and 2.

### 4.6 Odd lengths and tiny inputs

1. Processing is by pairs. With odd `n` the **last sample is ignored**: the encoder writes `n/2` bytes (rounded down) and consumes `n - 1` samples; the decoder reads `n/2` bytes and writes `n - 1` samples. The caller's buffer cell for the missing sample is left **untouched** (the vectors prove it with sentinel fill: 0xAA in the output byte, 0x5A5A in the PCM sample), and the state does not advance for it.
2. `n = 0` and `n = 1` do nothing: no read of the buffers, no write, no state change. Null buffers are acceptable when `n < 2`.
3. A caller wanting every sample coded must pass an even count. Nothing pads, and nothing signals the dropped sample.
4. The module writes strictly within `n/2` output bytes (encode) or within the first `n - (n & 1)` samples (decode), and reads only inside `n` input samples / `n/2` input bytes.

### 4.7 Invalid input

1. `pred` is any int16 and works. `index` outside 0..88 is a caller bug (the original would index outside its table); your code may clamp it first or leave it undefined, and no vector tests it.
2. Null `s`, or null buffers with `n >= 2`: undefined; not tested.
3. Every possible nibble value is a legal code to the decoder, and every byte value a legal pair. Decoding garbage is safe and produces bounded output (the vectors `allbytes*` and `randbytes*` drive it through extremes, including both saturation limits and both index limits).
4. Overlapping in/out buffers are not supported.

### 4.8 Threading and limits

1. Reentrant: no globals, no statics other than constant tables. Safe to call from any task as long as no two calls share the same state object or output buffer at once. In practice only the voice task calls it.
2. Task context only, but there is no blocking and no allocation. Stack use is a few words. No logging.
3. Cost: roughly a handful of simple integer operations per sample, called once per 20 ms for 320 samples. Keep it table-driven and branch-light; it runs on the voice task next to the audio read loop. No floating point.
4. No size cap on `n` beyond `size_t`; loop indices must not overflow on large sizes.

### 4.9 Free choices (yours) versus pinned choices

Free: how you structure the code, helper names, whether the shared update is a function or inline, how you clamp (any equivalent form), internal types (as long as results are identical), whether to clamp a bad `index` defensively.

Pinned (all verified by the vectors): the low-nibble-first order; sign in bit 3; truncating shifts for step/8, step/2, step/4; diff-zero positive; magnitude test order and `>=`; saturating predictor; index adjustment by magnitude only and clamping 0..88; odd-length tail ignored and untouched; no header; mono; pair-wise state advance.

## 5. What the module may call

Only `<stddef.h>` and `<stdint.h>`. No ESP-IDF, no FreeRTOS, no other `rabble_*` module, no logging, no heap. It must compile on the host with plain gcc and on the Xtensa target without component dependencies.

## 6. Device checklist (integrator)

The shipping gadget has PSRAM, so its pre-roll uses plain PCM and never calls the codec. To exercise it on the device, build once with the low-memory switch forced on (`RABBLE_LOW_MEM` set to 1 in the seam's memory header, temporary and not committed), then:

1. Boot; idle for at least a second so the pre-roll ring is full (idle mic read is running; 16 chunks = 320 ms).
2. Press and hold to talk, saying a short sentence **starting speech slightly before the press registers** (begin the first word at the press). Release. The reply arrives and the heard-text caption includes the first word of the sentence, as it does with the PCM ring. (A broken codec shows up as a clipped or garbled first word, or as crackle or loud noise in the recording.)
3. Repeat five turns, including one right after the speaker has played a reply (the pre-roll is reset after playback and must refill cleanly, with the encoder state still running).
4. Voice quality: use the serial recording stats the voice task already logs; peak, clipped count and noise floor of the pre-roll part should be in line with the plain-PCM build (ADPCM adds mild quantisation noise but must not add clicks at chunk joins). A click at every 20 ms boundary means the saved start states are not honoured (rule 4.5.4).
5. No crash or stack overflow in the voice task; heap and the 60 fps / busy frame gates unchanged (the codec adds well under 1 ms per 20 ms chunk on the S3).
6. Switch the flag back to 0 and confirm the normal build is unaffected.

## 7. Test vehicle

A host harness with plain gcc under `RaBbLE-Pocket/firmware/test/cleanroom/w1/adpcm_test/`, no ESP-IDF, one `run.sh`, built with `-Wall -Wextra -Werror` and once with `-fsanitize=address,undefined`. The golden files are copied there next to the test.

Byte-exact cases (must match every golden file in `w1-adpcm-vectors/`, driven from `manifest.tsv`):

1. For each `enc` row: load the input PCM as little-endian int16 (write the file loader to be endian-explicit), allocate `(n+1)/2` output bytes **prefilled with 0xAA**, set the state to the row's start, call encode with the row's `n`, and compare the whole buffer to the expected file and the final state `{pred, index}` to the row.
2. For each `dec` row: input bytes from the file, output buffer of `n` int16 **prefilled with 0x5A5A**, same comparison.
3. The `chunked` row: encode the first 2240 samples of `speechlike.pcm` in 7 calls of 320 with the state carried; before each call compare the state with the matching line in `chunked_starts.txt`; the concatenated bytes equal `chunked_enc.adpcm`; the final state equals the manifest row. Then decode each 160-byte chunk alone, from its saved start state, into 320 samples, and the concatenation equals `chunked_dec.dec16`.

Property cases (not byte-exact):

4. One 640-sample call equals two 320-sample calls with state carried (bytes and state).
5. Encoder state equals decoder state after the same stream, for random input (1000 random seeds, random even lengths up to 2000).
6. `n = 0` and `n = 1` leave state and buffers untouched, with null buffers allowed.
7. Odd-`n` sentinel check for both directions (the 0xAA byte and the 0x5A5A sample survive), including `n = 3`.
8. With guard bytes around the output buffers (or ASan), nothing is written outside the first `n/2` bytes or first `n - (n&1)` samples.
9. Saturation: decode of `0x77` repeated from `{32767, 88}` never exceeds the int16 range and `index` stays 88; decode of `0xFF` repeated from `{-32768, 0}` stays at -32768; `0x00` repeated from `{0, 5}` drives `index` to 0 and never below.
10. Round trip sanity (sound check, not exact; this threshold and case 9 are the spec author's reasoning, not measured on the original: if one fails while every golden vector passes, report it rather than bend the code): a 440 Hz sine at amplitude 12000, encode then decode from `{0,0}`; after a 100-sample warm-up, the signal-to-error ratio is at least 25 dB.
11. Compile checks: header compiles as C11 and as C++17; `sizeof(rabble_adpcm_t) <= 4`; struct is copyable by assignment; `{0}` initialisation yields pred 0 and index 0.

## 8. Ambiguities and notes

1. The vectors were made from the original module on the host (gcc, x86-64). The module is pure integer arithmetic, so the Xtensa target gives the same bytes; the only target-dependent thing would be `>>` on negative numbers, which this module never does (it shifts only the non-negative step table values).
2. The struct has 1 byte of tail padding in practice, `sizeof` is 4. Not part of the contract but do not grow it.
3. The Beam Protocol's reserved ADPCM codec (byte 1) is not defined yet. If it is defined later, it must say whether the stream carries a start state; this module's raw stream does not. A third-party decoder of WAV-style IMA blocks would not decode it without supplying a zero start state.
4. Out-of-range `index` and null pointers are deliberately not pinned (4.7); no caller can trigger them.
5. `final_pred`/`final_index` in the manifest for the `*_dec` rows equal those of the matching `*_enc` rows by design, which is a cheap extra check that the two directions agree.
