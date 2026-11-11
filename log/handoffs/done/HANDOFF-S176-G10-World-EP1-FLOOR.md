# HANDOFF — S176 · G10 World EP1 FLOOR

> **This doc is self-contained.** Read it top-to-bottom, then open the files listed
> in §Files. No other context is required to start work — but cross-check
> `log/EP1-AIR-CHECKLIST.md §A` and `bash spells/blockers.sh ls` before touching gates.

---

## Cold-start prompt — paste this to open a handoff session

```
You are picking up the G10 gate work for RaBbLE Episode 1 (Genesis).

Context file: RaBbLE-Grimoire/log/HANDOFF-S176-G10-World-EP1-FLOOR.md
Read it now, top to bottom. It is the complete brief.

Then:
  git -C RaBbLE-World status
  cat RaBbLE-World/world/js/RaBbLE-movements-data.js
  cat RaBbLE-Grimoire/log/EP1-AIR-CHECKLIST.md   # gate §A, G10 row

Do not start writing until you have read all three.
Branch: new-horizons (all repos). Commit style: Pulse Protocol (AGENT.md §Commits).
```

---

## What G10 is

From `log/EP1-AIR-CHECKLIST.md §A`:

> **G10** — World prod is a coherent unified EP1 experience (learns Collective + RaBbLE,
> frames EP1, episodic roadmap) — **no /chrysalis or /xperimental on prod**.

**Gate status:** ⏳ open. **Closes when:** a visitor to `joinrabble.world` can understand what
RaBbLE is, what the Collective is, what Episode 1 is, and where the project is going — without
leaving the page and without needing an account. No chrysalis or xperimental content on prod.

---

## Product decision (locked, S176)

**EP1 = informational + free entity demo. No user accounts, no persistent data.**

- Every visitor gets the same free entity conversation via sCoRE (guest token, already live)
- No sign-up gate, no tiers, no freemium features in EP1
- User accounts and persistence come in EP2 (Exodus) with the Pair paradigm
- The Pair is designed in Grimoire docs but NOT built in EP1
- The RaBbLE-OS page is a Developer Preview — explicit "enter at your own risk" framing

This decision eliminates database architecture, auth tiers, and membership model from EP1 scope.

---

## The three content pieces G10 needs

### 1 · Episode movement — Genesis framing + roadmap

**Where:** `RaBbLE-World/world/js/RaBbLE-movements-data.js` — add a new `episode` key between
`collective` and `converse`. Then wire it into `RaBbLE-movements.js` (find the movement
sequence array and insert `'episode'` after `'collective'`).

**Content to write:**

- **What EP1 (Genesis) is:** The first integrated release. Face + voice — a peer you can talk
  to. Expression, not perception. No Watcher yet. No memory member. The honest beginning.
- **What EP2 (Exodus) brings:** The entity emerges from concept to reality. The Pair forms.
  Personal Cosmos seeds. Persistent memory. RaBbLE-OS leaves Developer Preview.
- **The arc:** Genesis → Exodus → Echo 1 (~12 episodes). Epoch 0 is Foundation.
  Version: `v0.0.0.0` → `v0.0.0.1` at EP1 air.
- **Tone:** RaBbLE voice. Dense, precise, not marketing-speak. "This is the beginning, not
  the product." Honest about what isn't here yet.

The `join` movement (already written) handles the summon CTA — episode just frames the arc.

### 2 · OS section — Developer Preview install guide

