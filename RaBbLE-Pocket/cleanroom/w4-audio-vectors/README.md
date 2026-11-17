# w4-audio golden vectors

Behaviour data for `rabble_audio` (W4). Recorded on a host against a fake codec, board and settings. Inputs are in `inputs/`, expected outputs in `expected/`. All PCM files are raw 16-bit signed little-endian, no header. `*.s16` are interleaved stereo (L,R,L,R...); `*.pcm` are mono.

Compare rules: PCM outputs from `read` must match within +-1 LSB per sample (float rounding); chirp outputs within +-2 LSB; dBFS values within 0.01 dB; level values within 0.001; selftest and loopback logs: same line structure and strings, numbers within 0.1 (dBFS) or exact (integers, Hz after rounding).

## metrics.tsv
Columns: `case`, `frames`, `dbfs`, `level`. Input for each case is `inputs/<case>.pcm` (the `empty` row has no file: zero frames). The test passes the buffer to the dBFS and level functions and compares.

## read.tsv
One row per scenario. Columns: `case`, `mic_slot` (board value in force), `input` (stereo file in `inputs/` fed to the fake mic codec, consumed sequentially, one interleaved sample per 2 bytes), `calls_frames` (comma list: successive read calls with this many mono frames, on one fresh module instance after init), `fail_after_reads` (-1 never; N: the fake codec read fails from the (N+1)th read call after init on), `output` (file in `expected/`: the concatenation of the caller buffers after all calls, buffers prefilled with 0x5A5A before each scenario, so untouched samples show 0x5A5A), `ret_codes` (return value per call, 0 = ok, -1 = failure), `codec_read_bytes` (the byte size of each codec read, in order). The high-pass state starts at zero at the beginning of every scenario.

## write.tsv
Columns: `case`, `speaker_on` (setting), `input` (mono file), `calls_frames`, `fail_after_writes` (as for reads), `output_stereo` (what reached the fake speaker codec when the output was active, interleaved), `ret_codes`, `codec_write_bytes` (bytes per codec transfer, in order). Zero-frame calls transfer nothing. The files describe the sample stream and its chunking only: they say nothing about when the output stage is powered (see the spec, section 6.5).

## chirp.tsv
Columns: `case`, `rising`, `speaker_on`, `output_stereo`, `codec_writes`, `frames`. Output is the stereo stream (both slots equal; all zeros when the speaker setting is off).

## lifecycle.tsv
Columns: `scenario`, `kind` (`call` codec/board call seen by the fake, `log` info log line, `step` scenario marker, `ret` return value), `detail`. Scenarios exercise init, failure paths, power cycling and setters. **Spec sections 6.2, 6.3 and 6.5 override these rows where they differ; compare only:** mic open and close, board gain calls, log text, return codes. **Ignore:** rows mentioning `open spk`, `close spk` or `set_out_vol spk` (speaker timing is 6.5), rows about the `i2s_common` log level (6.2 states the outcome, not a mechanism), and the setter values where 6.3 now clamps (in-range values are unchanged).

## expected/selftest_nominal.log, expected/selftest_slow.log
Console output of the self-test with the fake mic fed from `inputs/selftest_src.s16` (L: 1 kHz amplitude 3000 plus offset 100 plus small noise; R: half of L plus small noise) and a fake clock that advances 20 ms (nominal) or 22 ms (slow) per 20 ms codec transfer, mic gain setting 30. The `log` lines are the two self-test lines. The `count` line gives the number of codec reads and writes: 38 each.

## expected/loopback_*.log
Console output of the loopback test with a fake codec that echoes the speaker data to both mic slots two chunks late, scaled by 10^(gain/20) times 0.3 (first file, volume argument 60) or times 1.0 (second, volume 100), clipped to 16 bits. Settings in force: volume 55, mic gain 24. The `count` line gives the number of codec reads and writes: 1440 each.
