# RaBbLE-Voice Phase 2 Handoff — Vocoder Implementation

**Session:** S189 (Foundation scaffold complete)  
**Date:** 2026-07-03  
**Status:** Phase 2 unblocked, ready to begin  
**Owner:** Mark McConachie  

---

## What You Have

**Foundation is complete and on-disk:**
- `RaBbLE-Xperimental/rablets/RaBbLE-Voice/` — full directory structure
- `src/types.ts` — unified SynthesisEngine interface (all three engines implement this)
- `src/index.ts` — factory functions (createVocoderEngine() is a stub waiting for implementation)
- `src/benchmark.ts` — shared measurement utilities
- `package.json` — build config ready to go
- `AGENT.md` — session checklist + phase breakdown
- `CONTEXT.md` — current state tracker
- `README.md` — rablet description

**Personality locked in Grimoire:**
- `RaBbLE/Ethos/RaBbLE-Personality.md` — canonical definition (6 poles, interaction, application)
- All three paths should reflect: curious, creative, playful, unbounded, chaotic (slightly), disagreeable, not sycophantic

**No git tracking:** RaBbLE-Xperimental is gitignored (active sandbox). Vocoder work happens on-disk; no commits until Phase 2 complete.

---

## Phase 2: Vocoder Implementation

### Goal

Build a working synth voice using Tone.js + Web Audio API. Browser-native, zero external dependencies. This validates the three-path architecture and gives Mark a voice to test.

### Why Vocoder First?

