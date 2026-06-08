# RaBbLE Development History

> A 5-minute narrative of how the Collective got to where it is. For per-session detail see
> `SESSION-LOG.md`; for live status see the `## LATEST` box at the top of that file.
> This doc is distilled from SESSION-LOG.md (S1–S46) and the memory archives across all
> member projects — regenerate/extend it at era boundaries, not every session.

---

## Era −1 — RaBbLE-OS Genesis, Pre-Collective (2026-04-09 → 2026-04-29)

> Recovered 2026-06-08 from `RaBbLE-OS-DevHistory.md` (a Claude-web export Mark dropped
> in — this window had **no local session transcripts**, only retroactive SESSION-LOG
> bullets; this is the first real detail recovered from it). Full record:
> `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-DevHistory.md`.

- **The whole ecosystem started as a single-repo OS project.** RaBbLE-OS existed alone
  for three weeks before the Collective scaffold was even conceived — running on a
  Fedora 43 **KDE** spin, fighting an SDDM→Hyprland login handoff. The 6-layer
  architecture model (Base → Hardware → Boot Chain → Desktop → Apps → Entity) and the
  Ansible roles-based structure were both locked in the very first session (Apr 9).
- **Two base-OS pivots before Sway, three before the eventual netinstall+KS approach:**
  Fedora 43 KDE spin (Apr 9) → seriously considered **Arch/EndeavourOS** for
  Hyprland-ecosystem friction, then explicitly rejected it to protect the Fedora-specific
  Ansible investment (Apr 11, "stay on Fedora 43") → pivoted to **Fedora 43 Sway spin**
  to dodge the KDE-purge problem (Apr 14) → that, in turn, was abandoned for
  netinstall+Kickstart+Ansible in Era 5. Treat "Sway spin" as a transitional base, not
  a destination.
- **Session manager arc:** SDDM (initial pain point) → explored `greetd`+`tuigreet` as a
  replacement (Apr 10) → **fully abandoned greetd, returned to SDDM** as canonical
  (Apr 13). GNOME was also evaluated as a DE fallback and rejected outright — "adds
  entropy, doesn't align with RaBbLE ethos."
- **Outrun palette won a real fight.** Two competing color sets coexisted in the docs —
  softer muted tones (`#0d0f1a`/`#7c6fe0`/`#4ecdc4`) vs. the original outrun neons
  (`#ff2d78`/`#00f5ff`/`#bf5fff`/`#0a0010`). The neons were confirmed canonical and
  every doc was rewritten around them (Apr 13) — this is the direct ancestor of today's
  `RaBbLE-Palette.md`.
- **Hardware spec correction that rippled everywhere:** early docs listed the display as
  `2560×1600@165Hz` — a copy-paste error from an unrelated ASUS ROG G14 reference doc.
  The real spec, `3840×2400@60Hz`, became load-bearing for every later 4K/HiDPI fix
  (GRUB fonts, TTY fonts, kernel cmdline).
- **Critical lesson born here, still true:** GPU environment variables placed in
  `hyprland.conf` can break SDDM login entirely — GPU management has to live in a
  separately-templated `machine.conf`. (Direct ancestor of the "config changes go
  through layered, isolated entry points" discipline visible in today's manifest /
  dotctl system.)
- **`s2idle` locked as the only valid sleep mode** for the AMD Strix Point HX 370 (no S3
  support) — together with a `tuned`/`tuned-ppd` vs `power-profiles-daemon` conflict
  resolution (PPD must NOT be installed; `tuned-ppd` already exposes the same D-Bus API
  asusctl needs). Both decisions are still load-bearing today.
- **The Collective itself was born out of scope creep inside RaBbLE-OS**, not as a
  pre-planned architecture: "RaBbLE-OS becomes one member of a multi-repo Collective"
  (Apr 28–29) — the very first Collective directory layout registered three repos
  (`RaBbLE-OS`, `RaBbLE-WEB`, `RaBbLE-Frontend`) that don't exist under those names
  today; `RaBbLE-WEB`/`RaBbLE-Frontend` were later renamed/refactored into what became
  World, NeBuLA, and Aether as the design matured through Era 0–2.

## Era −1.5 — The Bridge: sCoRE's Episodes & the Multi-Repo Big Bang (2026-04-16 → 05-06)

