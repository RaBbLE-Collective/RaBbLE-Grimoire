# NeBuLA entity vocabulary: names across the Collective (read-only survey, 2026-11-18)

Paths are relative to `/home/rabble/RaBbLE-Collective/`. "Spec" = `RaBbLE-Grimoire/log/plans/Unified-Entity/Unified-Entity-Puppet-Spec.md`. "Canon" = `.../Unified-Entity-Canon.md`. "Seed" = parked pose value, not canon (spec ruling 9). "Alias" names the canonical term.

## 1. Vocabulary table

| name | kind | surface | file:line | notes |
|---|---|---|---|---|
| calm | expression (emotion) | Grimoire spec, web NeBuLA, Pocket, TUI, World | `RaBbLE-NeBuLA/src/backends/alive-backend.js:207-208` (EXPR, EMOTIONS); `RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c:125` (F_CALM); `RaBbLE-sCoRE/tui/rabble-face/src/face.rs:65`; `RaBbLE-sCoRE/ui/face.py:47` | Idle baseline, zero offsets. Only expression on the live body today (Canon 7). Also `RaBbLE-Grimoire/log/plans/Unified-Entity/live/live.js:5-7` (ORDER=['calm']). |
| joy | expression (emotion) | Spec, web, Pocket, TUI (Rust enum has no Joy-driven Mood) | `alive-backend.js:209`; `scene.c:126` (F_JOY); `face.rs:66`; `face.py:48`; spec 10.1 `"joy"` block | Seed. Portal rises into orb (crescent). Pocket reaches it only via input `happy` (`RaBbLE-Pocket/firmware/entities/RaBbLE/src/rabble_input.c:611`). Spec ruling 38: wanted, not canon. |
| sad | expression (emotion) | Spec, web, Pocket, TUI, mock | `alive-backend.js:212`; `scene.c:127` (F_SAD); `face.rs:54` (Expr::Sad), `face.rs:67`; `face.py:50`, `face.py:851` (`error` -> sad) | Seed. Pocket state `NL_STATE_ERROR` maps to sad (`scene.c:617`, `W_SAD`). TUI Mood `error` -> sad (`face.py:851`). Spec 10.1 surfaces.pocket.state_map. |
| angry | expression (emotion) | Spec, web, TUI, mock | `alive-backend.js:213`; `face.rs:68`; `face.py:52`; `face.py:852` (`denied` -> angry, 2 s then idle, `DENIED_SECONDS` 2.0 at `face.py:853`) | Seed. Portals clamp onto eyes (no-touch failure, spec 3.5 table). No Pocket mapping (spec 4.x table: "(none)"). |
| listening | state (interaction) | Spec, web, Pocket, TUI, mock, World | `alive-backend.js:66` (ALIVE_STATES), `alive-backend.js:214` (EXPR.listening pose), `alive-backend.js:1144`; `scene.c:133` (W_LISTEN), `scene.c:614`; `nebula_lite.h:29` (NL_STATE_LISTEN); `face.rs:69` (Expr::Listening); `face.py:54`, `face.py:848` (typing -> listening) | Pose is the retired +-252 pose in web/TUI (spec ruling 5, Canon 8). Pocket uses candidate A (`dy +-40`, `scene.c:128`). Alias of TUI Mood `typing`. |
| speaking | state (interaction) | Spec, web, Pocket, TUI, mock, World | `alive-backend.js:67`, `:215`, `:1145`; `scene.c:133` (W_SPEAK), `:616`; `nebula_lite.h:29` (NL_STATE_SPEAK); `face.rs:70`; `face.py:55`, `face.py:849` (streaming -> speaking); World `RaBbLE-World/world/js/RaBbLE-account.js:424`, `RaBbLE-catalog-page.js:10`, `RaBbLE-stage.js` | Pose seed `dy +-44`. Alias of TUI Mood `streaming`. Spec ruling 10: interior effect unset. |
| thinking | state (legacy alias) | web NeBuLA, World, canvas2d | `alive-backend.js:132`, `:1141` (thinking -> idle + mood process), `:1216`; `core/animation.js:9` (STATE_ENTROPY); `backends/canvas2d/index.js:263`; `threejs-backend.js:789`; `RaBbLE-World/world/js/RaBbLE-stage.js:88` (`setEntityState('thinking')`); `RaBbLE-World/world/js/RaBbLE-dock.js:101` | Legacy alias. Not a state: it resolves to mood `process`. Spec 4 table: "alias: thinking -> mood process". Pocket has no thinking name; it is `NL_STATE_THINK` (`nebula_lite.h:29`). |
| idle | state | all surfaces | `alive-backend.js:66`, `:120` (stateS), `:121` (moodS); `scene.c` (NL_STATE_IDLE, `nebula_lite.h:29`); `face.rs:Mood::Idle` (`driver.rs:85-99`); `face.py:847`; World `RaBbLE-face.js:93` (idle -> label RESONANT), `RaBbLE-face.js:357`, `RaBbLE-stage.js:110` | Interaction-state idle, not the same as calm (emotion). Overloaded: NeBuLA also uses `idle` for `mode` (`element.js:21`), `eye-behavior`, `doors` and `graph`. |
| resonant | condition (system) | World label, doors element | `RaBbLE-World/world/js/RaBbLE-face.js:93` (`state === 'idle' ? 'resonant'`); `RaBbLE-NeBuLA/src/elements/doors.js:16,30,215` | Alias of idle in World's statusbar label (`%RESONANT%`). Also in Identity (see row below). doors.js `'resonant'` is a separate entity-state value. |
| glitch | condition (system) | doors element | `RaBbLE-NeBuLA/src/elements/doors.js:16,30,170` (`glitching = _entityState==='glitch'`), `:215` | Only in doors.js. Not in the alive backend. Identity `%GLITCH%` (`RaBbLE-Agent/RaBbLE-Identity.md:281`). Canon 9.5 proposes a condition layer mapping glitch = mood plus aura; not implemented. |
| dormant | condition (system) | Identity only | `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Identity.md:273` | Parked seed. No surface references it. Canon 9.5 proposes dormant = eyes receded. |
| initializing | condition (system) | Identity only | `RaBbLE-Identity.md:275` (%INITIALIZING%) | Parked seed. Nothing renders it. |
| calibrating | condition (system) | Identity only | `RaBbLE-Identity.md:277` (%CALIBRATING%) | Parked seed. |
| system drift (%SYSTEM_DRIFT%) | condition (system) | Identity only | `RaBbLE-Identity.md:203, 264, 285` | Parked seed. Canon 9.5 proposes dimmed. No code reference. |
| resonant (%RESONANT%) | condition (system) | Identity only | `RaBbLE-Identity.md:279, 283` | Identity name for normal operating state. Surface name is `resonant` (World label) and `idle` (setState). Alias. |
| genius resonance (%GENIUS_RESONANCE%) | condition (system) | Identity only | `RaBbLE-Identity.md:106, 287` | Peak state, emergent insight. Parked seed. Closest surface term: mood `insight`. |
| null void (%NULL_VOID%) | condition (system) | Identity only | `RaBbLE-Identity.md:73, 286` | Critical failure, restart required. Parked seed. No surface. |
| curious | mood (temperament/pointer) | web NeBuLA, Pocket mock, TUI (no pose) | `alive-backend.js:67` (ALIVE_MOODS), `:127` (moodS curious), `:1130-1131` (pointer-driven enter); `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html:743`; spec 4 table (row "curious") | Canon 9.2 and ruling 6: curious is temperament, not an expression. Spec: no pose on any surface (gap). Pocket firmware has no curious name (`touch`, `happy` are the noticing triggers, spec 4.4). |
| ponder | mood | web, Pocket, TUI (not on TUI), mock | `alive-backend.js:68` (ALIVE_MOODS), `:124`, `:1134`; `scene.c:132` (W_PONDER), `:615` (NL_STATE_THINK first 1.5 s), `scene.c:130` (F_PONDER); mock `rabble-pocket-entity.html:86` | Additive offsets (gx 14, gy -9, tilt 5, squint 0.22). Pocket derives it from THINK time, not a named state. |
| process | mood | web, Pocket, TUI, World, mock | `alive-backend.js:68`, `:125`, `:1135`, `:1141`; `scene.c:132` (W_PROCESS), `:615`; `RaBbLE-World/world/js/RaBbLE-account.js:405` (setMood process); TUI Mood `working` (`face.py:850`) | Alias for legacy `thinking`. Pocket: THINK after 1.5 s (`F_PROCESS`). TUI maps `working` to Calm with 2.5x saccades (spec 4 table), not to process. |
| insight | mood | web, mock (not in Pocket firmware) | `alive-backend.js:68`, `:126`, `:1128`; mock `rabble-pocket-entity.html:80-81` ("insight burst at 8") | Events: widen, flash, rings, blink at 1.3 s. Spec: no pose anywhere (gap). |
| ponder/process/insight/curious/idle | mood set | Spec 4 mood table | `RaBbLE-Grimoire/log/plans/Unified-Entity/Unified-Entity-Puppet-Spec.md:319-328` | The mood table in the spec is the canonical list. |
| sleep | setting (not a state) | Pocket | `RaBbLE-Pocket/firmware/entities/RaBbLE/src/rabble_setup.c:59` (I_SLEEP, 0-3600) | Name collision: a timeout setting, not an entity expression. No "sleep" pose exists. |
| power_off | setting (not a state) | Pocket | `rabble_setup.c:60` | Same. Not an expression. |
| OFF | state | Pocket | `RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/include/nebula_lite.h:29` (NL_STATE_OFF); `scene.c:630` | Fades portals and rest. Pocket only. Not in alive-backend. |
| error (TUI Mood) | mood (TUI) | TUI | `RaBbLE-sCoRE/tui/rabble-face/src/driver.rs:103`; `face.py:851` | Maps to expression `sad`. Alias of Pocket `NL_STATE_ERROR`. |
| denied (TUI Mood) | mood (TUI) | TUI | `driver.rs:104`; `face.py:852-853` | Maps to `angry`, reverts to idle after 2.0 s. Pocket: no equivalent. |
| typing (TUI Mood) | mood (TUI) | TUI | `driver.rs:100`; `face.py:848` | Maps to listening. Alias. |
| streaming (TUI Mood) | mood (TUI) | TUI | `driver.rs:101`; `face.py:849` | Maps to speaking. Alias. |
| working (TUI Mood) | mood (TUI) | TUI | `driver.rs:102`; `face.py:850` | Maps to calm with 2.5x saccade speed (`face.py:850`). Spec says process should be the target. |
| Expr enum (TUI) | enum | TUI | `RaBbLE-sCoRE/tui/rabble-face/src/face.rs:51-58` | Calm, Joy, Sad, Angry, Listening, Speaking. Six members. Mirrors `ALIVE_EMOTIONS` plus two states. |
| Mood enum (TUI) | enum | TUI | `RaBbLE-sCoRE/tui/rabble-face/src/driver.rs:85-90` | Idle, Typing, Streaming, Working, Error, Denied. Six members. Names are not the same as the Expr enum. |
| W_CALM / W_LISTEN / W_PONDER / W_PROCESS / W_SPEAK / W_JOY / W_SAD | enum (weights) | Pocket | `RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c:133` | Pocket blend weights. Angry has no W_ slot (spec: angry not on Pocket). |
| NL_STATE_IDLE / LISTEN / THINK / SPEAK / ERROR / OFF | enum (states) | Pocket | `RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/include/nebula_lite.h:29` | Pocket state enum. Mapped in `scene.c:612-617`. Names differ from web (`listening`, `thinking`, `speaking`). |
| F_CALM / F_JOY / F_SAD / F_LISTEN / F_SPEAK / F_PONDER / F_PROCESS | pose (seed table) | Pocket | `scene.c:125-131` (F_CALM 125, F_JOY 126, F_SAD 127, F_LISTEN 128, F_SPEAK 129, F_PONDER 130, F_PROCESS 131) | Seed values generated from web tables (spec 10.2 generator writes between `// <registry:joy>` markers). Not canon. |
| FORMS (Rest (home), Mirror) | form | Grimoire live rig | `RaBbLE-Grimoire/log/plans/Unified-Entity/live/live.js:3` | Only 2 forms named. Spec 4.1 has four (see next rows). Canon 9.1 flags the mismatch. Rest = `ER|PL`, Mirror = `ER|PR`. |
| Rest (home) | form | Spec, live.js, World via NeBuLA | Spec `Unified-Entity-Puppet-Spec.md:202` (word `0110`); `live.js:3`; Canon 4 | Default rest. Spec ruling 3. |
| Swap | form | Spec | Spec `:203` (word `1010`) | Also called "the Ball form" in spec. Canon 9.1: name it once. Not in live.js FORMS (dropped from the live body, ruling 22). |
| Mirror | form | Spec, live.js | Spec `:204` (word `0101`); `live.js:3` | Rest with portals below. |
| Swap-Mirror | form | Spec | Spec `:205` (word `1001`) | Named in spec only. |
| unstable word 0000 "cold, very sad" | form (working name) | Spec, WORKING table | Spec `:208`; `live.js:4` (`WORKING={0:'cold, very sad'...}`) | Builder working name. Not a canonical pose. |
| unstable word 1111 "angry, alarmed" | form (working name) | Spec, WORKING table | Spec `:208`; `live.js:4` (15:'angry, alarmed') | Same. Note `live.js` keys are decimal (0,3,12,15), spec uses 4-bit strings. |
| "odd state" 0011 and 1100 | form (working name) | Spec, WORKING table | Spec `:208`; `live.js:4` (3:'odd state', 12:'odd state?') | Unnamed in spec. |
| turn | move | Spec, live.js | Spec `:36` (Canon 4 table "Turn"), ruling 15 (`Unified-Entity-Puppet-Spec.md:30`); `live.js` `rotMode='spin'` (line 15) | Whole-face yaw half-turn. Reaches all four rests with portal flip (Canon 4). |
| portal swap / withdraw-swap / swap move | move | Spec, Pocket, live.js | Spec `:38` (ruling 24, 1.45 s smootherstep), `:233` (as built `scene.c:689-714, 767-770`), `:216`; Canon 4 table | Recede, move, emerge. Pocket's withdraw curve: `w = sin(pi*fl)`, eye height `1 - 0.97*w` (spec `:239`). Canon 9.3: old 0.95 s / 0.7 s timings are stale. |
| flip (portal flip) | move | Spec | Spec `:238` (portal path), `:231` (Mirror), Canon 9.1 | Portal changes which side is on top. Canon 4 treats flip + turn as the two moves. |
| blink | move | Spec, web, Pocket | Spec Canon 4 table; `alive-backend.js:804`; `alive-backend.js:816` (eye.blinkT); `graph.js:322-330` and `floor.js:387-396` (blinkPhase `idle/closing/opening`, separate) | "Same squash toward the portal." Eyes hide only by receding (spec 7.3, ruling 12). |
| withdraw (eye hide) | move | Spec, Pocket | Spec `:239`, `:169` ("withdraw and hide are expressed only as a recede") | Name for the recede step inside portal swap. `hide` also named in spec but not defined separately. |
| hide | move (named, undefined) | Spec | Spec `:169`, `:216` | Spec says eyes hide by receding. No separate hide move exists in code. Alias for withdraw. |
| shock | timeline event | web | `alive-backend.js:197` (BOOT.shock 9.6 s), `:729` (`boot.sf`, setExpr joy 2.4) | Boot event, sets joy briefly. Spec 4.4 table lists "poke x4, shock" as disturbance triggers. |
| BOOT timeline (grid, motes, sphere, portalArc, eyeRise, blinks, mesh, lens, orbit, bokeh, logStart, logEnd, ready, slide, shock, idle) | timeline | web | `RaBbLE-NeBuLA/src/backends/alive-backend.js:196-197` | Named phases, seconds: ready 7.4, slide 7.6-9.8, shock 9.6, idle 10.2. Boot-only; not an expression. |
| mock timeline: listen / think / ponder / process / insight burst / speak / joy / back to listen | timeline | Pocket mock | `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html:80-82` (listen 0-4, think 4-8, insight at 8, speak 8-12.5, joy 12.5-15.4) | Demo timeline only. Names match Pocket state set. |
| poke | event | web | `alive-backend.js:774` (`mind.pokes`), spec 4.4 ("poke x4") | Triggers angry at 4 pokes (`alive-backend.js:774`). |
| happy (input) | event | Pocket | `RaBbLE-Pocket/firmware/entities/RaBbLE/src/rabble_input.c:611` | Input name that drives joy on Pocket (spec 4.4 "happy" as noticing trigger). |
| touch | event | Pocket | spec 4.4 table ("noticing: touch, happy") | Pocket input name, not verified in firmware grep. |
| dizzy | event | Pocket | spec 4.4 table ("disturbance: dizzy") | Named in spec only; not found in firmware grep. Treat as unverified. |
| Identity states table | condition | Identity | `RaBbLE-Identity.md:273-287` | See rows above for each name. |
| %NULL_VOID% / %CHARACTER_LOCK% / %STABLE% / %MEMORY_ONLINE% / %PATH% / %ENTITY_SPEC_LOCKED% | commit/log state tokens | Identity/commit style | `RaBbLE-Identity.md:4, 73, 132, 134, 158, 341`; `RaBbLE-Grimoire/RaBbLE-Agent` commit style | These are commit-message state tokens, not entity conditions. Do not map them to faces. Only %NULL_VOID% is a named entity condition (Identity 286). |
| %INJECT_STATE% | template placeholder | Identity | `RaBbLE-Identity.md:319` | Template placeholder, not a state. |
| World setState / setMood calls | state/mood requested by Portal | World | `RaBbLE-World/world/js/RaBbLE-face.js:91` (entityState wrapper), `:357` (setMood idle), `RaBbLE-account.js:405-406` (setMood process, setState idle), `:424` (setMood idle, setState speaking), `RaBbLE-stage.js:88` (thinking), `:110` (idle), `RaBbLE-dock.js:101-102` (thinking/speaking) | Portal passes `idle | listening | speaking | thinking` as state and `idle | ponder | process | insight | curious` as mood. `RaBbLE-face.js:93` maps idle -> RESONANT label. |
| RaBbLE-movements data | movement names | World | `RaBbLE-World/world/js/RaBbLE-movements.js` (state strings `'idle'` / `'speaking'` at lines 64, 106, 123, 207, 222, 357-358, 413, 434, 523, 537, 551, 610); `RaBbLE-movements-data.js` (content labels, not expressions) | World movements use the state strings idle/speaking only. No pose names. |
| eye-behavior saccade mode: calm / normal / alert / chaotic | state (eye saccade) | web NeBuLA | `RaBbLE-NeBuLA/src/backends/eye-behavior.js:41, 59, 112` | Different axis from emotion. `calm` here means saccade mode, not the emotion. Name collision. |
| entity state (eye-system) | state | web NeBuLA canvas2d | `RaBbLE-NeBuLA/src/backends/canvas2d/eye-system.js:32`; `eye-behavior.js:56` | Always `'idle'` at start. |
| STATE_ENTROPY idle/thinking/speaking | state (entropy) | web NeBuLA core | `RaBbLE-NeBuLA/src/core/animation.js:8-12` (0.3, 0.6, 0.8) | Entropy values, not poses. Uses `thinking` name (legacy). |
| `STYLE` keys: energy glow tempo bounce hop trem gazeY orbit sphere lens jit pulse strike surf grav bpm sparkle sigh dim stiff | style channels | web, Pocket, spec | `alive-backend.js:219-224`; spec 3.x "Style channels" | Keyed by emotion (calm, joy, sad, angry). `dim` and `hop` differ between web and Pocket (spec open item). |

