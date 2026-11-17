# RaBbLE Pocket: Ideas Pane

<!-- tab: RaBbLE Pocket: Ideas Pane -->

# RaBbLE Pocket: Ideas Pane (Oct 22, 2026)

Status: ideas and design direction, not decided. Written after Pocket first captured a note, beamed it to sCoRE for transcription, and saved it locally. Firmware is built on the Muse gadget SDK and is being clean-roomed.

## 1. Capture and offline queue

- Flash partition is only 8 MB, so store compressed audio, not raw. Raw 16 kHz mono is about 32 KB per second (about 4 minutes). Opus at about 16 kbps fits roughly an hour.
- Use the TF card slot as the real offline queue. Flash holds the index and a small buffer.
- Queue states: recorded, queued, beaming, confirmed, purged.
  - recorded: compressed, written to SD with timestamp and private flag.
  - queued: eligible to beam, waiting for a link.
  - beaming: in flight to sCoRE.
  - confirmed: sCoRE transcribed and acknowledged with a checksum.
  - purged: audio deleted, tiny index entry kept.
- Rule: never purge until sCoRE confirms the note is safely stored.
- Storage full: the Pocket reports it and the user offloads. The entity shows it as a mood (portals dimming), not an error.

## 2. Private mode

- Physical gesture on the device, such as a long press on the action button or a button combo.
- Clear indicator on the entity (different glow or closed-portal look) so the mode is always obvious.
- Private notes are tagged at capture, stored encrypted on SD with a device key, and never enter the beam-up queue.
- Private notes skip the middle of the queue and go from recorded to a local-only state.
- Private notes need local transcription (dock session or phone), since no third-party provider should see them.

## 3. Dock session (USB plug-in)

- When the Pocket connects to the laptop or desktop, a companion service pulls queued audio off the SD card.
- Local Whisper transcription on the RTX 4060 laptop or RX 6700XT desktop.
- Results pushed into sCoRE as text. Private notes stay entirely on the user's own machine.
- Same session can double as the learning-while-charging loop: offload, transcribe, retrain the creature network.

## 4. Transcription options (cheapest to most sovereign)

- Groq Whisper Large v3 Turbo: about $0.04 per audio hour. Current cheapest hosted option.
- Deepgram Nova-3: about $0.26 per hour batch. OpenAI hosted Whisper: $0.006 per minute.
- Self-hosted Whisper on own GPU: feasible, but the box becomes a single point of failure for every user.
- On-device on the paired iPhone (Apple on-device speech recognition): audio never leaves the phone, no per-call cost. Best long-term answer once the iOS app works.

## 5. Rough cost picture (single heavy user)

- About 2 hours of voice notes per day is about 60 hours a month, roughly $2.40 of transcription on Groq.
- Classifier and cleanup tier on small models: a dollar or two.
- Reasoning on a mid-tier model for a few hundred notes: single-digit dollars.
- Total: roughly $5 to $15 per heavy user per month. Prices checked via web search on Oct 22, 2026; verify before relying on them.
- Privacy settings matter more than price.

## 6. Account, encryption, and backup (Amazon S3 on the Collective)

- Envelope encryption: a data key per note or batch, wrapped by a per-user key in AWS KMS. Only the wrapped key is stored beside the ciphertext in S3.
- Recovery: KMS-held key gated by account login through sCoRE, plus a recovery phrase as a second wrapping of the user key, kept offline by the user.
- Bucket hygiene: private, public access blocked, versioning on, object lock for ransomware protection, IAM scoped to each user's prefix, CloudTrail on key use.
- Decryption happens server-side in sCoRE, in memory, per request. Encrypted at rest, not end-to-end. This makes search and the Grimoire MCP easy.
- Later option: client-side end-to-end with a key derived from a recovery phrase or passkey. More sovereign, but search and MCP access get harder.
- The Grimoire MCP never touches S3 directly. It asks sCoRE, which checks the session, fetches, decrypts, and returns plaintext. One choke point for auth and audit.
- API keys for Groq, OpenRouter and others: keep in Secrets Manager, scope per provider, set spend limits, rotate.

## 6b. Data in motion and provider choice

- TLS protects the wire. The real exposure is what the provider does with content once it arrives. Anonymizing helps identity, but note content can identify people on its own.
- Pick providers by data terms: zero retention, no training on API traffic. OpenRouter can restrict routing to zero-retention endpoints, but that shrinks the free-model pool.
- Free tiers are where risk concentrates. Free Gemini API and free OpenRouter models may log or train. Verify Groq's terms before relying on them.
- Strip or pseudonymize obvious identifiers before anything leaves sCoRE.
- Tiering: most idea-capture notes may go to vetted providers after scrubbing. Client or personal details stay local or on sCoRE only. A private tag means never sent anywhere. Default to the stricter tier when the classifier is unsure.
- Note: sCoRE has no compute of its own today and relies on third-party providers.

## 7. Free tier and paid tier model