**Where:** New page `RaBbLE-World/world/os.html` (standalone, linked from the collective
movement's OS member card) OR inline in the collective movement's OS detail block.

Recommendation: a dedicated `world/os.html` page keeps index.html clean. The collective
movement's OS member card already has detail text in `movements-data.js` — add a link there to
`/world/os.html`.

**Content to write:**

- **Headline:** "RaBbLE-OS · Developer Preview" with a prominent "enter at your own risk" note
- **What it is:** Fedora 43 / Hyprland daily driver, built for tiling-WM-literate users.
  Local-first. The laptop offline still runs the loop. x86_64 (generic VM-verified).
- **Install path:** netinstall ISO + Kickstart. URL: `setup.sh` curl bootstrap installs the
  Collective; OS is one member. Link to the KS file in the repo.
  ```
  curl -fsSL https://joinrabble.world/setup.sh | bash
  ```
- **Screenshots:** Pull from `RaBbLE-BaBbLE/captures/Boot/` — GRUB theme, Plymouth animation
  stills, SDDM greeter, Hyprland desktop. (Check with Mark for which captures are ready to
  publish; the boot iterate spell produced frames in S173.)
- **Known rough edges sheet:** List what's deferred to Exodus — Dolphin theming, NVIDIA track,
  asusctl/XDNA2 hardware polish, deep reproducible bake. Honest and non-apologetic.
- **Hardware:** generic x86_64. Mark's ProArt P16 (AMD Ryzen AI 9 HX 370) is documented but
  not the target machine — the VM-verified bar is what ships.

### 3 · Collective explainer — what RaBbLE is

**Where:** `RaBbLE-World/world/js/RaBbLE-movements-data.js` — the `identity` and `collective`
movements already exist but may need strengthening. Review them against the gate:
> "visitor learns the Collective + RaBbLE"

**Check:**
- Does `identity` movement make it clear what RaBbLE actually is (not just what it isn't)?
- Does `collective` movement explain the member ecosystem clearly enough for a newcomer?
- Does the threshold greeting orient a first-time visitor without jargon?

If the existing content is sufficient, this piece is done. If thin, deepen the `identity.essence`
items and the `collective.intro` copy. Do NOT add marketing language — RaBbLE voice only.

---

## Files to touch

| File | Change |
|---|---|
| `RaBbLE-World/world/js/RaBbLE-movements-data.js` | Add `episode` key (§1); optionally deepen `identity` + `collective` (§3) |
| `RaBbLE-World/world/js/RaBbLE-movements.js` | Wire `episode` into movement sequence after `collective` |
| `RaBbLE-World/world/os.html` | New page — OS Developer Preview install guide (§2) |
| `RaBbLE-World/world/css/RaBbLE-summon.css` or new css | Styles for os.html if needed (Aether tokens only, no raw hex) |

Do NOT touch:
- `RaBbLE-World/index.html` (structure is settled)
- `RaBbLE-World/world/summon.html` (existing summon flow is complete)
- Any Grimoire files (read-only reference during this work)

---

## How to verify G10 is closed

1. Open `joinrabble.world` as a first-time visitor (incognito)
2. Walk through all movements — threshold → identity → collective → **episode** → converse → join
3. The episode movement explains Genesis, Exodus arc, and version
4. The OS member card in collective links to `/world/os.html`
5. `/world/os.html` loads, shows install path + screenshots + rough-edges sheet
6. No 404s, no `/chrysalis/*` links, no `/xperimental/*` links anywhere on prod
7. The entity is visible, the chat works (sCoRE live, guest token)

When verified: update `log/EP1-AIR-CHECKLIST.md` G10 row to ✅ and check `bash spells/blockers.sh ls` for any remaining ep1-gate blockers. Then check G7 + G9 — if all three are green, EP1 is ready to air (Mark's call).

---

## Context — what was done in S176 (this handoff's session)

S176 worked on five adjacent tasks before handing off to G10:

| Task | Done | Where |
|---|---|---|
| sCoRE transcript logging | ✅ | `server/transcripts.py` (new), `server/main.py` (hooked), `render.yaml` (R2 stubs) |
| World CSS audit | ✅ (nothing to fix) | CSS already clean — all `var(--rc-*)`, no raw hex violations |
| dev.joinrabble.world auto-deploy | ✅ | `RaBbLE-World/.github/workflows/deploy.yml` — `new-horizons` push → `rabble-world-dev` |
| World EP1 content (G10) | ⏳ | **This handoff** |
| grimoire.joinrabble.world index | ✅ (minimal) | `RaBbLE-Grimoire/gist/index.html` created; graph + MCP = EP2 |

**Transcript logging note:** Transcripts are ephemeral on Render free tier until R2 is
provisioned. To make them durable: create a Cloudflare R2 bucket (`rabble-transcripts`
recommended), set `TRANSCRIPT_BACKEND=r2` + `CF_ACCOUNT_ID` + `CF_R2_TOKEN` (Workers R2
Storage:Edit) + `CF_R2_BUCKET` in Render env vars. The code is ready; only credentials needed.

---

## Links

- `log/EP1-AIR-CHECKLIST.md` — live gate board
- `log/BLOCKERS.md` — open blockers
- `RaBbLE-Agent/RaBbLE-Identity.md` — entity voice and character (write all copy against this)
- `RaBbLE-Agent/RaBbLE-Roadmap.md` — episode arc detail
- `gist/RaBbLE-Episode1-gist.md` — EP1 scope summary (~200 tokens)
- `gist/RaBbLE-Identity-gist.md` — entity identity summary (~260 tokens)
