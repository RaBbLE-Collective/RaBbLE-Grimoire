# EP1 Dispatch — Session State (S58, 2026-06-09)

> Handoff file. Written mid-session at Mark's request (context limit near).
> Companion to `RaBbLE-Episode-1-Release-Brief.md`. Next agent: read this, then resume coordination.

## Decision log

- **PIVOT: sCoRE deploys to Render, not Railway** (Mark's call — Render is fully free). All Railway references in brief/epoch/harness are now stale; update at finalization.
- Railway was never set up for sCoRE anyway (only linked project was unrelated `PhysioAi_Backend`; auth token expired 2026-04-25). No loss.
- `render.yaml` already exists in RaBbLE-sCoRE: service `rabble-score`, Python 3.12, `rootDir: server`, uvicorn, `healthCheckPath: /health`, free plan, `FRONTEND_URL=https://joinrabble.world`.
- Domain discrepancy unresolved: epoch file says `joinrabble.world`, brief says `rabble.world`. **Ask Mark which is canonical.**

## Task board

| # | Task | Status |
|---|------|--------|
| 1 | sCoRE → **Render** | 🟡 Agent running in background (relaunched after Render pivot; original Railway agent stopped). May still be in flight — check before re-dispatching. |
| 2 | World → production | ⏸ Blocked on Render URL |
| 3 | OS VM bootstrap verify | 🟠 PARTIALLY VERIFIED (see below) — dynamic VM run needs Mark |
| 4 | Release docs | ✅ Drafted — `RaBbLE-Grimoire/log/EPISODE-1-RELEASE.md` (placeholders pending; swap Railway→Render refs at finalization; SESSION-LOG draft at bottom of that file, not yet applied) |
| 5 | Tag ×7 repos `episode-1-v0.0.0.1` | ⏸ Blocked on 1–3 |

## 🔴 sCoRE deploy — MANUAL RUNBOOK for Mark (~5 min browser work)

Render agent finished (S58 close). Final facts:
- **GitHub remote EXISTS** (CONTEXT.md "deferred" note is stale): `git@github.com:markm1206/RaBbLE-sCoRE.git`. `main` in sync with origin (f54df1f); local `dev` (42d255e) vs `origin/dev` (bc75e33) — push state unverified.
- Server is Render-ready as-is: `uvicorn main:app --host 0.0.0.0 --port $PORT` (honors Render's $PORT), health at `GET /health` (`server/main.py:97`). No code changes needed.
- `render.yaml` was UPDATED (uncommitted): added `GROQ_API_KEY`, `OPENROUTER_API_KEY`, `RABBLE_ADMIN_KEY` as `sync: false` declarations (no values). Without them the server boots but every chat completion fails.
- `render` CLI is NOT installed; no `RENDER_API_KEY` found.

**Steps:**
1. Commit + push the updated `RaBbLE-sCoRE/render.yaml` (suggested: `ingest ~ sCoRE >> render.yaml for Episode 1 deploy // %EP1_DEPLOY%`) to the branch Render will track. **Decide: track `main` (stable) or `dev`.**
2. Render Dashboard → New → Blueprint → connect `markm1206/RaBbLE-sCoRE` → pick branch.
3. When prompted, paste values for `GROQ_API_KEY` / `OPENROUTER_API_KEY` / `RABBLE_ADMIN_KEY`. NOTE: earlier inspection found the provider keys *commented out* in `server/.env` — you may need to source valid keys from your password manager. At least one of Groq/OpenRouter is required (`server/llm.py`).
4. Service name `rabble-score` → expected URL `https://rabble-score.onrender.com` (subject to availability).
5. Verify: `curl <url>/health` then `python3 RaBbLE-sCoRE/server/api_test.py <url>`; measure warm latency/TTFT and a cold-start (free tier sleeps after ~15 min idle, ~30–60s wake).
6. Hand the URL to the next session → dispatch World deploy (task 2).

## OS VM verification (agent report summary)

**Verdict: PARTIALLY VERIFIED** — static checks clean; VM boot not run (agent sandbox couldn't exec virsh/ansible).

- KS %packages matches `ansible/packages/manifest.yml` ✅
- **Drift found + fixed (UNCOMMITTED):** `RaBbLE-OS/spells/generate-kickstart.py` emitted `@^minimal-environment` (broken on F44); now emits `@core`. On branch `RaBbLE-OS-New-Horizons`. Mark: review + commit.
- KS %post/firstboot, Bootstrap.sh flags, nofail/vmctl safety, hyprpolkitagent autostart: all PASS (static).
- **supergfxd stub bug: FIXED since S33** — but `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-AgentGuide.md:114` still lists it as open (doc drift). Also stale FIXME at `manifest.yml:507` (polkit-gnome claim — already fixed).
- Doc drift: KS/vmctl/ISO target **Fedora 44** (`ISO/Fedora-Everything-netinst-x86_64-44-1.7.iso` present); AGENT.md/CONTEXT.md say Fedora 43. Bootstrap.sh mentions Wofi, roles use Fuzzel (cosmetic).

**Manual steps for Mark (VM proof):**
1. `cd ~/RaBbLE-Collective/RaBbLE-OS && ansible-playbook -i ansible/inventory/vm.hosts.yml ansible/site.yml --syntax-check`
2. `./RaBbLE-OS-vmctl.sh status` / `snapshots` — if `rabble-os-dev` exists, restore snapshot, don't re-cast
3. Fresh proof: `sudo ./RaBbLE-OS-vmctl.sh recast ISO/Fedora-Everything-netinst-x86_64-44-1.7.iso` (~30–60 min), monitor `vmctl logs`, then run `RaBbLE-Grimoire/RaBbLE-OS/verify/RaBbLE-OS-Verify-Checklist.md`
4. Snapshot after success: `sudo ./RaBbLE-OS-vmctl.sh snapshot post-firstboot`

## Known caveats

- Render free tier sleeps after ~15 min idle → ~30–60s cold start on first request. Document as known limitation in release notes (measure warm vs cold).
- Transient classifier outage blocked Bash for parts of this session; sub-agents hit sandbox permission denials on exec — some verification was read-only as a result.

## Next steps (in order)

1. Mark runs the manual Render runbook above → stable Render URL.
2. Dispatch World prod deploy (build NeBuLA IIFE, point chat at Render URL, deploy CDN, verify 9 pages + entity + e2e chat).
3. Mark runs VM recast proof (or accepts static verification for EP1 — his call).
4. Tag all 7 repos `episode-1-v0.0.0.1` (Grimoire, sCoRE, World, NeBuLA, Aether, OS, BaBbLE).
5. Finalize `EPISODE-1-RELEASE.md` (fill placeholders, Railway→Render), apply SESSION-LOG updates from its DRAFT section, commit per Pulse Protocol, run `spells/end-session.sh`.
