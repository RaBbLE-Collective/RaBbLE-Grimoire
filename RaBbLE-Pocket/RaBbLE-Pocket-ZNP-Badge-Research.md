# RaBbLE-Pocket ZNP Badge Research and Data Flow

Status: research note (2026-11-18, S352). Nothing built. Decisions below are Mark's direction from a chat, not formal rulings; the encryption section feeds `log/plans/EP2-Accounts-Encryption-Spec.md` and the S333 rulings in `log/DECISIONS.md`.

## ZNP Z01 findings
- **What it is:** a mic, speaker, small round touch screen, one button and a Bluetooth chip. Per the community repo, there's no AI inside. The badge sends voice to a phone app over BLE and shows or plays what comes back.
- **Reverse engineering exists:** [devniz/znp-re](https://github.com/devniz/znp-re) documents the full BLE protocol, with iOS, Android and Python examples. It's plain BLE, so a Pi or ESP32 could drive it too. The stock firmware stays untouched, so you can't brick it.
- **Chip:** probably JieLi, based on the RCSP-style protocol. This is an inference, not confirmed. Open one up and read the marking.
- **Variants:** at least Z01, Z01 Pro, Z02 and Z06. I only found protocol work for the Z01, so don't assume it applies to the others. Listing specs vary a lot between sellers.
- **Display unknowns:** the vendor app (BagiBagi) reportedly uploads images and short video loops, and wallpapers are stored on the badge. Text streams live. Whether it accepts arbitrary live frames for the entity is **unconfirmed**. Read PROTOCOL.md for that.
- **Likely no IMU.** The listings mention none, so the badge loses tilt, gravity-lock and shake inputs.
- **Reflashing:** unproven. JieLi has published SDKs and there's a community wiki for custom firmware on the M-VAVE FM-1 synth, but some chips may need a vendor tool. I found no one who has reflashed a ZNP badge.
- **Company:** I found nothing solid. It looks like a white-label product sold under several seller names (Hengjiaxin, JKNKCO, ZNP). The real OEM isn't identified yet.

## Decisions and direction
- **App path first.** A first-party RaBbLE companion app replaces BagiBagi. Reflashing is a side quest.
- **Tiers:** the badge is a thinner, longer-lasting, loop-based input surface. The Pocket is the full ambient creature. The loops would come from the same entity data as everything else.
- **Rig spec runs on the driver:** phone, web, or possibly ESP32. The ESP32 could receive streamed images into an LVGL texture as an overlay.
- **App as hub:** it bridges BLE to the internet, hands the device Wi-Fi credentials and runs local models.
- **Sourcing idea:** buy unbranded units from the OEM and rebrand them. Affiliate links plus a pair-and-flash flow are also on the table. Check the reseller terms first.

## Privacy and keys (still in progress)
- **Goal:** sCoRE holds only ciphertext, and you can't see user data.
- **Open:** whether to encrypt device-side or sCoRE-side. Device-side is the only way "the architect can't snoop" is actually true.
- **Pocket without a phone:** it decrypts on-device. The ESP32-S3 has hardware AES and SHA, plus flash encryption and secure boot via fuses. This isn't a true secure enclave, and fuse settings are permanent, so test on a spare board.
- **Pairing:** per-device keys, with revocation from the phone app.
- **Limited Pocket access:** write-mostly, with a cache of recent items only, so a stolen device exposes little.
- **Audio:** protect it with TLS in transit. sCoRE must see plaintext for Whisper, so it's a "never stored in plaintext" claim, not "never seen".
- **Auth:** a re-authenticating session unlocked from the phone. The gesture PIN is deferred, and it's weak on its own without retry limits.
- **Scope:** general personal data only, no finances, with a remote kill switch for lost devices.
- **Before promising anything publicly:** get an outside review, ideally a public spec or a small crypto consultancy. I'm not a security professional.

## Next steps
1. Read PROTOCOL.md to see how far the screen can go.
2. Buy one Z01 and read the chip marking.
3. Decide the encryption side, then do the pair and flash flow.
4. Run a full battery test on the Pocket, logging screen-on separately from idle.

## Sources
- [GitHub: devniz/znp-re](https://github.com/devniz/znp-re)
