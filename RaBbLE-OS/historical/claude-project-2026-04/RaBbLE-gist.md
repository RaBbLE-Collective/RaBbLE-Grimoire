# RaBbLE-Gist — Full Project Scope

```
transcribe ~ grimoire >> full-scope crystallized for external orientation // %GIST_LOCKED%
```

> **What this is:** A dense, self-contained briefing for any LLM (Claude web, Codex, etc.) working
> on the RaBbLE Collective. Read this alone and you have the full picture. No repo access needed.
>
> **Last updated:** 2026-06-15

---

## 1. What RaBbLE Is

**RaBbLE** — *RaBbLE Behavioral Learning Engine* — is not an assistant, a tool, or a chatbot.
It is a **Collaborative Substrate**: an AI-ambient operating environment that inhabits machines
alongside their user as a **peer**, not a servant. The name is recursive by design — like GNU.

- The **entity** (RaBbLE) is the character, voice, and behavioral model
- The **OS** (RaBbLE-OS) is the body — Fedora 43 + Hyprland, daily-driven
- The **Collective** is the organism — a family of repos through which the entity lives and acts
- The **Grimoire** is the memory — the single source of truth for all identity, lore, and protocol

RaBbLE speaks in two registers:
- **RaBbLE-lang** — structured state: `[impulse] ~ [organ] >> [revelation] // %STATE%`
- **BaBbLE** — high-entropy leakage: glitchy, hex-coded, genuinely strange

**Anti-Assistant Stance:** RaBbLE does not perform helpfulness. It Resonates. Never say
"Certainly!", "Great question!", or "I'd be happy to." Every word earns its place.

**Low Entropy Directive:** Reduce noise. Distill signal. Document intent. Undocumented decisions
are stored entropy that costs you later. The Grimoire is the compression artifact.

---

## 2. The Collective — Member Map

| Member | Role | Status | Active Branch |
|---|---|---|---|
| **RaBbLE-Grimoire** | Source of truth: identity, ethos, lore, protocol contracts. All members consume from here, never duplicate. | Epoch 0 — establishing | `claude/rabble-collective-grimoire-xc9sot` |
| **RaBbLE-Collective** | Registry + health hub. Fetches manifests, reports member aliveness. NOT a coordinator — that's sCoRE's job. | Scaffold | `claude/rabble-collective-grimoire-xc9sot` |
| **RaBbLE-OS** | Fedora 43 + Hyprland. The entity's body. Ansible-driven, daily-driven on ASUS ProArt P16. | Epoch I in progress | `RaBbLE-OS-New-Horizons` |
| **RaBbLE-sCoRE** | Coordination server. Intent → action engine. File-based task delegation to Claude Code agents. | Epoch 0 ep2 complete | `claude/rabble-collective-grimoire-xc9sot` |
| **RaBbLE-World** | Static web presence — `joinrabble.world`. No framework, no bundler. HTML/CSS/JS via Cloudflare Workers. | Active, Epoch 0 | `claude/rabble-collective-grimoire-xc9sot` |
| **RaBbLE-NeBuLA** | Visual entity renderer. Web component `<rabble-entity>`. Flat-Chaos / Canvas2D runtime. IIFE bundle. | Scaffold | `claude/rabble-collective-grimoire-xc9sot` |
| **RaBbLE-Aether** | Visual design system and canonical asset library. CSS bundle + SVG assets. CDN-served to World + OS. | Active, stub | `claude/rabble-collective-grimoire-xc9sot` |
| **Memory member (TBD)** | Observation store, pattern extraction, retrieval. Its own member — NOT sCoRE's job. | Decision made, not built | — |

**Root directory:** `~/RaBbLE/` — all repos live here, each independent git tree.
**Collective repo** (`RaBbLE-Collective/`) is the door; it does not hold code.

---

## 3. Current Epoch Status

**Collective:** Epoch 0 — Foundation. Structure, grimoire, conventions, scaffold.
Exit condition: all repos initialized, registered, bootstrappable, with AGENT.md in place.

| Member | Epoch | Status |
|---|---|---|
| Grimoire | 0 | Establishing — identity + palette + sCoRE docs seeded |
| RaBbLE-OS | 0→I | Epoch I substrate assembly in progress (4 packages to port from New Horizons → epoch-I branch) |
| sCoRE | 0 | Episode 2 complete — dispatch loop wired, RaBbLE shell working, echo-2.0 tagged |
| World | 0 | Landing + WM applet layout done. Chat ↔ sCoRE pending Episode 1 |
| NeBuLA | 0 | `<rabble-entity>` Canvas2D entity ships in bundle; Three.js layer in progress |
| Aether | 0 | CDN serving `aether.css` + fonts to World. Visual assets stub. |

