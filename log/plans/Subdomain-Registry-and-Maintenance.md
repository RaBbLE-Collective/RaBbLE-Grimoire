# Subdomain Registry + Collective Health — Next Steps

> Written S185 (2026-06-30). Captures the subdomain architecture Mark described
> verbally + a maintenance backlog for post-EP1 and ongoing Collective health.
> These are ideas/proposals — none are decided until Mark acts on them.

---

## 1. Subdomain Registry (`registry/subdomains.yml`)

The Collective has six live or planned subdomains with no central record. Proposal:
add `registry/subdomains.yml` as the authoritative map. Reference it from `status.sh`
and `CONTEXT.md`.

### Proposed structure

```yaml
# registry/subdomains.yml
# Authoritative map of all joinrabble.world subdomains.
# owner: Collective member responsible for this subdomain's content/deploy
# tech:  hosting/delivery mechanism
# status: live | staging | unknown | planned

subdomains:

  - host: joinrabble.world
    label: World — homepage
    owner: RaBbLE-World
    tech: Cloudflare Pages
    purpose: User-facing homepage, entity interaction, chat surface
    status: live
    notes: EP1 landing + chat wired to sCoRE via score.joinrabble.world

  - host: dev.joinrabble.world
    label: World — dev/staging
    owner: RaBbLE-World
    tech: Cloudflare Workers (deploy-dev GitHub Actions workflow)
    purpose: Staging + dev testing for HTML/CSS/JS pages; Xperimental and Chrysalis preview zone
    status: staging
    blocker: B-10 — GitHub Actions deploy-dev job missing CLOUDFLARE_API_TOKEN secret
    notes: |
      Mark to create a scoped CF Workers token:
        gh secret set CLOUDFLARE_API_TOKEN --body <token>
      Workflow + dev domain binding + CLOUDFLARE_ACCOUNT_ID secret already correct.

  - host: score.joinrabble.world
    label: sCoRE — LLM backend
    owner: RaBbLE-sCoRE
    tech: Render (free tier Web Service); subdomain CNAME → Render URL
    purpose: LLM chat API endpoint; all World chat traffic routes here
    status: live
    notes: rabble-score-x7qq.onrender.com; managed via spells/render-ctl.sh

  - host: grimoire.joinrabble.world
    label: Grimoire — MCP + browsable docs
    owner: RaBbLE-Grimoire
    tech: unknown / unverified
    purpose: |
      Dual role:
        (a) Grimoire as MCP server — agents connect here for context retrieval
        (b) Browsable Grimoire — human-readable doc site built from Grimoire markdown
    status: unknown
    notes: |
      Unverified as of S185. Needs:
        1. Confirm if live: curl https://grimoire.joinrabble.world
        2. Determine current tech (Cloudflare Worker? static site? render?)
        3. If MCP is intended: spec and implement (EP2 target unless already wired)
        4. If browsable site: decide generator (static from markdown vs dynamic)

  - host: aether.joinrabble.world
    label: Aether — CSS framework CDN
    owner: RaBbLE-Aether
    tech: Cloudflare R2 + Workers (versioned bundle delivery)
    purpose: CDN delivery of all Aether versions (aether.min.css); also hosts framework docs
    status: live
    notes: |
      v0.0.0.1-rc.1 bundles confirmed HTTP 200 (S153, G3 green).
      Docs: Aether member can serve distilled/user-forward docs that point to
      Grimoire entries (RaBbLE-Aether/ section). Grimoire remains canonical.

  - host: nebula.joinrabble.world
    label: NeBuLA — JS effects CDN
    owner: RaBbLE-NeBuLA
    tech: Cloudflare R2 + Workers (versioned bundle delivery)
    purpose: CDN delivery of all NeBuLA versions (nebula.iife.js); may host NeBuLA Studio + docs
    status: live
    notes: |
      v0.0.0.1-rc.1 bundle confirmed HTTP 200 (S153, G3 green).
      NeBuLA Studio (visual WYSIWYG for Aether + NeBuLA) is EP2 target
      (see project_nebula_refinement_backlog memory).
      Docs: same model as Aether — member docs page points to Grimoire section.
```

### Docs architecture (for aether + nebula + future members with public surfaces)

Mark clarified S185: **Grimoire is the canonical home for ALL docs.** Members may have
independent docs pages (e.g. at their subdomain) but these are distilled / user-forward
views that point back to the Grimoire section — not duplicates. The Grimoire entry is
the source of truth; the member page is the consumer-facing front door.

