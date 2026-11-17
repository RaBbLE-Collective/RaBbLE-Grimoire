# w1-adpcm golden vectors

Behaviour data for `rabble_adpcm`, produced by compiling the original module on a host and calling it as listed. All files are raw: PCM and decoded output are 16-bit signed little-endian mono, ADPCM output is the packed byte stream (first sample of each pair in the low nibble). No headers. About 80 KB in total.

`manifest.tsv` is the machine-readable list (one row per case: op, input file, initial state, sample count `n`, output file, expected final state). The test vehicle in the spec reads it.

Call conventions used to make the data:

- `enc`: `rabble_adpcm_encode_block(&state, pcm, n, out)` with `state = {pred, index}` as in the manifest. `out` was `(n+1)/2` bytes, **prefilled with 0xAA**, and the whole buffer is the expected output file. An odd `n` therefore ends with an untouched 0xAA byte.
- `dec`: `rabble_adpcm_decode_block(&state, in, n, pcm)`. `pcm` held `n` samples **prefilled with 0x5A5A** and the whole buffer is the expected output. An odd `n` therefore ends with an untouched 0x5A5A sample (the file `randbytes_dec_odd.dec16` shows it).
- Every `*_dec` case decodes the matching `*_enc.adpcm` from state {0,0} and ends in the same final state as the encoder (the pair never drifts).
- `final_pred` / `final_index` in the manifest are the state struct after the call.

| File(s) | What it is |
|---|---|
| `silence.pcm` (800 samples) | all zeros; stays at state {0,0}, every code 0 |
| `sweep.pcm` (4000) | sine sweep 100 Hz to 7 kHz at 16 kHz sample rate, amplitude 16000 |
| `square_fs.pcm` (1600) | full-scale square, +32767 / -32768, half period 40 samples (hard clipping) |
| `noise.pcm` (2000) | uniform white noise over the whole int16 range |
| `speechlike.pcm` (2400) | 150 Hz tone, 3 Hz amplitude modulation, light noise |
| `alt_extreme.pcm` (640) | alternates +32767 / -32768 every sample (worst-case slew; both clamps hit) |
| `slow_ramp.pcm` (1500) | slow linear ramp, steps far below the minimum step size |
| `len1.pcm`, `len2.pcm`, `len4.pcm` | 1, 2, 4 samples; n=1 produces no output and no state change |
| `len5_odd.pcm`, `len321_odd.pcm` | odd lengths; the last sample is ignored |
| `<name>_enc.adpcm`, `<name>_dec.dec16` | encode from {0,0} and decode back from {0,0} |
| `sweep_enc_state`, `noise_enc_state_hi`, `noise_enc_state_lo` | encode from non-zero starts: {-5000,30} first 2000 samples; {32767,88}; {-32768,0} (both noise cases converge to the same final state) |
| `allbytes.bin` | bytes 0..255 twice; decoded as 1024 samples from {0,0}, {32767,88} and {-20000,60} (`allbytes_dec*`) to cover every code from extreme states |
| `randbytes.bin` | 1000 pseudo-random bytes; `randbytes_dec` decodes 2000 samples from {1000,40}; `randbytes_dec_odd` decodes n=7 from {0,0} (3 whole bytes consumed, sample 7 untouched) |
| `chunked_*` | the pre-roll usage: first 2240 samples of `speechlike.pcm`, encoded as 7 consecutive calls of 320 samples with the state carried across calls. `chunked_enc.adpcm` is the 7 outputs concatenated (160 bytes each); `chunked_starts.txt` is the state (`pred index`) held **before** each call; `chunked_dec.dec16` is each 160-byte chunk decoded alone from its own saved start state, concatenated. Final state after the 7th encode call is in the manifest row. |