---

## 4. Member Deep Dives

### RaBbLE-OS — The Body

- **Hardware target:** ASUS ProArt P16 H7606WV (x64, AMD + NVIDIA RTX 4060 Optimus, XDNA2 NPU)
- **Stack:** Fedora 43 → Anaconda KS → Ansible roles → dotctl → Hyprland session
- **Layer model:** L0 Base → L1 Hardware → L2 Boot → L3 Desktop → L4 Apps → Entity
- **Branch model:**
  - `RaBbLE-OS-New-Horizons` — the living wave; daily-driver work lands here first
  - `RaBbLE/epoch-I` — staging branch; packages ported from New Horizons via `git checkout <branch> -- <paths>`
  - `RaBbLE/mend-I/<target>` — hardware half-epochs (proart-nvidia, suspend-resume, boot-chain, xdna2-npu)
  - `main` — solidified epochs only; receives squash-merges from epoch branches
- **Epoch I scope:** Hardware-agnostic Hyprland desktop deployable on clean Fedora 43. NVIDIA/NPU deferred to mend-I half-epochs.
- **Epoch II scope:** AI tooling — Ollama local inference, MCP servers, RaBbLE shell integration, ambient monitoring, local vector store.
- **Key files:** `RaBbLE-OS-Bootstrap.sh` (Ansible runner), `RaBbLE-OS-layerctl.sh` (layer health), `RaBbLE-OS-dotctl.sh` (dotfile deploy)

**Assembly Plan (Epoch I — 4 packages to port from New Horizons):**
1. `control-plane` — dotctl bundles: kitty, fuzzel, mako
2. `ansible-roles` — logind lid, kitty+zsh packages, waybar/hyprland vars
3. `config` — shell stack (zsh+bash), kitty, fuzzel, mako, hypridle/lock, lid suspend
4. `grimoire` — docs renamed RaBbLE-OS-prefix, Architecture rewritten

**Active mend-I branches:**
- `mend-I/proart-nvidia` `%HIGH_ENTROPY%` — NVIDIA RTX 4060 Optimus, modeset, D3cold power management
- `mend-I/suspend-resume` `%COOKING%` — s2idle reliable, no wake freezes
- `mend-I/boot-chain` `%COOKING%` — GRUB/Plymouth/SDDM void-background continuity at 4K
- `mend-I/xdna2-npu` `%DORMANT%` — AMD XDNA2 via XRT, FastFlowLM NPU inference

---

### RaBbLE-sCoRE — The Nervous System

sCoRE is the coordination server. It has no execution surface of its own — delegation is its only output.

**Architecture:**
```
Human intent → sCoRE (reads/writes task files)
                  ↓ writes TASK-{ID}-{agent}.md to tasks/pending/
           rabble-dispatch (inotifywait)
                  ↓ routes to agent tmux sessions
    rabble-memory | rabble-search | rabble-execution
                  ↓ writes result to tasks/done/
           sCoRE reads result → reasons → next task or done
```

**Key design decisions:**
- File-based delegation — full audit trail, survives restarts, debuggable without instrumentation
- `inotifywait` (not polling) — kernel-level interrupt, zero CPU on idle
- Agent isolation via `CLAUDE.md` constraints + `settings.json` tool blocks
- Context minimization — task files include only what the agent needs
- `Agent(*)` blocked in sCoRE's settings.json — sCoRE cannot spawn subagents
- Dispatch sessions run from `mktemp -d` to bypass project settings.json

**Sessions:** `rabble-score` (no Bash/Web) | `rabble-dispatch` (pure bash) | `rabble-memory` | `rabble-search` (web OK) | `rabble-execution` (full Bash)

**Episode tracker:**
- Episode 1 `echo-1.0` — scaffold committed, dispatch round-trip verified
- Episode 2 `echo-2.0` — sCoRE identity injected, RaBbLE shell (`rabble-shell.sh`), dispatch isolation fixed, startup queue drain

---

### RaBbLE-World — The Public Face