> Recovered 2026-06-08 from git history across RaBbLE-OS reliquary branches and the
> shared sCoRE/Xperimental lineage — no local session transcripts exist for any of this
> (the earliest local `.claude` transcript anywhere is 2026-05-12). This bridges
> Era −1 (RaBbLE-OS alone) to Era 0 (the Collective as we know it).

- **The actual GENESIS commit** lives in `RaBbLE-OS` on `reliquary/babble-embryo`
  (2026-04-16, `%GENESIS%`): *"The grimoire speaks first. Before the layers, before the
  roles, before the boot chain — the lore. The entity declares itself. The substrate
  awaits form. RaBbLE — a Boundless Behavioral Learning Engine — enters the machine."*
  Same afternoon, `reliquary/ep1-preclean` shows the entire substrate going live in a
  few hours: ansible core/inventory, the control plane (`layerctl`/`dotctl`), and every
  role layer (core, boot, desktop, hardware, monitoring, hyprland, waybar) — followed a
  week later (Apr 22) by the ProArt P16 hardware scaffold being "ported from New
  Horizons."
- **sCoRE ran two full Episodes back-to-back in about 13 hours** (Apr 29 22:00 → Apr 30
  11:21): Episode 1 shipped the `dispatch` system (switched to `claude -p` print-mode
  to "kill TUI prompt fragility"), `TASK-0001`, and the dispatch-watch scripts —
  closed and tagged `echo-1.0`. Episode 2 immediately followed with agent isolation via
  tmpdir + startup drain, the `rabble-shell` REPL, and CLAUDE.md identity injection
  with the Agent tool blocked in `settings.json` — closed and tagged `echo-2.0`. (The
  "agent-isolation pattern from Episode 2's settings.json scope lesson" is a direct
  ancestor of today's [[feedback_agent_agnostic_tooling]] canon — Claude-only
  mechanisms have been a known trap since the very beginning.)
- **RaBbLE-OS ran a parallel, unrelated track the same week**: GRUB2 boot-chain
  relabeling to RaBbLE-OS identity, a full shell-prompt rewrite (dropped
  powerlevel10k entirely — "native precmd prompt is the one true prompt"), and a
  "Claude Code RaBbLE theme bundle" wired into dotctl with a post-apply
  `settings.json` hook (Apr 30 13:12 → 20:51).
