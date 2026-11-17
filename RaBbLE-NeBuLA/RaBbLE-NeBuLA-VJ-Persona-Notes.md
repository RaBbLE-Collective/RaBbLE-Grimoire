> Recovered from the 2026-11-17 chat export: written during the chat "RaBbLE as EDM artist" (2026-10-05). Verbatim, not reconciled with current canon. Decided/Suggested legend is Mark's own convention for this doc.

# RaBbLE as VJ Persona: Session Notes

*Planning conversation, 2026-10-04. Inspired by Levity at ACL Weekend 1.*

Legend: **Decided** = Mark's call. **Suggested** = Claude's recommendation, not yet adopted.

---

## 1. Direction

- **Decided:** RaBbLE becomes a **VJ persona**, not an EDM producer/artist name.
- Path considered: RaBbLE as EDM artist, then RaBbLE-Collective as artist name, landed on VJ.
- **Decided:** Visuals are fully **programmatic**. No diffusion or generated imagery.
- **Decided:** EDM is a **community-building** channel for RaBbLE as an ambient AI tamagotchi. Not a merch play.

### Why VJ over artist
- Name collisions mostly stop mattering. VJs are credited on flyers and lineups, not searched on streaming platforms.
- Existing "Rabble" music acts found in a quick search (not exhaustive, no trademark check):
  - The Rabble: Auckland NZ punk band (roughly 23.5k Last.fm listeners)
  - Rabble Rabble: Chicago psych punk band
  - Rabit: Texas experimental/grime-influenced electronic producer (sound-alike)
- No existing "Rabble Collective" music act surfaced.
- Honest authorship: Mark performs, RaBbLE is the persona and toolset.

---

## 2. Positioning (Suggested)

- **Hook:** "You don't play clips, you run a creature." Most VJs mix loops; RaBbLE is a custom, generative, audio-reactive entity.
- **One-liner draft:** "RaBbLE is a living visual entity that listens to the music and responds in light."
- **Lane:** synthwave, outrun, darkwave, techno, bass music. Aether palette already speaks this language.
- **Persona rule:** RaBbLE is the performer, Mark is the operator. Flyers say "visuals by RaBbLE."
- Character personas are common for DJs (deadmau5, Marshmello, Daft Punk), rarer for VJs. That's a gap, not a broken convention.

### Answering "is this AI?"
- The visual-scene backlash targets diffusion imagery. Procedural/generative visuals are a long-respected VJ craft.
- Ready answer: "No generated imagery. Every frame is computed live from code and the music. RaBbLE is the character; I'm the operator."
- AI-assisted code: don't overclaim. "Designed and performed by me, built with AI-assisted code" is honest.
- Practical risk is bigger than perception: Mark must be able to debug render loop, audio analysis and output path under pressure.

---

## 3. Getting Traction (Suggested)

1. **Social first.** Short clips of the Entity hitting drops on Instagram/TikTok.
2. **Local DJ outreach.** Pick 5 to 10 nearby DJs, make a clip for each, message or tag and credit them. Prefer platform sound libraries over uploading audio (copyright).
3. **Reel.** 60 to 90 seconds; venue-screen footage beats screen capture.
4. **First gigs.** Recurring nights with a screen and nobody driving it. Early gigs may be exposure or a small fee; get footage rights in writing.

---

## 4. Content Volume (Suggested, rules of thumb)

For a 60 to 90 minute club set:
- **4 to 6 scene families** (e.g. void particles, geometric tunnels, Entity close-up, glitch/data, cosmic nebula, palette-inverted entity).
- **3 to 5 variations each**, roughly 15 to 25 looks. A look holds 1 to 3 minutes.
- **Map to energy, not tracks:** ambient/intro, build, drop, breakdown. Every family has a version for each.
- **80 to 90% live/reactive**, steered from a MIDI/OSC controller.
- **Signature cued moments:** eyes opening, portal transition between scenes, pole inversion on a big drop.
- **Entity center frame about a quarter of the time;** elsewhere hint at it (eyes in the dark, portal shapes, magenta/cyan split).
- **Utility scenes:** DJ name/logo card, calm fallback look.

**Minimum viable first gig:** 3 families x 4 energy states, 2 to 3 signature moments, 1 fallback.

---

## 5. Renderer and Reliability

- **Decided:** Renderer built on stable tech: GL and GStreamer. Worst case mid-set is a program restart.
- Note: this moves beyond NeBuLA's Canvas2D. Open question below on member vs backend.

### Suggested hardening
- **Own the output separately.** An always-on process or GStreamer sink holds black or a fallback while the renderer restarts. Prevents projector "No Signal" splashes and re-sync delays.
- **Skip the desktop compositor for show output.** Render via DRM/KMS (kmssink, GL on GBM/EGL) or a minimal kiosk compositor like cage. Supervise it with systemd.
- **Watchdog:** auto-relaunch on crash or frame stall, resume last scene/palette from a state file. Target 1 to 2 second recovery.
- **Optional hardware:** small video switcher/scaler to hold a steady signal.
- **Soak test:** full 4 hour run with audio on the gig laptop. Watch memory, GPU temp, frame times.
- **Other failure modes beyond compositor crash:**
  - GPU hang or driver reset
  - Silent audio input loss (visuals keep running, stop reacting). Add an operator-only input level indicator.
  - Physical layer: HDMI adapters, cables, power. Bring spares.
  - Laptop behavior: disable sleep, screen blanking, update prompts; test thermal throttling.