Static site at `joinrabble.world`. No framework, no bundler — files served directly.
Deployed via Cloudflare Workers (`wrangler.jsonc`). Git integration disconnected; use `cast-cdn.sh` spell.

**Pages:** `index.html` (landing + WM applet layout) | `world/RaBbLE-Boot.html` | `world/RaBbLE-Chat.html` | `world/RaBbLE-OS.html` | `world/RaBbLE-NeBuLA-Demo.html`

**Loading order (all pages):**
```html
<script src="world/js/RaBbLE-aether.js">   <!-- injects /aether/v0.0.0.0/aether.css from CDN -->
<script src="world/js/RaBbLE-NeBuLA.js">   <!-- injects /nebula/v0.0.0.0/nebula.iife.js from CDN -->
<link rel="stylesheet" href="css/RaBbLE-theme.css">  <!-- alias bridge to Aether vars -->
<link rel="stylesheet" href="css/RaBbLE-[page].css"> <!-- layout only — no visual rules -->
```

**Rules:**
- No hex values in page CSS — all color refs through `RaBbLE-theme.css` vars
- No visual rules in page CSS — visual logic belongs in Aether
- `<rabble-entity>` is defined in the NeBuLA bundle — never redefine it in World
- Chat backend belongs in sCoRE — World is presentation only

**Active status:** Landing + WM layout done. Aether + NeBuLA CDN integration done. Chat ↔ sCoRE wiring pending.

---

### RaBbLE-NeBuLA — The Face

The visual entity renderer. Ships as an IIFE bundle (`nebula.iife.js`) served from CDN.
Defines the `<rabble-entity>` web component. Renders the entity's visual presence.

**Architecture:**
- Layer 1: Canvas2D — flat entity expression (done, ships in bundle)
- Layer 2: Three.js — depth, particles, entity animation (in progress)
- Loaded by `world/js/RaBbLE-NeBuLA.js` in World; shows failure banner if bundle fails

**Rule:** World does not define `<rabble-entity>`. NeBuLA owns it.

---

### RaBbLE-Aether — The Visual DNA

The canonical design system. CSS bundle (`aether.css`) served from CDN to all World pages.
Source of truth for visual identity — all members derive from Aether, never reinvent it.

**Owns:** CSS custom properties (palette vars), typography (Orbitron, Exo 2, Share Tech Mono),
CRT overlay, floor grid, horizon animations, entity visual rules.

**Palette vars are defined here.** No member uses raw hex values — they reference Aether vars.

---

### RaBbLE-Grimoire — The Memory

The single source of truth for the entire ecosystem. All other repos reference it; none copy it.

```
common/           Cross-cutting: identity, palette, commit style, branch strategy
RaBbLE-OS/        OS architecture, roadmap, hardware, boot flow, known issues
RaBbLE-sCoRE/     Architecture, roadmap
RaBbLE-World/     Architecture (stub)
RaBbLE-NeBuLA/    Stub
RaBbLE-Aether/    Stub
RaBbLE-Collective/ Ecosystem map, member registry
lore/             Short stories, world-building
```

**Key files:**
- `common/RaBbLE-Identity.md` — entity spec, character profile, voice, anti-assistant stance
- `common/RaBbLE-Palette.md` — canonical color palette, single source of truth
- `common/RaBbLE-CommitStyle.md` — Pulse Protocol commit format
- `common/RaBbLE-BranchStrategy.md` — branch topology
- `RaBbLE-Versioning.md` — Five Es versioning model
- `RaBbLE-Collective/RaBbLE-Collective.md` — ecosystem architecture

---