- Free tier: free-offered models, with transparent disclosure of which provider handles the notes and that they may be logged or used for training.
- Paid tier: named zero-retention models and the sovereign backend.
- Product framing: built for idea capture, not personal logging. This keeps free-tier stakes low.
- A plain label at the moment of use does more than a buried policy. The policy should say the same thing.

### Draft in-app disclaimer

"RaBbLE is built for idea capture. Please don't store sensitive personal information. On the free tier, notes may be processed by third-party AI providers. Mark any note private to keep it on your device only."

### Draft privacy policy section (early phase, to refine)

- Purpose: RaBbLE is designed for capturing ideas, project thoughts, and to-dos. It is not designed for sensitive personal records.
- Free tier processing: transcription and reasoning may use third-party AI providers. Those providers may log requests, and some may use content to improve their products. Content is minimized and identifiers are scrubbed where possible, but this cannot be guaranteed.
- Private notes: notes marked private are stored encrypted on your device, are not sent to third-party providers, and are not included in cloud backup unless you choose otherwise.
- Paid tier: uses named providers with no-retention and no-training terms, plus encrypted account backup.
- Storage: backed-up notes are encrypted at rest. In the current design the service can decrypt them to provide features like search.
- Review this section with a qualified professional before public launch.

## 8. Open items and next steps

- Research providers properly for no-retention, no-training terms, especially on free tiers.
- Check whether yesterday's Pocket work is pushed. The RaBbLE-Pocket repo had no branches when last checked, and the Muse code was not found in the Grimoire.
- Build out the Grimoire MCP and the AWS layer (S3, KMS, Secrets Manager).
- Decide the privacy gesture and the entity's private-mode look.
- Prototype the dock companion service with local Whisper.
- Plan phone-side transcription for the iOS app.
- Phase the work onto the Pocket in order: capture queue first, private mode, dock session, then account sync.

## 9. Update: current hardware reality (no SD card yet)

- No SD card is installed, so the offline queue is the 8 MB LittleFS partition on the 16 MB flash. The rest of flash holds the app and a few MB reserved for OTA.
- Compression becomes mandatory, not optional. Opus at about 16 kbps holds roughly an hour in 8 MB. Dropping to 12 or 8 kbps for voice buys more headroom.
- LittleFS wear: write each note as one append-only file, avoid frequent small rewrites, keep the index tiny.
- Power-loss safety: write the audio first and the index entry last, so a crash mid-note leaves a recoverable orphan, not a corrupt queue.
- High-water mark: at about 80% full the entity starts signaling, so storage never surprises the user mid-thought.
- Storage full means the user offloads. No automatic eviction.
- Terminology: the capture queue is just offline notes saved as small compressed files in a waiting line, beamed to sCoRE when back online, then deleted after confirmation.

## 10. Update: current firmware status

- The Pocket works end to end: it captures a note, beams it to sCoRE, sCoRE transcribes it, and it is saved locally.
- Built on the Muse gadget SDK, which is now being clean-roomed. Opus 5.5 has been very effective for ESP32 work.
- Unknown: when offline, does the firmware persist audio to LittleFS, or only hold the latest buffer in RAM? If buffer-only, the Opus capture queue is the first real feature to build, not a retrofit.
- Unknown: whether yesterday's work was pushed to GitHub. The RaBbLE-Pocket repo was empty when last checked, and the Muse code was not found in the Grimoire's new-horizons branch.

## 11. Update: product decisions so far

- Offer a free tier on free-offered models, with the third-party logging and training risk disclosed up front in the app and the privacy policy. A paid tier names zero-retention providers and adds the sovereign backend.
- Product framing is idea capture, not personal logging. Mark does not want the service used as a diary.
- Recovery matters: the account backup must be recoverable (KMS-held key plus a recovery phrase), not lose-the-key-lose-everything.
- Mark wants to research providers that offer no retention and no training even on free tiers, accepting that this narrows the usable model set.
- The best long-term transcription path is on the paired iPhone, once the iOS app works. Dock-session Whisper on Mark's own GPUs covers private notes in the meantime.
- Standard practice is the goal for the AWS layer: S3, KMS envelope encryption, Secrets Manager, CloudTrail.

## 12. Next steps (to work locally)

- [ ] Ask the RaBbLE OS agent: when offline, does the firmware persist audio to LittleFS or hold only the latest buffer? If it persists, in what format and with what index?
- [ ] Check git status and push the Pocket firmware and the new-horizons branch so the work is recoverable.
- [ ] Build the Opus capture queue on LittleFS (append-only files, index written last, never purge before sCoRE confirms, 80% high-water warning).
- [ ] Define the private-mode gesture and the entity's private-mode look.
- [ ] Research providers for no-retention, no-training terms on free tiers (Groq, OpenRouter zero-retention routing, others).
- [ ] Stand up the AWS layer: private S3 bucket with versioning and object lock, per-user KMS keys, Secrets Manager for provider keys, CloudTrail.
- [ ] Build the Grimoire MCP so it reads through sCoRE, never straight from S3.
- [ ] Prototype the dock companion service with local Whisper on the 4060 or 6700 XT.
- [ ] Review the disclaimer and privacy policy wording with a qualified professional before public launch.