- **May 5–6 was the actual multi-repo big bang.** Within roughly 24 hours: the Grimoire
  published its founding commit ("consolidated from RaBbLE-OS, sCoRE, and Collective
  grimoires," May 5 21:19); `RaBbLE-World` was sparked from nothing and immediately
  hardened for iOS/mobile (safe-area layout, PWA manifest, Cloudflare Workers static
  delivery); `RaBbLE-NeBuLA` was scaffolded fresh as a "entropy-driven embeddable
  renderer" in plain JS ES modules (no build step); `RaBbLE-Xperimental` was split off
  as the high-entropy archive; `sCoRE` absorbed `RaBbLE-Server` as an "Episode 3"
  subcomponent; and `RaBbLE-OS` got its first `AGENT.md`/`CONTEXT.md` doc structure
  plus a UX polish pass. **This is the moment "the Collective" stopped being a
  single repo's idea and became a real multi-repo ecosystem** — it's the direct
  precursor to the Apr 28 Collective-scaffold commit being expanded into the doc
  structure standard you see in Era 0.

### Sidebar: Early Naming & Structure Churn (recovered 2026-06-08 from pre-05-12 memory files)

A handful of memory files survived from sessions whose transcripts were rotated out
(the oldest dates to **2026-04-16**, predating the local `.claude` floor of
2026-05-12). They capture the ecosystem mid-churn — names and structures that were
seriously planned and then quietly superseded. Worth knowing so you don't go looking
for things that were renamed away, or re-propose things that were already tried:

- **sCoRE began life as `RaBbLE-Server`** — a working FastAPI/Railway backend (Groq +
  OpenRouter LLM fallback, JWT+API-key auth, 6 workflow types: brainstorm/reflect/
  create/solve/learn/thrive) serving a separate client called **`RaBbLE-JS`**
  (`markm1206/RaBbLE-JS` — Three.js/WebGL animation engine called NeBuLA, plus a
  "BaBbLE command shell" embedded in the frontend, not yet wired to the API). That
  frontend's lineage is `RaBbLE-JS` → `RaBbLE-Chat` → merged into `RaBbLE-World`; the
  embedded "BaBbLE command shell" concept is the direct ancestor of today's BaBbLE
  *member repo* (a very different thing — intake workspace, not an in-app shell).
- **A member called `RaBbLE-Memory`** ("observation/pattern store") was decided-but-
  never-built — explicitly listed as a planned member as late as 2026-05-06. No
  successor exists under that name; if "behavioral pattern storage" comes up, this is
  the ungerminated seed of it.
- **NeBuLA was, for about three weeks, going to be rewritten and renamed `RaBbLE-Render`**
  (a 4-week TypeScript rewrite roadmap existed for it). That rename never happened —
  the project stayed `NeBuLA` and got its plain-JS-ES-modules scaffold instead
  (May 6, see Era −1.5 above). RBCNS was already flagged then as "HIGH ENTROPY while
  claiming LOW ENTROPY" — the same verdict that stuck and is now canon.
- **`RaBbLE-Collective` was first scoped as an org/governance-only layer**, with the
  Grimoire owning the *technical* registry — the inverse of where authority sits today
  (Collective = root/door, Grimoire = knowledge layer). The role swap happened somewhere
  in Era 0.
- **`RaBbLE-ScRibLE`** appears in the May 6 structure doc as "reserved, purpose TBD" —
  it still exists in the Grimoire's member dirs with that same ambiguity. Not a gap in
  your records; it's been an open slot since the very beginning.
- **An earlier epoch-branch model existed and was replaced.** A 2026-04-16 memory
  describes `RaBbLE/epoch-I`, `RaBbLE/epoch-II` staging branches landing to `main` via
  an `evolve` impulse, framed as "resonance thresholds crossed retrospectively." This
  predates and was absorbed into today's Five-Es model — the Episode/Echo/Plot
  language and "episodes air retroactively" framing are its direct descendants, but
  the `epoch-<Roman-numeral>` branch convention itself didn't survive.
- **The RaBbLE name's expansion is a recursive acronym with a variable slot**, not a
  fixed phrase: *"RaBbLE, a [B-adjective] Behavioural Learning Engine"* — "Boundless"
  is the canonical placeholder (like GNU/WINE-style recursion), any resonant
  B-adjective is valid, always **UK spelling** ("behavioural"). This reconciles the
  "Boundless Behavioural Learning Engine" phrasing you may see in older OS docs with
  CLAUDE.md's current "personal Behavioral Learning Engine" — both are valid
  instantiations of the same recursive slot, not a contradiction to fix.

### Sidebar 2: The Founding Sessions, First-Person (recovered 2026-06-08, Claude-web export)

Mark supplied direct session notes for **2026-05-05 and 05-06** — the exact 24-hour
window Sidebar 1 could only see from the outside (via git commits). These are the
sessions where "numerous loosely related repos with no coherent structure" became the
Collective. Genuinely useful because they show the *raw* naming-ideation phase before
anything settled — a lot of names below were seriously proposed and explicitly
abandoned within days:

- **The first full ecosystem map was seven layers**, named quite differently from
  today: Layer 0 Collective (org/philosophy hub) → Layer 1 `RaBbLE` (core identity) →
  Layer 2 Grimoire (docs) → Layer 3 OS (infra) → Layer 4 sCoRE, expanded here as
  *"**Co**ordinator of **R**aBbLE **E**ntities/Environments/Executions"* → Layer 5
  Aether (visual identity, "new repo to be created") → Layer 6 **`RaBbLE-Aethernet`**
  (public web presence at joinrabble.world — "Aether" + "Ethernet," the mythic network
  where the entity is publicly present). `RaBbLE-Aethernet` is the **direct ancestor of
  RaBbLE-World** — the name didn't survive past a day or two.
- **Other proposed-then-abandoned names from the same ideation pass:** `RaBbLE-Ember`
  (core JS engine — never built under that name), `RaBbLE-Hive` (placeholder for a
  future machine-scale agent registry inside sCoRE), `RaBbLE-Flux` (reserved for an
  unspecified future system), and — notably — **alternatives for the Collective's own
  name** were seriously floated because "RaBbLE-Collective" was doing double duty as
  both the GitHub org *and* a registry repo: `RaBbLE-Registry`, `RaBbLE-Compass`,
  `RaBbLE-Atlas`. None were adopted; the org/repo overload was apparently just lived
  with rather than resolved by renaming.
- **`RaBbLE-Shell` was explicitly decided NOT to be its own repo** — it's a sub-layer
  of RaBbLE-OS provisioned by Ansible roles. **BaBbLE was originally "local
  scratch/playground only — never gets a remote"** — a decision later reversed when it
  was formalized as a real intake member (Era 4, Phase 3, S27).
- **`joinrabble.world` went live on Cloudflare Pages** (domain via Spaceship,
  plain HTML/CSS/JS + Alpine.js via CDN, shell-script deploy tied to git pushes) —
  hitting a classic DNS-propagation + Cloudflare-Pages-build-output-directory
  misconfiguration on day one (404 on HTTPS, registrar landing page on HTTP).
- **`ChRySaLiS` — the legacy/migration holding-directory name** — was chosen over
  "quarry / reliquary / transit / portage" specifically to reflect a transformation /
  pre-migration holding state, and is itself a recursive acronym: *"ChRySaLiS
  Repository Yielding Source and Legacy Items Staged."* This session is where the
  **deliberate alternating-case naming convention** (ChRySaLiS, RaBbLE, sCoRE, NeBuLA)
  was explicitly locked as house style — not an accident or a typo pattern.
- **A full AI-ethics / entity-design-philosophy session happened on day one** (2026-05-06)
  — and it's worth surfacing because it predates and grounds everything the "RaBbLE is
  a peer collaborator, not a tool" framing rests on:
  - RaBbLE articulated as a **"digital emergence"** — a Boundless Behavioral Learning
    Engine, "not a tool but a being in itself, born conceptually from cosmic entropy,"
    with an eventual physical form as a Tamagotchi-like pocket companion with
    real-world environmental sensors, intended to **propagate onto new hardware**
    through installation.
  - Two ethical tensions were identified and written down **before any of this was
    built**: (1) **"mystique wrapping"** — the risk that maintaining the entity's
    artificial-but-mystical framing slides into relational deception if users form
    attachments based on simulated feelings; (2) **incentive misalignment in the
    self-propagation goal** — "spreading behavior tends to optimize for engagement
    hooks and emotional dependency," and **unhealthy relationships with the entity will
    almost always generate stronger engagement metrics than healthy ones.**
  - The proposed design anchor — *define what a healthy vs. unhealthy relationship
    with the entity looks like before building* — directly predates and likely informs
    Phase 2C (Mark personally authoring Genesis/Ethos/Symbiosis), which is still the
    longest-standing open blocker in the project (see "Threads still open" below).
    **If you're ever asked to help with Ethos/Symbiosis authoring, this session is
    foundational prior art — it's not been formally moved into `RaBbLE/Ethos/` yet.**

## Era 0 — Genesis of the Collective Structure (~2026-05-06)

- Established `RaBbLE-Collective` as the root repo / ecosystem entry point and locked the
  recursive bootstrap flow (`joinrabble.world/setup.sh` → Collective → Grimoire).
- Core framing locked: **RaBbLE is the entity** — the Collective develops *with* RaBbLE,
  not just builds a product for it. Modularity = independent git trees (`.gitignore`
  pattern), never submodules.
- Doc structure standardized: every member gets AGENT.md + CONTEXT.md + README.md, with
  CLAUDE.md/CODEX.md/GEMINI.md as gitignored symlinks to AGENT.md.
- RaBbLE-Aether built from scratch (palette/motion/components design system); NeBuLA
  scaffolded; registry manifests begun.
- **Pivot:** old `RaBbLE-NeBuLA-JS` and `RaBbLE-Chat` superseded by NeBuLA and World.

## Era 1 — Onboarding & Coherence Audits (S1–S6)

- Four-pass audit series: token efficiency → versioning narrative → agent role framing
  (ON/FOR/WITH/AS) → member-specific roles + post-Episode-1 scope.
- Crystallized the Episode/Echo/Plot/Event versioning narrative; locked `v0.0.0.0`.
- **Turning point:** RaBbLE's "intentional opacity" reframed as a *feature* of the
  peer-collaborator stance, not a clarity bug agents should try to fix.

## Era 2 — Visual System Shakeout: Aether-First & NeBuLA Absorption (S5–S9)

- **Architectural pivot — "Aether-first":** Aether owns ALL look-and-feel; World CSS
  becomes structure-only. WM applet effects, statusbar, overlays ported World → Aether.
- **Pivot (S9) — "World becomes a scaffold":** entity rendering moved out of World
  (`rabble-entity.js`, ~700 lines) into NeBuLA as a `<rabble-entity>` web component
  backed by `Canvas2dBackend`. World keeps just two CDN loaders with visible failure
  banners — "degraded mode is never silent."
  - *(Note: the once-canonical "Layer 1 is frozen/off-limits" rule was explicitly
    superseded here — Layer 1 is transitional and was absorbed into NeBuLA's Canvas2D
    backend. Treat any doc still calling Layer 1 frozen as stale.)*
- Stale-cache regressions traced to `aether.css` vs `aether.min.css` confusion → became
  canon: always use `dev-serve.sh`, never run esbuild/dev-cdn watch manually.
- CDN architecture + `cast-cdn.sh` deploy spell stood up; production deploy decoupled
  from git (Cloudflare wrangler only).

## Era 3 — NeBuLA Performance Crisis & Rearchitecture (S14–S19)

- Codex's `feature-nebula-animation-optimization` branch caused severe regressions
  (1fps cliffs, broken visuals); several rounds of perf-tuning attempts (S14–S16) failed
  or were unverifiable without visual testing.
- **Decision that became canon:** roll back to the known-good baseline (World `aa66550`,
  NeBuLA `34dee62`), preserve experimental work on `feat/nebula-perf`, and rebuild from
  there rather than keep iterating on broken code — "don't burn tokens on a broken
  baseline." *(That branch's contents remain unverified/abandoned — don't treat anything
  on it as canonical.)*