Pattern to follow:
- `RaBbLE-Aether/docs/` (or `aether.joinrabble.world/docs`) → pulls from `RaBbLE-Grimoire/RaBbLE-Aether/`
- `RaBbLE-NeBuLA/docs/` (or `nebula.joinrabble.world/docs`) → pulls from `RaBbLE-Grimoire/RaBbLE-NeBuLA/`
- Distillation: same gist-style condensation (`distill-gists.sh` as reference pattern)
- No content should live only in a member doc page; always promote to Grimoire first

---

## 2. RaBbLE-OS Install Tiers

Mark described a third install tier not yet formally documented in the registry:

| Tier | Method | Target |
|------|--------|--------|
| ISO | Netinstall ISO download + Anaconda | Any x86_64 machine |
| KS + Ansible | `cast-ks` + Kickstart + Bootstrap.sh | VM or bare metal |
| DE session bootstrap | `bootstrap spell` (new) | Fedora-native install — adds RaBbLE as a session |

The DE session bootstrap (install tier 3) is new. It means a Fedora user can install
RaBbLE-OS as a Hyprland session without wiping their existing OS — lower barrier for
testing. This should be:
- Documented in `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-AgentGuide.md`
- Added to G7 verification options (verify on DE-session tier, not just full ISO install)
- Tracked in `registry/manifests/RaBbLE-OS.manifest.yml` under `install_tiers`

---

## 3. Maintenance Backlog (post-EP1 or parallel)

### EP1-blocking (G7/G9 — Mark-led)

- [ ] **G7** — OS Developer-Preview FLOOR verify: install + boot + recovery on generic x86_64 VM
- [ ] **G9** — `setup.sh` bootstrap end-to-end on fresh machine
- See `log/G7-G9-Verification-Guide.md` for full procedure

### Immediate cleanup (non-blocking, any session)

- [ ] **Drop `.rc-*` aliases** in Aether/World — per-page screenshot parity first; `.rc-*` are
      legacy shims from the Framework Refactor; remove once every P4 page is migrated.
      (`spells/end-session.sh`-era sessions stalled on this — per S182 handoff)
- [ ] **De-dupe Three.js** — loaded by both NeBuLA bundle AND World's floor/graph; "Multiple
      instances" console warning; non-blocking but should be resolved before EP1 air
- [ ] **Fix `account.html` "← chat" link** → points to nonexistent `RaBbLE-Chat.html` (404);
      update to correct route or remove link (raised S183, open)
- [ ] **B-10** — `dev.joinrabble.world` deploy: add `CLOUDFLARE_API_TOKEN` secret to GitHub Actions
      (`gh secret set CLOUDFLARE_API_TOKEN --body <token>`) — Mark-led

### Collective coordination improvements (EP2 targeting)

- [ ] **`spells/ep1-status.sh`** — single terminal command that shows all 10 gate rows from
      EP1-AIR-CHECKLIST.md, open ep1-gate blockers, and member readiness in one table.
      Eliminates the cross-file hunting described as the ad-hoc session problem.
- [ ] **`status.sh` enhancement** — pull in subdomain liveness check (curl each subdomain,
      report HTTP status) alongside the existing branch/clean health.
- [ ] **Grimoire.joinrabble.world** — verify if live; if not, decide EP1 vs EP2 target.
      MCP endpoint is EP2 (post-entity); browsable docs site may be EP1.
- [ ] **Session number tracking** — end-session.sh currently infers session number from
      SESSION-LOG. A lightweight counter file (`log/.session-counter`) would make inference
      exact and remove the "SNN" fallback.

### Documentation gaps

- [ ] **Subdomain registry** — implement `registry/subdomains.yml` (spec above in §1)
- [ ] **Member docs architecture** — write a short protocol in Grimoire for the
      "member docs page points to Grimoire section" pattern; wire into `init-project.sh`
      so new members get the template
- [ ] **OS install tiers** — add tier 3 (DE session bootstrap) to OS AgentGuide + manifest
- [ ] **distill-gists.sh** — run after this session's doc changes to keep gist/ current:
      `bash spells/distill-gists.sh`

---

## 4. Episode 1 Air — Current State

Only two gates remain:

| Gate | State | Owner |
|------|-------|-------|
| G7 | ⏳ verify | Mark (VM required) |
| G9 | ⏳ verify | Mark (fresh machine required) |

All other gates green. Once G7 + G9 flip ✅, run the air procedure in
`log/EP1-AIR-CHECKLIST.md §D`.

---

## Priority order (suggested)

1. Mark runs G7/G9 (gates EP1 air)
2. B-10 CF token (unblocks dev.joinrabble.world auto-deploy)
3. Drop `.rc-*` aliases + Three.js de-dupe (clean EP1 codebase)
4. `registry/subdomains.yml` (cheap, high orientation value)
5. `spells/ep1-status.sh` (operational quality-of-life)
6. Grimoire.joinrabble.world investigation
7. Member docs architecture write-up