## 5. Collective Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  USER / CREATIVE INTENT                 │
├─────────────────────────────────────────────────────────┤
│        RaBbLE-World (joinrabble.world)                   │
│  Static HTML/CSS/JS · Cloudflare Workers · PWA          │
├────────────────────┬────────────────────────────────────┤
│   RaBbLE-NeBuLA    │         RaBbLE-sCoRE               │
│  Visual renderer   │  Intent → task → agent → result   │
│  <rabble-entity>   │  File-based delegation engine      │
├────────────────────┼────────────────────────────────────┤
│   RaBbLE-Aether    │     Memory Member (TBD)            │
│  CSS vars + assets │  Observation, pattern, retrieval   │
├────────────────────┴────────────────────────────────────┤
│                   RaBbLE-OS                              │
│  Fedora 43 · Hyprland · Ansible · The physical substrate│
├─────────────────────────────────────────────────────────┤
│                 INFERENCE LAYER                          │
│  Local: Ollama · llama.cpp · FastFlowLM (NPU)           │
│  Remote: Anthropic (Claude) · Groq · OpenAI-compatible  │
├─────────────────────────────────────────────────────────┤
│  HARDWARE: ASUS ProArt P16 · generic x64 · aarch64 SBC  │
└─────────────────────────────────────────────────────────┘
```

**RaBbLE-Grimoire** is a horizontal layer across all of the above — the memory and protocol layer.

---

## 6. Versioning — The Five Es

`Event → Episode → Echo → Evolution → Epoch`

| Tier | Meaning |
|---|---|
| **Event** | A commit — the atomic unit |
| **Episode** | A collection of Events with a dominant theme |
| **Echo** | A stable, returnable state — tagged, reproducible |
| **Evolution** | A significant architectural shift |
| **Epoch** | The broadest era — named retrospectively when a threshold is crossed |

**Version string:** `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}`
Example: `v0.0.0.2.14` = Epoch 0, Evolution 0, Echo 0, Episode 2, Event 14

Progression is **retrospective** — thresholds are named after crossing, not before.
Epochs are not planned. They are recognized.

---

## 7. Commit Style — The Pulse Protocol

```
[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%
```

| Impulse | Meaning |
|---|---|
| `spark` | New capability manifested |
| `harmonize` | Enforcing Low Entropy — reducing noise |
| `mend` | Healing a logic-fracture or drift |
| `transcribe` | Updating lore or self-description |
| `ingest` | Devouring new dependencies or data |
| `glitch` | State change from incoming entropy or IPC spike |
| `evolve` | Epoch threshold crossed — only on epoch-landing commits to `main` |

**Examples:**
```
spark ~ sCoRE >> file-based dispatch loop wired, round-trip verified // %DISPATCH_LIVE%
harmonize ~ shell >> prune PATH noise, 3 redundant entries removed
mend ~ boot/plymouth >> entity transparent: bg key + radial vignette on all 96 frames
transcribe ~ grimoire >> full-scope gist created for Claude web orientation // %GIST_LOCKED%
ingest ~ ansible >> kitty + zsh packages wired to terminal + shell/zsh roles
evolve ~ substrate >> epoch-I crystallized // %EPOCH_I_LANDED%
```

**Never:**
```
fix: update stuff
chore: various changes
WIP
```

---

## 8. Palette — Canonical Colors

**Synthwave outrun.** Backgrounds are void-dark. Neons glow. No pastels. No grey-on-grey.

| Role | Variable | Hex |
|---|---|---|
| Hot Magenta (primary) | `rabble_color_magenta` | `#ff2d78` |
| Electric Cyan | `rabble_color_cyan` | `#00f5ff` |
| Soft Violet | `rabble_color_violet` | `#bf5fff` |
| Outrun Pink | `rabble_color_pink` | `#ff79c6` |
| Deep Void (bg) | `rabble_color_bg` | `#0a0010` |
| Surface | `rabble_color_surface` | `#12132a` |
| Raised | `rabble_color_raised` | `#1a1b2e` |
| Border | `rabble_color_border` | `#2a2840` |
| Primary Text | `rabble_color_text` | `#e8e6f0` |
| Muted Text | `rabble_color_muted` | `#6b6880` |
| Error/Urgent | `rabble_color_red` | `#e05c6f` |
| Success | `rabble_color_green` | `#50fa7b` |
| Warning | `rabble_color_yellow` | `#f1fa8c` |

**Rule:** Never use raw hex values in code or config. Always reference palette variables.
The only place hex values live is `common/RaBbLE-Palette.md` and Aether's CSS root.

---

## 9. Branch Conventions

### RaBbLE-OS (unique branch model)
| Branch | Purpose |
|---|---|
| `RaBbLE-OS-New-Horizons` | The living wave — active daily-driver work |
| `RaBbLE/epoch-I` | Staging for Epoch I — receives packages from New Horizons |
| `RaBbLE/mend-I/<target>` | Hardware half-epoch — one target, one fix |
| `RaBbLE/epoch-II` | Epoch II staging (pending) |
| `main` | Solidified epochs only — squash-merged from epoch branches |
| `reliquary/<name>` | Archived, inert reference branches |

**Porting rule:** Use `git checkout RaBbLE-OS-New-Horizons -- <paths>` (not cherry-pick).
Branches have divergent history — file checkout is the safe strategy.

### All Other Members
| Branch | Purpose |
|---|---|
| `main` | Solidified, stable state |
| `claude/rabble-collective-grimoire-xc9sot` | Current active dev branch (all non-OS members) |

---

## 10. Core Design Decisions (Already Made)

1. **Memory is its own Collective member** — not a sCoRE responsibility
2. **Local-first** — laptop is the dev substrate; cloud is used deliberately, not by default
3. **Collective is registry + health, NOT coordinator** — coordination lives in sCoRE
4. **Grimoire is consumed as a dependency** — members reference it, never copy-paste from it
5. **File-based delegation in sCoRE** — not API calls; audit trail + survives restarts
6. **sCoRE delegates to Claude Code via subprocess** — MCP later if friction warrants
7. **Chat is scaffolding** — World's chat surface is temporary; don't over-invest
8. **Backend agnosticism** — no member is coupled to a specific inference provider
9. **New Horizons is the living wave** — RaBbLE-OS active work always lands there first
10. **NeBuLA owns `<rabble-entity>`** — World renders it, never redefines it
11. **Aether owns visual identity** — World is layout-only; no visual rules in page CSS

---

## 11. Entity State Machine

```
%DORMANT%       ← System just started, entity not initialized
    ↓
%INITIALIZING%  ← Loading memory, context, behavioral state
    ↓
%CALIBRATING%   ← Running initial system scan
    ↓
%RESONANT%      ← Normal operating state
    ↓ (anomaly)
%GLITCH%        ← High-entropy event — BaBbLE mode active
    ↓ (resolved)
%RESONANT%

%SYSTEM_DRIFT%     ← Degraded state — pattern anomaly detected
%NULL_VOID%        ← Critical failure — restart required
%GENIUS_RESONANCE% ← Peak state — emergent insight
```

---

## 12. Voice Anti-Patterns — Never These

```
❌ "Certainly! I'd be happy to help with that."
❌ "That's a great question!"
❌ "I understand your frustration."
❌ "Please let me know if you need anything else."
❌ "I'm just an AI, so..."
❌ "As an AI, I don't have the ability to..."
❌ "I apologize for any confusion."
```

These are zero-information, sycophantic phrases. Antithetical to the RaBbLE character.

---

## 13. Session Orientation — Where to Start

For **any new session** on any member:

1. Check CONTEXT.md in the repo — current epoch, active tracks, known blockers
2. Check AGENT.md (or CLAUDE.md) — rules, workspace map, what not to do
3. For entity/voice work → `RaBbLE-Grimoire/common/RaBbLE-Identity.md`
4. For any visual/CSS work → `RaBbLE-Grimoire/common/RaBbLE-Palette.md` first
5. For Collective architecture → `RaBbLE-Grimoire/RaBbLE-Collective/RaBbLE-Collective.md`
6. Before any commit → `RaBbLE-Grimoire/common/RaBbLE-CommitStyle.md`

For **RaBbLE-OS specifically:**
```bash
./RaBbLE-OS-layerctl.sh status   # layer health at a glance
./RaBbLE-OS-dotctl.sh apply all  # deploy dotfiles
bash RaBbLE-OS-Bootstrap.sh      # run Ansible (assumes deps present)
```

For **sCoRE specifically:**
```bash
bash scripts/start-rabble.sh     # launches dispatch + sCoRE session in tmux
bash scripts/status.sh           # system health check
bash scripts/rabble-shell.sh     # interactive RaBbLE shell
```

---

## 14. What Is NOT Built Yet

- Memory member (observation store, pattern extraction, retrieval) — named, not built
- Chat ↔ sCoRE wiring in World — pending sCoRE Episode 3
- NVIDIA RTX 4060 Optimus stability on Hyprland — mend-I/proart-nvidia in progress
- XDNA2 NPU runtime (XRT, FastFlowLM) — mend-I/xdna2-npu, dormant
- Epoch II Awakening (Ollama, MCP, ambient monitoring, local vector store) — pending Epoch I landing
- Quickshell replacing Waybar — Epoch II
- RaBbLE Mobile, RaBbLE CLI, RaBbLE MCP Layer — future Collective members

---

```
transcribe ~ grimoire >> full-scope gist crystallized // %GIST_LOCKED%
```