- Fastest path to validation (no external APIs, model downloads, or system dependencies)
- Browser-native (can test immediately in dev UI)
- Full creative control over phoneme, formant, effects
- Proof-of-concept that the SynthesisEngine interface works
- Can generate distinctive, opinionated voice (supports RaBbLE's personality)

### What to Build (In Order)

**1. `src/vocoder/vocoder-phonemes.ts`** (~1 day)
- IPA phoneme table: each phoneme maps to [pitch, duration, vowel_color]
- Simple text→phoneme lookup (rule-based, no ML)
- Example:
  ```typescript
  {
    'a': { pitch: 100, duration: 100, formant: 'open' },
    'e': { pitch: 110, duration: 100, formant: 'close' },
    // ... consonants with noise params
  }
  ```
- Emotion modification: curious emotion = +20% pitch, faster tempo; thoughtful = -20% pitch, slower

**2. `src/vocoder/vocoder-formants.ts`** (~1 day)
- Vowel resonance profiles (F1, F2, F3 frequencies)
- Biquad filter factory (using Web Audio API)
- Test: apply filters to buzz tone, verify frequency response
- Three formant filters per vowel (different "colors")

**3. `src/vocoder/vocoder-effects.ts`** (~1.5 days)
- Bit-crushing (8-bit, 12-bit, 16-bit) for digital artifacts
- Vocoder effect (modulate carrier through envelope)
- Pitch-shifting (using Tone.js Shifter)
- Saturation/warmth (soft clipping)
- Optional: granular effects for "processing" emotion

**4. `src/vocoder/vocoder-engine.ts`** (~2 days)
- Implement `SynthesisEngine` interface:
  ```typescript
  async speak(options: SpeakOptions): Promise<SynthesisResult>
  ```
- Synthesis loop:
  1. Parse text → phonemes
  2. Build timeline (when to play each phoneme)
  3. Generate carrier signal (buzz tone or noise per phoneme)
  4. Apply formant filters per vowel
  5. Layer effects (bit-crushing, vocoder, pitch shift)
  6. Apply emotion (pitch/tempo/effects envelope)
  7. Return AudioBuffer
- Emotion mapping:
  - curious: +20% pitch, 20% faster, clear formants
  - thoughtful: -20% pitch, 20% slower, sustained formants
  - processing: digital artifacts, stuttering, pitch wobble
  - alert: sharp attacks, high volume, pitch jumps
  - playful: pitch variation, breathy quality, micro-laughs
  - concerned: low volume, wavering pitch, held notes

**5. `tests/vocoder.test.ts`** (~1 day)
- Unit tests for phoneme parsing
- Formant filter correctness (frequency response shape)
- Effect chain (verify bit-crushing, vocoder behavior)
- Emotion parameter application
- Integration: speak() produces AudioBuffer with correct duration

**6. `src/ui/demo.html`** + `src/ui/voice-player.ts` (~1 day)
- Standalone HTML page (no build step needed)
- Text input field
- Emotion dropdown (curious/thoughtful/processing/alert/playful/concerned)
- Play button
- Waveform canvas (Canvas2D, simple visualization)
- Duration display

### Success Criteria

- ✅ `npm test` passes (all vocoder tests green)
- ✅ `npm run bench:vocoder` completes and shows reasonable latency (<500ms for short phrase)
- ✅ demo.html works in browser — can input text, select emotion, hear output
- ✅ Output sounds **distinctly non-human** but **intelligible** (goal: Johnny-5 character)
- ✅ Different emotions produce noticeably different voice characteristics
- ✅ Model size = 0 KB (all in-memory, pure JS)

### Known Gotchas

1. **Intelligibility vs. character tradeoff:** Pure synth phonemes may sound robotic. Tuning formants and duration will be iterative. Start with clarity; add artifacts for character.
2. **Tone.js version:** Make sure Tone.js Web Audio context is initialized before first speak(). Test early.
3. **Phoneme timing:** Consonants need short bursts; vowels need sustained carriers. Duration tuning is critical.
4. **Emotion orthogonality:** Emotions should not interfere with each other (applying "curious + playful" should work).
5. **Memory cleanup:** Ensure AudioBuffer/Oscillators are properly cleaned up (no leaks).

### File Checklist

```
RaBbLE-Xperimental/rablets/RaBbLE-Voice/
├── src/vocoder/
│   ├── vocoder-phonemes.ts      ← Build first
│   ├── vocoder-formants.ts      ← Build second
│   ├── vocoder-effects.ts       ← Build third
│   ├── vocoder-engine.ts        ← Build fourth (main engine)
│   ├── vocoder.bench.ts         ← Add after engine works
│   └── README.md                ← Update with phoneme spec
├── src/ui/
│   ├── demo.html                ← Standalone test page
│   ├── voice-player.ts          ← Player component
│   └── voice-ui.css             ← Aether palette styling
├── tests/
│   └── vocoder.test.ts          ← Unit tests
└── CONTEXT.md                   ← Update: mark Vocoder READY when complete
```

### Session Workflow

```bash
cd RaBbLE-Xperimental/rablets/RaBbLE-Voice

# Install and build
npm install
npm run build:watch    # Watch changes in one terminal

# In another terminal: test-driven development
npm run test:watch     # Watch tests, re-run on change

# Develop:
# 1. Write test case in tests/vocoder.test.ts
# 2. Implement in src/vocoder/*.ts
# 3. Tests auto-run and show pass/fail
# 4. Once tests pass, manual test in browser:
#    npm run build
#    open src/ui/demo.html in browser

# When Phase 2 complete:
# Update CONTEXT.md: status = "Phase 2 Complete, Phase 3 Unblocked"
```

### What Mark Needs to Decide

After Phase 2 works, Mark should listen to vocoder output and answer:

1. **Intelligibility:** Can you understand the words? (1-5 scale)
2. **Character:** Does it sound like an opinionated entity? (1-5 scale)
3. **Emotions:** Do the 6 emotions come through? Which work best?
4. **Quality:** Overall, does vocoder feel like a viable choice? Or should we wait for Bark/Festival?

This feedback informs whether to ship Vocoder, continue to Phase 3/4, or pivot the architecture.

### References

- **Personality guide:** `RaBbLE-Grimoire/RaBbLE/Ethos/RaBbLE-Personality.md` — apply throughout
- **Type contract:** `src/types.ts` — SynthesisEngine interface
- **Tone.js docs:** https://tonejs.github.io/ (Synth, Oscillator, Biquad, Shifter)
- **Web Audio API:** https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
- **Formant frequencies:** https://en.wikipedia.org/wiki/Formant (reference table)
- **IPA Phonetics:** https://en.wikipedia.org/wiki/Help:IPA

### If You Get Stuck

1. **Phonemes don't sound right?** Formant tuning is the lever. Adjust F1/F2/F3 per vowel.
2. **Emotions not distinct enough?** Increase pitch range (curious +30%, thoughtful -30%), tempo changes (curious 1.2×, thoughtful 0.8×).
3. **Memory leaks?** Check that Oscillators are `.stop()` and disconnected after speak().
4. **Intelligibility too low?** Simplify first (pure formants, no bit-crushing); add effects incrementally.
5. **Tests failing?** Check Tone.js Web Audio context is initialized; ensure AudioBuffer duration is correct.

### Exit Criteria (Phase 2 → Phase 3)

- [ ] All tests pass (`npm test`)
- [ ] Benchmarks run without error (`npm run bench:vocoder`)
- [ ] demo.html works in browser (text input, emotion select, play button)
- [ ] You can listen to output and judge intelligibility/character
- [ ] CONTEXT.md updated with Vocoder status
- [ ] Phase 3 (Festival) unblocked

---

**Handoff date:** 2026-07-03  
**Expected completion:** ~1 week (5–7 days of focused development)  
**Questions?** Refer to `AGENT.md` (session checklist) or `CONTEXT.md` (current phase, blockers, unknowns).