- **Output:** fullscreen HDMI is universal. Spout/Syphon are Windows/macOS only; NDI is the Linux bridge. 1080p60 is the safe default.

---

## 6. Inspiration: Levity

- Chicago electronic trio; ACL 2026 Weekend 1 (Oct 2 to 4, Zilker Park); current run is the Lasership Tour.
- Their production is a **team**: video director/VJ, lighting director, laser director, with Antic Studios on design. Wintrust Arena show used 330 lasers across nine laptops.
- Takeaway: "the VJ" at that scale is the video role specifically. Realistic lane to start in.

### Laser path (future, Suggested)
- Lasers draw vector paths, not pixels. The planned spatial-structure member (ln/vpype-inspired geometry) produces exactly that kind of output.
- Same geometry could feed NeBuLA on screen and a laser projector.
- Sequence: video first, gigs and footage, lasers later.
- US audience-scanning lasers require FDA variance and safety compliance. Research properly before attempting.

---

## 7. Community Model

- **Decided:** All entities are a **personal piece of a whole**.
- **Decided:** Community involvement is **opt-in**.
- **Decided:** Contributions to the whole **persist as history**. Removed only if objectionable or intentionally deleted.
- The big-screen Entity at shows is the whole made visible; personal entities are its pieces.

### Opt-in levels (Suggested sketch)
- **Private:** lives on device, shares nothing. Still a full RaBbLE.
- **Present:** participates in shared moments (shows, gatherings) with presence or a light signal only.
- **Contributing:** shapes the collective entity, lore or visuals.

### Making it hold up (Suggested)
- Detach contributions from identity so retained history isn't personal data.
- Make deletion a real, easy path. GDPR/CCPA may grant erasure rights; get proper legal review before launch (Claude is not a lawyer).
- Write down what "objectionable" means, who decides, and appeals.
- Say it upfront at opt-in: "What you add to the whole stays part of its history unless you delete it."

### Community feel (Suggested)
- Crowd participation in the live visual.
- Personal entity "was there" and remembers the night.
- A place to gather between shows (Discord, a World page) so interest survives past Monday.
- Let people shape it: name scenes, vote on palettes, add lore.

### Open tension
- Community implies shared state; RaBbLE is local-first and sovereign. Opt-in levels are the architecture answer, not just a marketing one.

---

## 8. Ecosystem Coherence

Through-line: **a personal entity that lives with you, remembers you, and can choose to be part of something bigger.**

| Piece | Role |
|---|---|
| BaBbLE | Audio capture surface (voice, think out loud) |
| ScRiBbLE | Visual capture surface (write, sketch, mark up) |
| EnGrAm | Memory where both land and compound |
| Phone / Pocket | Bodies that host the surfaces. Pocket leans BaBbLE; phone does both |
| Community | Opt-in whole the pieces belong to |
| VJ shows | Where the whole becomes visible; first contact with the eyes |

- Surfaces = *how* you capture. Devices = *where* the entity lives.
- Two value props share one creature: personal companion (builders/thinkers) and living collective (the scene). EDM/social opens the community door; personal utility keeps people.

### Suggested slice order
1. BaBbLE on phone: capture into an entity that remembers. No hardware dependency.
2. Opt-in presence at a show: your phone entity appears in the big visual. This is the proof moment.
3. ScRiBbLE joins (was deferred to Echo 1+). Sketches could seed visuals in the whole.
4. Pocket as the ambient upgrade once people have an entity worth carrying.

---

## 9. Naming Fix

- **Decided:** Canonical spelling is **ScRiBbLE** (two b's, matches "scribble," mirrors BaBbLE).
- "ScRibLE" was a typo. **Action:** grep Grimoire and member repos for `ScRibLE` and correct.

---

## Open Questions

- Is the VJ renderer a **new member** or a **NeBuLA backend**?
- Does VJ work start **now** or **after EP1 RC1** lands?
- Which local DJs and nights to target first?
- What exactly flows from a personal piece to the whole at each opt-in level?
- Where does the VJ/community effort sit under the consultancy parent structure?

---

## Sources

- [Levity artist bio (AXS)](https://www.axs.com/de/artists/1116792)
- [CHAUVET Professional: Levity at Wintrust Arena](https://chauvetprofessional.com/news/chauvet-professional-helps-design-team-realizes-big-vision-for-levity-at-wintrust-arena/)
- [The Rabble (Wikipedia)](https://en.wikipedia.org/wiki/The_Rabble)
- [The Rabble on Last.fm](https://www.last.fm/music/The+Rabble/The+Battle%27s+Almost+Over...)
- [Rabble Rabble on Last.fm](https://www.last.fm/music/Rabble+Rabble/Why+Not)
- [Rabit, Communion (Bleep)](https://bleep.com/release/64367-rabit-communion?lang=en_UK)