## 2. Same concept under different names across surfaces

| concept | canonical (spec 4 table) | web NeBuLA | Pocket firmware | TUI (Rust/Py) | Identity / Grimoire | World / other | notes |
|---|---|---|---|---|---|---|---|
| listening | listening | `listening` (state) | `NL_STATE_LISTEN`, `W_LISTEN` | Expr `Listening`, Mood `typing` | none | World: no listening call found | TUI Mood name differs from Expr name. |
| speaking | speaking | `speaking` (state) | `NL_STATE_SPEAK`, `W_SPEAK` | Expr `Speaking`, Mood `streaming` | none | World: `speaking` | |
| thinking | process (mood) | `thinking` (legacy alias of idle + process) | `NL_STATE_THINK` (ponder then process) | Mood `working` (drawn as calm 2.5x) | `%THINKING%` not defined | World: `thinking` in stage, dock | Spec says `thinking` is an alias for mood `process`, not a state. Three names for one thing. |
| ponder | ponder | mood `ponder` | THINK for first 1.5 s (`F_PONDER`) | none | none | none | Pocket has no ponder name, only time. |
| process | process | mood `process` | THINK after 1.5 s (`F_PROCESS`) | Mood `working` | none | World `process` (`account.js:405`) | `working` in TUI is not `process`. |
| insight | insight | mood `insight` | none | none | `%GENIUS_RESONANCE%` (Identity peak) | mock HTML only | Identity name and mood name describe the same peak. |
| curious | curious (descriptor, not expression) | mood `curious` | none (`touch`/`happy` as noticing) | none | Identity: temperament (Canon 9.2) | mock HTML only | Canon says it is a descriptor. |
| sad | sad (emotion) | `sad` | `NL_STATE_ERROR` -> sad | Mood `error` -> sad | none | none | `error` is the TUI name; `ERROR` is the Pocket name. |
| angry | angry (emotion) | `angry` | none | Mood `denied` -> angry (2 s) | none | none | `denied` = a cue, not the same as `angry` state. |
| joy | joy (emotion) | `joy` | input `happy` -> joy | none | none | none | Pocket input name differs from expression name. |
| calm | calm (emotion, resting) | `calm` | `F_CALM` / `W_CALM` | Expr `Calm` (also Mood `idle` -> calm, `face.py:847`) | none | none | Mood `idle` maps to expression `calm`. |
| idle | idle (state) | `idle` (state), also `idle` mood | `NL_STATE_IDLE` | Mood `Idle` | `%RESONANT%` (Identity) | World label `RESONANT` | Idle is overloaded: state, mood, Pocket enum, and Identity resting condition are all "idle or resonant". |
| resonant | (Identity name for idle) | none (no alias in alive-backend) | none | none | `%RESONANT%` | World label `RESONANT` (`RaBbLE-face.js:93`) | Alias of idle. |
| glitch | (condition) | none in alive | none | none | `%GLITCH%` | doors.js `'glitch'` | Only the doors element uses it. |
| dormant | (condition) | none | none | none | `%DORMANT%` | none | Parked seed. |
| error | sad (Pocket/TUI) | none | `NL_STATE_ERROR` | Mood `error` | `%SYSTEM_DRIFT%`? (no direct map) | none | Error in TUI and Pocket maps to sad; Identity has no error state. |
| denied | angry (TUI only) | none | none | Mood `denied` | none | none | |
| rest / Rest (home) | Rest (home) | `0110` in spec; `FORMS` in live.js | `F_CALM` is the rest | none | none | none | Form vs emotion: calm is an expression, Rest is a form. |
| mirror | Mirror (form) | none | none | none | none | none | Named in live.js and spec. |
| swap / Swap | Swap (form) | none | none | none | none | none | Live body dropped it (ruling 22). Also "the Ball" in spec. |
| portal swap | portal swap (move) | none | withdraw-swap (`scene.c:689-714`) | none | none | none | Pocket's name is "withdraw-swap"; spec adopts "portal swap". |
| turn | turn (move) | none | none | none | none | none | Spec name; live.js `rotMode='spin'` is the same concept. |
| blink | blink (move) | `blink` (eye.blinkT) | blink | none | none | `graph.js` / `floor.js` blinkPhase | Spec: blink = squash toward portal, not a screen cut. |
| withdraw / hide | withdraw (move) | none | `withdraw` in curve | none | none | none | Spec says eyes "hide" by "withdraw". Two names for one step. |
| shock / poke | disturbance trigger | `shock` (boot), `poke` (4x = angry) | `dizzy` (spec only) | Error, Denied | none | none | Spec table lists these as triggers. |

## 3. Notes for the consolidation

- The emotion layer is calm, joy, sad, angry on web and TUI. Pocket has no angry slot. TUI Mood `denied` is the only route to angry on TUI.
- The state layer is idle, listening, speaking, plus the legacy `thinking`. Pocket uses NL_STATE_* enums with the same meaning but different names.
- The mood layer is idle, ponder, process, insight, curious. Pocket derives ponder and process from time in THINK. Insight and curious have no pose anywhere.
- Condition names from Identity (%DORMANT%, %INITIALIZING%, %CALIBRATING%, %RESONANT%, %GLITCH%, %SYSTEM_DRIFT%, %GENIUS_RESONANCE%, %NULL_VOID%) have no mapping to any face. Canon 9.5 proposes a condition layer. Only doors.js and the World label reach any of them.
- Forms: live.js FORMS has 2 entries. Spec 4.1 has 4 stable forms. Unstable working names (cold, very sad; angry, alarmed; odd state) are only in the builder and live.js WORKING table.
- Canonical name set to use in new code, from the spec: calm, joy, sad, angry (emotion); idle, listening, speaking (state); idle, ponder, process, insight, curious (mood); Rest, Swap, Mirror, Swap-Mirror (form); turn, portal swap, flip, blink (move).
