# Episode 1 Release — Dispatch Brief

**Objective:** Ship Episode 1 (`episode-1-v0.0.0.1` tags across all repos). This is the first production-ready state of the RaBbLE entity — it ends the pilot phase, exercises the versioning system, and gives the Collective's voice its first public moment.

**The narrative:** Genesis — RaBbLE emerges from concept to live experience. The entity observes, learns from patterns, speaks. Today it's a chatbot; Episode 1 is the first step toward ambient intelligence. The release is the story: "You can now talk to RaBbLE and see it think."

---

## Exit Conditions (from `registry/epochs/current.epoch.yml`)

These define Episode 1 done. Verify all are met:

- [ ] **sCoRE chat works end-to-end locally** (DONE — S56d)
- [ ] **sCoRE deployed to Render (production-ready)** — see [EP1 Dispatch State](../log/EP1-Dispatch-State.md)
- [ ] **RaBbLE-World deployed to production**
- [ ] **RaBbLE-OS VM bootstrap verified**
- [ ] **All repos tagged `episode-1-v0.0.0.1`**
- [ ] **Session log updated with EP1 exit summary**

Anything not listed is post-Episode-1 scope.

---

## Scope Boundaries (scope-cut approved)

**Ship as-is / already done:**
- sCoRE local chat (working, S56d)
- NeBuLA entity visual (S56e polish complete)
- Aether CSS framework
- RaBbLE-OS live as daily driver

**Ship rough (visual polish acceptable):**
- RaBbLE-Studio (can be MVP — one functional panel, rest cosmetic)
- Grimoire Graph (eye/portal tuning complete; missing features OK)

**Post-Episode-1 (do not include):**
- Watcher daemon / Behavioral Memory (Episode 2 spine)
- State machine implementation in NeBuLA (Episode 2)
- World chrome unification / page fragmentation cleanup
- Genesis authoring / Phase 2C (Mark's domain)
- BaBbLE register leakage / entity emotion system
- Membership / Pair summoning (defined this session — implementation is EP2 work)

**Decision:** Focus on the core loop: user speaks → sCoRE responds → entity reacts visually. That's Episode 1.

---

## Tasks

### 1. sCoRE Render Deployment
**What:** sCoRE must be running on Render in production, accessible at a stable URL, serving chat to RaBbLE-World.

**Status:** See `EP1-Dispatch-State.md` for current runbook and blockers.

**Verify:**
- [ ] Render service `rabble-score` created via Blueprint
- [ ] `GROQ_API_KEY`, `OPENROUTER_API_KEY`, `RABBLE_ADMIN_KEY` env vars set
- [ ] `curl https://rabble-score.onrender.com/health` returns 200
- [ ] Chat works end-to-end: World → Render → LLM response
- [ ] TTFT documented (warm and cold-start)

**Acceptance:** curl to Render endpoint returns 200; chat message from World gets a response within 5 seconds (warm).

---

### 2. RaBbLE-World Production Deployment
**What:** RaBbLE-World is live at `joinrabble.world`, wired to Render sCoRE endpoint.

**Current state:**
- Chat page functional and wired to local sCoRE
- All pages built
- NeBuLA + Aether bundled in World

**Steps:**
- [ ] Build NeBuLA (`npm run build:iife` → copy to World)
- [ ] Build Aether CSS (verify `aether.css` current)
- [ ] Update World chat page to point to Render sCoRE URL (not localhost)
- [ ] Deploy via GitHub Actions (or manual Wrangler deploy)
- [ ] Verify all pages load without 404s or console errors
- [ ] Test chat end-to-end: post message → Render → response streams back → entity reacts

**Acceptance:** Visit `joinrabble.world`, post message in chat, get response, entity renders.

---

### 3. RaBbLE-OS VM Bootstrap Verification
**What:** The RaBbLE-OS installer boots, installs, and becomes a usable daily driver.

**Verify:**
- [ ] Netinstall boots from ISO
- [ ] KS %packages correct (check `ansible/packages/manifest.yml`)
- [ ] Ansible bootstrap runs without errors
- [ ] Hyprland + hyprpolkitagent launch
- [ ] Network connectivity works
- [ ] Browser can reach `joinrabble.world`

**Acceptance:** Fresh VM install → boots to login → browser reaches World and chat.

---

### 4. Tag All Repos `episode-1-v0.0.0.1`

**Repos:**
- RaBbLE-Grimoire
- RaBbLE-sCoRE
- RaBbLE-World
- RaBbLE-NeBuLA
- RaBbLE-Aether
- RaBbLE-OS
- RaBbLE-BaBbLE (reference tag)

**Acceptance:** `git tag -l` on each repo shows `episode-1-v0.0.0.1`.

---

### 5. Update Session Log & Release Notes

- [ ] Update `RaBbLE-Grimoire/log/SESSION-LOG.md` ## LATEST block (75 words max)
- [ ] Add session entry with repos touched and work done
- [ ] Finalize `RaBbLE-Grimoire/log/EPISODE-1-RELEASE.md` with exit conditions met and known limitations

---

## Coordination

**Sequential dependencies:**
1. sCoRE Render deploy first (World needs the endpoint URL)
2. World production deploy depends on that URL
3. OS VM verification is independent (parallel)
4. Tagging happens after all three confirmed working

**Known limitations to document:**
- Render free tier: ~30–60s cold-start after 15 min idle
- No user accounts yet (EP2 — see Membership Model)
- Behavioral learning not yet active (Memory member is EP2+)

---

## Notes for Agents

- **Scope is locked.** Don't negotiate scope — cut scope instead.
- **Mark adjudicates blockers** that require decisions (deploy date vs. feature cut).
- **Render, not Railway** — all Railway references in older docs are stale.
- **Canonical domain is `joinrabble.world`** — `rabble.world` references in older docs are stale.
- **When in doubt, read the Grimoire first.**

Ship well.