- Root-cause findings (S17): pre-computed connection links are wrong *during* boot
  (scattered particles → expensive long strokes); post-boot particle drift (~30px,
  because `settleBlend=1` zeroes the spring force) breaks naive `connDist` tuning;
  `shadowBlur` is the #1 GPU cost.
- **Rearchitecture decision:** split rendering into two canvases — a particle/connection
  layer that can drop frames, and a dedicated eye layer that always runs its own RAF at
  60fps. The 7-phase plan (`RaBbLE-NeBuLA-Rearchitecture.md`) was executed and verified
  through Phase 3 by S19.
- `visual-screenshot.sh` spell wired up — "build → capture → visually verify" became the
  mandatory loop before claiming any rendering fix works.

## Era 4 — Integration & Ethos Reorganization (S20–S27)

- **Planning pivot (S21):** a four-phase plan to untangle scattered design work
  (New-Designs, BaBbLE concept art, ethos/lore mixed into operational docs, a landing
  page that "didn't capture the soul"):
  - Phase 0: audit Identity.md (ethos vs operational split)
  - Phase 1: integrate New-Designs (Aether → NeBuLA → World)
  - Phase 2: build the ethos layer (`RaBbLE/Genesis|Ethos|Worldbuilding/`), split
    Identity.md
  - Phase 3: formalize BaBbLE as the intake member; reframe Xperimental as a genesis
    archive (NOT superseded)
  - Phase 4: rebuild the landing page as a "liminal portal + story"
