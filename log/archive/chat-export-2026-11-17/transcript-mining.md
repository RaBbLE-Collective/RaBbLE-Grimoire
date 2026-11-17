# Mining the raw transcripts: method and results

```
transcribe ~ grimoire >> raw chat transcripts mined for authored docs and decisions // %ARCHIVE%
```

> Second pass over the 2026-11-17 chat export, using full transcripts instead of summaries. Raw data stays in the
> Personal Grimoire archive; this note records what was found and where it went.

## Method

1. Pulled every document Claude wrote inside the chats from the file-creation tool calls (95 distinct
   filenames, `.md` and `.txt`, over 1.5 KB; 139 writes counting revisions).
2. Matched each one against all the repos by content (shared six-word runs), not by filename, because many
   were renamed on the way into the Grimoire.
3. Pulled the decision and constraint sentences out of the full chat summaries (the earlier digest kept only
   the first paragraph) and checked each against the Grimoire with a text search, then read the hits to drop
   false positives.

## Results

- **Already in the Grimoire (35 of 95 docs at 90 to 100% text match, 7 more at 30 to 90%):** the sCoRE architecture set
  (Local-Architecture, Quota-Router, Entropy-Tracker, Agent-State, Local-Tickets), Dependency-Policy,
  TaskViSoR-Identity, Platform-Identity, the Agent-Framework-Research, PRD and Vision set, EP2 accounts spec,
  Puppet-Pocket pipeline, EnGrAm-Architecture, EyeStates and DevHistory. The chats were the authoring surface
  and the integration was done at the time.
- **No home yet, now placed (6 docs; the other 47 below 30% are April drafts, the items listed next, or career, Incenergy and PhysioAI material):** `RaBbLE-NeBuLA-VJ-Persona-Notes`, `RaBbLE-Pocket-Muse-Bringup`,
  `RaBbLE-Pocket-Boot-Latency-and-Power-Session`, `RaBbLE-Distilled-Nonzens-Mythos`,
  `RaBbLE-Society-of-Agents-Architecture`, `RaBbLE-EnGrAm-Photo-Notes-Storage-Origins`.
- **Elsewhere:** `STAT_SPEC` and the MCP benchmark notes went to `~/Incenergy/docs/`; interview prep went to
  `Seeker/.../jobs/` (Lutron round 3, Warren County study); the PhysioAI spec bundle and the Dropbox-reorg
  agent contract went to the Personal Grimoire intake.
- **Left in the raw archive:** April 2026 working drafts of the OS and Collective docs (they were superseded by the
  versions now in `RaBbLE-OS/historical/` and the reliquary), EP1 air plans (EP1 shipped), and
  `NeBuLA-Morphogenesis-Concept` and `Unified-Nebula-Spec` (kept in `design-docs/`; the Morphogenesis concept
  builds on another artist's work with a restrictive licence, per the 2026-10-06 chat, so it was not promoted).
- **Decisions:** 16 decisions the Grimoire had no trace of were added to `log/DECISIONS.md` under "Decisions
  recovered from chat history", each with a status. Corrected after review with Mark: the framework row now states his intent (framework-agnostic,
  React not used yet, adoption deliberate); the capture row is open (client versus server decryption undecided,
  everything stored must be encrypted); one row still needs checking against the S328 compositor trial.

## Limits

- 69 of 218 chats have empty bodies in the export, so nothing can be mined from them.
- Decision rows come from Claude's chat summaries, which are second-hand. Verify before treating one as a ruling.
- Document match percentages count shared text, so a heavily rewritten doc can score low while still being
  covered. Low scorers were read by hand before placing.
