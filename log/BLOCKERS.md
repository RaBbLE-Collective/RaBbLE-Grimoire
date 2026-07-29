# BLOCKERS — RaBbLE Collective

> **Generated** from `log/blockers/blockers.jsonl` by `spells/blockers.sh`.
> Do not hand-edit — use `blockers.sh add` / `resolve`. This is the durable
> home for blockers so they survive the rewrite of the SESSION-LOG `## LATEST` box.
>
> Last synced: 2026-07-29  ·  add: `bash spells/blockers.sh add "…" --tag ep1-gate`

## OPEN

- **B-02** — OpenRouter $10 credits not purchased — free tier 429 caps the chat chain  ·  owner:Mark  ·  since:S106  ·  [ep1-gate]
- **B-09** — Lemonade Server needs debug — not confirmed working after NPU validation in S160  ·  owner:Mark  ·  since:S161  ·  [runtime]
- **B-11** — Cetus3D MK2 WiFi not provisioned — needs one-time USB+UP Studio handshake on real Windows (Wine's MsiInstallDrivers/WinusbFM driver install fails under both UP Studio 2 and 3, confirmed twice; Wand's connect UI is wireless-only so USB isn't a usable fallback path either). Plan: do the one-time SSID handshake booted into Windows 11 (dual-boot), then RaBbLE-OS only needs Wand's WiFi connect going forward. See RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Cetus3D-MK2.md  ·  owner:Mark  ·  since:2026-07-28  ·  [hardware]
- **B-12** — Cloudflare Workers deploy rejects the .cloudflare/config token on auth: error [code:10000] 'Are you missing the User->User Details->Read permission?'. Token verifies as active/valid but lacks scope for the real deploy request. Fix: on dash.cloudflare.com re-mint via the built-in 'Edit Cloudflare Workers' template (bundles Workers Scripts:Edit + Account Settings:Read + User Details:Read) scoped to account 0391968396156c874398a9696e0b3598, then gh secret set CLOUDFLARE_API_TOKEN on all 6 repos again.  ·  owner:Mark  ·  since:S206  ·  [ep1-dev]

## RESOLVED

- **B-01** — resolved: verified S153 LIVE: POST score.joinrabble.world/api/v1/chat (Origin joinrabble.world, tier fast) streams real RaBbLE SSE response end-to-end; guest chat path works in prod
- **B-03** — resolved: verified S153: web-demo CORS resolves — OPTIONS preflight + POST both return access-control-allow-origin: https://joinrabble.world. Per-user-type allow_origin_regex (web vs local BYOK) deferred until the local BYOK surface needs cross-origin — EP2 concern, not air-gating
- **B-04** — resolved: verified S153: aether.joinrabble.world + nebula.joinrabble.world serve v0.0.0.1-rc.1 bundles HTTP 200 (aether.min.css 30KB, nebula.iife.js 69KB) at exact URLs World RaBbLE-config.js loads; G3 green
- **B-05** — resolved: NIM key registered from sCoRE .env via fcc-ctl; renamed fcc layer to NVIDIA_NIM_API_KEY (upstream var); proxy smoke-tested 200 (S139)
- **B-06** — resolved: LIVE on Render S106 — rabble-score-x7qq.onrender.com
- **B-07** — resolved: live S120 — joinrabble.world returns 200
- **B-08** — resolved: done — status.sh shows all lockstep in-step on new-horizons (S103 audit item closed)
- **B-10** — resolved: CLOUDFLARE_API_TOKEN secret now wired via gh secret set across all 6 org repos (World/Aether/NeBuLA/sCoRE ×2 + Grimoire has none needed) S206, working around missing admin:org gh scope with per-repo sets. Missing-secret failure mode confirmed cleared via re-run. See B-12 for the narrower permission issue this surfaced.