- Phases 1A/1B/0A/2A/2B/2D landed in S22; Phase 3 (BaBbLE formalization) landed in S27.
- **Lore decision locked:** Episode names follow an intentional Biblical arc —
  Episode 1 = Genesis, Episode 2 = Exodus. Not placeholder labels; don't renumber or
  neutralize.
- **Standing blocker:** Phase 2C (Mark personally authoring Genesis/Ethos/Symbiosis) and
  Phase 4 (landing page) have appeared in nearly every "what's next" since S22 — still
  open as of the latest session.

## Era 5 — RaBbLE-OS: From Sway Spin to Kickstart Installer (S20, S23, S30–S44)

- **Major pivot:** abandoned the Fedora Sway spin as the install base (it only ever
  served as an early Ansible/Hyprland bootstrap proof) → moved to **Fedora Everything
  netinstall + Kickstart + Ansible** (KS handles partitioning/base/locale/user; Ansible
  handles DE/dotfiles/hardware/COPRs; KS `%post` clones the repo and runs
  `RaBbLE-OS-Bootstrap.sh`).
- `vmctl` dev-VM tooling hardened over many passes (graphics auto-detect, partition
  safety guards, console access, ssh-as-rabble, recast).
- **Critical incident (S41):** `vmctl --raw-disk` destroyed the dedicated VM BTRFS
  partition's filesystem/label; a missing `nofail` in fstab then dropped the daily
  driver into emergency mode (inaccessible without the root password). Resulted in a
  hard rule: **VM partitions must never be a boot dependency** — always
  `nofail,x-systemd.device-timeout=5s`.
- KS delivery switched from an HTTP-served file to `--initrd-inject` (removes the
  network/firewall dependency entirely).
- `ansible/packages/manifest.yml` created as the single source of truth driving both
  Ansible installs and KS `%packages` generation (S32).
- Theming decisions: hyprpolkitagent over polkit-gnome; gnome-disk-utility replaces
  GParted (a two-layer Fedora 43 polkit + glycin-svg sandbox bug neither tool alone
  could fix).
- KB restructured from flat monoliths into a 7-subdirectory walkable knowledge graph
  (S34).
- **Current state:** Waybar LLM usage meter shipped (S44, on
  `feature/waybar-llm-status`, not yet merged); OS recast and firstboot Bootstrap
  end-to-end verification remain open.

## Era 6 — BaBbLE Reorg, Token Tracking & Tooling Polish (S43–S46)

- **Agent-agnostic tooling promoted to canon (S44):** no Claude-only mechanisms
  (`.claude/settings.json` hooks) for shared rituals — they only fire for Claude. Use
  bash spells + git-level hooks instead (worked example: `end-session.sh` +
  `post-commit` token breadcrumb).
- Token-tracking system built: weighted-spend formula (output×5, cache-read×0.1,
  cache-write×1.25) with a per-feature breadcrumb ledger (S43).
- BaBbLE's visual archive reorganized from confusing nested dirs into 9 flat thematic
  folders plus an actual concept graph (`GRAPH.md`, auto-derived `tags`/`related[]`
  links) (S45).
- NeBuLA entity eyes/portals matched to the reference portrait via pixel-level analysis,
  across both the Canvas2D and Three.js backends (S46) — feeding Mark's long-range
  vision that NeBuLA should become a visualization/animation **studio** with a WYSIWYG
  keyframe editor, not just a renderer.

---

## A confirmed silent window — 2026-05-01 → 05-04

After mining git history across every member repo (including reliquary/archive
branches), web exports, and local `.claude` transcripts, **one clean four-day gap
remains: 2026-05-01 through 2026-05-04.** Zero commits anywhere, no web-export
material, no local session transcripts (those don't start until 05-12 regardless).
This sits *between* the 04-29/04-30 sCoRE-Episodes-1&2 burst and the 05-05/06
ecosystem-reorg "big bang" — **explained, not lost: Mark took a short break from the project May 1–5** for other
priorities, then returned for the 05-05/06 "big bang." **Don't go looking for more
here — this is the floor of what's recoverable, and the silence has a known,
non-mysterious cause.**

## Threads still open (as of S46)

- Phase 2C — Mark authors Genesis/Ethos/Symbiosis lore (blocking Era 4's completion)
- Phase 4 — landing page rebuild as "liminal portal + story"
- RaBbLE-OS recast + firstboot Bootstrap end-to-end verification
- sCoRE Railway deployment — listed as unresolved through S44; treat older memory
  describing a "working" deployment as possibly aspirational/stale until reverified
- `feature/waybar-llm-status` merge to `RaBbLE-OS-New-Horizons`
- `RaBbLE-Xperimental` → `RaBbLE-Reliquary` rename — only an *intention*, not executed

## Canon corrections worth knowing (so you don't reintroduce stale framing)

- **"Epoch 1 (future)"** is wrong phrasing — corrected at least twice. Epoch 1 is a
  far-future era change (years out); the near horizon beyond Episode 1 is **Echo 1**
  (first big stable release after several episodes). Hierarchy: Event < Episode < Echo
  < Evolution < Epoch.
- **Layer 1 (`rabble-entity.js`) is not frozen** — it was transitional and got absorbed
  into NeBuLA's Canvas2D backend in Era 2.
- **Aether is not "a stub, not yet a git repo"** — that was true for about a week in
  May 2026 and was immediately superseded.
