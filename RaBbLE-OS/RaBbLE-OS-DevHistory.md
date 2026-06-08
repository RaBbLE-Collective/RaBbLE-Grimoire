# RaBbLE-OS — Development History

```
transcribe ~ grimoire >> substrate history crystallized // %DEV_LOG_LOCKED%
```

> Generated from project files and conversation history.
> Dates are derived from session timestamps. Time of day is UTC.
> Append new entries below using the Pulse Protocol.

---

## 2026-04-09

### Session: Initial Project Scaffolding + SDDM/Hyprland Transition Planning

**Focus:** First documented Claude session on RaBbLE-OS. System was running Fedora 43 KDE spin. Project had already been scaffolded with Ansible assistance from Claude and Gemini. Primary pain point: SDDM → Hyprland login not working.

**Work done:**
- Full project tree reviewed; existing Ansible scaffolding assessed
- Identified SDDM → Hyprland session handoff as the core blocker
- First full architecture diagram produced: 6-layer model (Base → Hardware → Boot Chain → Desktop → Apps → Entity)
- Ansible role structure proposed: `base/`, `hardware/`, `aesthetics/`, `snapper/`, `dev-tools/`, `AI-tools/`
- Dotfiles extracted from Ansible `j2` templates into a static `stow`-compatible structure under `dotfiles/`
- `hyprland.conf`, `hypridle.conf`, `hyprpaper.conf`, `hyprlock.conf`, `kitty.conf`, `mako/config`, `quickshell/shell.qml` all scaffolded
- Initial synthwave palette tokens set: `#0d0f1a` bg, `#e040fb` accent, `#00e5ff` cyan, `#ff6ec7` pink *(note: these were later corrected to canonical outrun values)*
- `docs/RABBLE.md`, `docs/ARCHITECTURE.md`, `docs/BOOT_FLOW.md`, `docs/PACKAGES.md` written as first canonical grimoire documents — superseded all prior MANIFESTO, PHILOSOPHY, RABBLE_ENTITY fragments
- `ROADMAP.md` updated to reflect actual current state
- `hardware/asusctl.yml` rewritten with s2idle fix: `SuspendState=s2idle` confirmed as the only correct sleep mode for AMD Strix Point HX 370 (no S3 support)
- `rabble-asus-resume.service` created to re-apply power profile 1 second post-resume (race condition fix)
- `tuned` / `tuned-ppd` conflict with asusctl identified; `platform_policy_linked_epp = false` added to `asusd.conf.j2`

**Decisions locked:**
- Fedora 43 KDE spin is the starting base (to be replaced)
- Ansible roles-based structure (not flat playbook)
- s2idle is the only valid sleep mode for this hardware
- Stow-style dotfile symlinking over Ansible `copy/template` for user configs

---

## 2026-04-10 (multiple sessions)

### Session 1: Agentic OS — Full Stack Planning

**Focus:** Broader architectural planning session. Hardware confirmed in detail. First formal RaBbLE entity definition produced.

**Work done:**
- Hardware profile documented in full: Ryzen AI 9 HX 370, Radeon 890M (PCI 65:00.0), RTX 4060 Max-Q (PCI 64:00.0), XDNA2 NPU (/dev/accel/accel0), 32GB LPDDR5X, 3840×2400@60Hz display, Btrfs root
- Optimus/PRIME topology documented: AMD 890M drives display; NVIDIA is offload-only via `DRI_PRIME=pci-0000_64_00_0`
- AI stack architecture sketched: Ollama (local inference), llama.cpp with CUDA, vLLM, FastFlowLM (NPU), ChromaDB (vector store), nomic-embed-text (embeddings), Claude as primary cloud model
- SDDM QML theme (`Main.qml`) drafted with outrun palette — first attempt at Qt6 API; later found to have compatibility issues
- Plymouth script theme drafted with synthwave assets
- GRUB2 role written with HiDPI 4K font fix identified (`ter-v32b` via `grub2-mkfont`)

---

### Session 2: XDNA2 Driver Reconciliation

**Focus:** Reconciling a git diff between two versions of Ansible config. XDNA2 and AI stack were the most modified areas.

**Work done:**
- `npu_xdna2.yml` rewritten — COPR install path, memlock fix, LD_LIBRARY_PATH fix, broken symlink fix for `xrt-smi`; all three real failure modes on Fedora 43 documented
- `all.yml` reconciled: new values (`rabble_user: mark`, `nouveau_loaded: false`) kept, but all `# NOTE:`, `# WARNING:`, `# Verified via:` inline documentation restored (new version had stripped them)
- `grub.yml` updated with resolution fix, `video=efifb:off`, fallback theme, conditional theme deployment; `plymouth.enable=1` restored to kernel cmdline
- `ai-stack/main.yml` restructured with phase gating (`ai_stack.phase` variable); `__NV_PRIME_RENDER_OFFLOAD=1` and `__GLX_VENDOR_LIBRARY_NAME=nvidia` restored to PRIME offload env blocks

**Decisions locked:**
- AI stack is phase-gated: `phase: 0` = deps only, `phase: 1` = llama.cpp + CUDA, `phase: 2` = vLLM + FastFlowLM
- `nouveau` must be blacklisted via `/etc/modprobe.d/` — managed by hardware role
- `all.yml` inline comments are architectural memory and must be preserved through diffs

---

### Session 3: DE-Agnostic System Control Planning

**Focus:** Three active pain points — suspend/lid behavior, battery management, second screen handling — all relying on KDE and needing DE-agnostic replacements.

**Work done:**
- Phase 1.6 "System Control Layer" added to roadmap
- DE-agnostic suspend stack defined: `systemd-logind` (lid/idle hardware events) → `swayidle` (Wayland compositor idle, DPMS, lock) → `hyprlock` (lock screen)
- Power stack: `power-profiles-daemon` / `asusctl` integration; Waybar power profile indicator
- Display management: `kanshi` for automatic output profiles; `wdisplays` for manual override
- Settings interface plan: `wofi`-based system menu as interim; Quickshell settings surface as long-term Phase 1.5+ target
- Dependency order established: logind/swayidle first → PPD/asusctl → kanshi → wofi menu → Quickshell surface

---

### Session 4: Git Strategy + README

**Focus:** Organizing `main` branch as clean project anchor.

**Work done:**
- `main` branch defined as docs + roadmap only; no implementation until merged via PR
- Branching model: `feat/*` → PR into `phase/*` → PR into `main`
- Phase branches: `phase/0-foundation`, `phase/1-daily-driver`, `phase/2-ai-awakening`, `phase/3-entity-emergence`
- `README.md` rewritten with bare metal framing, VM caveat with `%LEGACY_MODE%` comment, installation prerequisites
- Repo structure section intentionally removed from README to avoid doc drift

---

### Session 5: KDE → Hyprland / greetd Exploration

**Focus:** Evaluating session manager options. KDE frustration reaching critical point.

**Work done:**
- GNOME as fallback DE evaluated and rejected — adds entropy, doesn't align with RaBbLE ethos
- `greetd` + `tuigreet` explored as SDDM replacement
- Ansible `aesthetics/` role built for GRUB + greetd + TTY font fix:
  - `FONT=ter-v32b` in `/etc/vconsole.conf` for readable 4K TTY
  - `systemd-vconsole-setup` override with `ExecStartPost` to reapply Terminus after NVIDIA module loads (font reset issue)
  - `video=1920x1200` kernel cmdline (replaced `video=efifb:off` which left framebuffer empty)
  - GRUB resolution and font fix: `GRUB_GFXMODE`, `GRUB_FONT`

**Note:** greetd path was later fully abandoned in favor of SDDM. See 2026-04-12 entry.

---

### Session 6: Hyprland Config Issues + Roadmap Update

**Focus:** Cataloguing Hyprland problems and expanding the roadmap.

**Work done:**
- Critical lesson documented: **GPU env vars in `hyprland.conf` can break SDDM login entirely**. GPU management must live in `machine.conf` (Ansible-templated separately)
- New roadmap items added:
  - `machine.conf` GPU isolation pattern
  - Ansible-managed wallpaper
  - Mouse/input via pure libinput outside WM
  - Unified settings panel
  - KDE theming artifacts in Hyprland (needs purge-kde)
  - Quickshell bar replacing Waybar
  - COPR currency check (solopasha flagged as potentially stale)
  - Minimize/maximize/close button hooks
  - Tiling + floating WM hybrid behavior
- Roadmap bumped to v0.4
- `main.yml` as router pattern documented: each role's `main.yml` is 5-line dispatcher only; logic in named files
- `group_vars/` flat structure recommended over per-role `vars/main.yml`

---

## 2026-04-11

### Session: Arch/EndeavourOS Migration Consideration + COPR Research

**Focus:** Evaluating Arch-based migration due to Hyprland ecosystem friction on Fedora.

**Work done:**
- EndeavourOS evaluated: Calamares installer (no chroot required), vanilla Arch base, Hyprland native support
- HyDE project reviewed as reference for DE-style Hyprland aesthetic
- Decision: **stay on Fedora 43** — Ansible investment is Fedora-specific; COPR friction is real but manageable
- COPR research:
  - `solopasha/hyprland` confirmed abandoned
  - `lionheartp/Hyprland` confirmed as official Hyprland wiki recommendation for Fedora — actively maintained by Nobara Linux contributor
  - `ashbuk/Hyprland-Fedora` noted as cleaner RPM packaging, minimal deps, no ABI conflicts
  - Decision: migrate to `lionheartp/Hyprland` COPR

**Decisions locked:**
- Fedora 43 remains the base OS
- `lionheartp/Hyprland` replaces `solopasha/hyprland` in all Ansible roles

---

## 2026-04-13

### Session: Grimoire Reconciliation — Full Doc Rebuild

**Focus:** First major documentation reconciliation. Project had accumulated multiple states of docs across `grimoire/`, `Proposed_Docs/`, and raw `BaBbLE/` notes.

**Work done:**
- Full grimoire extracted and audited across all versions
- **Palette conflict resolved:** Two competing sets existed — softer muted values (`#0d0f1a`, `#7c6fe0`, `#4ecdc4`) vs original outrun tokens (`#ff2d78`, `#00f5ff`, `#bf5fff`, `#0a0010`). Outrun neons confirmed as canonical. All docs updated.
- **Display resolution corrected:** Early docs listed `2560×1600@165Hz` (copy error from ASUS ROG G14 example in AddingTargets.md). Correct spec: `3840×2400@60Hz`.
- New canonical grimoire documents produced:
  - `RaBbLE-Palette.md` — single source of truth for all color values
  - `Hardware.md` — full verified hardware spec promoted from deprecated archive
  - `Architecture.md` — GPU architecture diagram, power management flow, desktop component map, dotfile symlink map, observability commands
  - `BootFlow.md` — per-stage palette targets with hex values, SDDM QML `DropShadow` glow code, Plymouth spinner sweep spec
  - `Theming.md` — per-component theming guide with canonical palette targets throughout
  - `Index.md` (README) — full indexed grimoire with cross-reference tables and reading-order guides
- `KnownIssues.md` — stale references fixed
- `DistilledNonZense.md` — full entropy archive with display correction documented

---

## 2026-04-13 (evening)

### Session: KDE Manually Removed + Boot Chain Issues Documented

**Focus:** KDE had been manually purged from the system. Boot chain issues catalogued for resolution.

**Work done:**
- KDE removal confirmed; `purge-kde/` Ansible role flagged as still needed for reproducibility
- Boot chain issues enumerated and root-caused:
  - GRUB background: must be 8-bit or 16-bit PNG; true-color fails silently
  - GRUB text: microscopic at 3840×2400; `grub2-mkfont` + `ter-v32b` fix identified
  - TTY font: needs `FONT=ter-v32b` in `/etc/vconsole.conf`; may drift after NVIDIA module load
  - Plymouth: "DejaVu" font visible, wrong color — theme assets need rebuild
  - Plymouth mid-boot reload: screen goes black during Plymouth → SDDM transition; NVIDIA driver load timing implicated
  - SDDM: `Main.qml` falls back to Breeze default — Qt6 API validation needed
  - Unified boot palette: no visual continuity across GRUB → Plymouth → SDDM yet
- ASUS-specific keybind mapping drafted for Hyprland:
  - `XF86KbdLightOnOff`, `XF86KbdBrightnessUp/Down` — keyboard backlight
  - `XF86Launch1`, `XF86Launch4` — ASUS custom keys (verify with `wev`)
  - `XF86AudioMute`, `XF86AudioRaiseVolume/LowerVolume` via swayOSD
- Webcam toggle script drafted (`v4l2-ctl` / `modprobe uvcvideo`)
- swayOSD added to package list: `erikreider/swayosd` COPR

**Decisions locked:**
- SDDM confirmed as canonical session manager — greetd arc fully deprecated
- All greetd references purged from active docs; preserved in `DistilledNonZense.md`
- `aesthetics/` role directory renamed to `boot/` with subdirs `grub2/`, `plymouth/`, `session_manager/`

---

## 2026-04-14

### Session 1: Layered Ansible Architecture + Hardware Module Design

**Focus:** Restructuring Ansible for clean hardware-specific layering. Asusctl integration planning.

**Work done:**
- Two-axis inventory model confirmed: `architecture` group (x86_64, aarch64) × `hardware profile` group (asus_proart_p16, generic_x64)
- `power_stack_profile` variable defined with three states: `tuned_only` → `tuned_asus` → `full_asus`
- `rabble_modules` feature flag dict proposed for UI layer modularity
- `npu_runtime` variable added alongside `npu_enabled` for XDNA2-specific XRT gating
- `ui_ux/` role split recommended before Hyprland layer grows
- Step-by-step asusctl integration plan without breaking 8–12W baseline

---

### Session 2: Fedora 43 Power Management Baseline Confirmed

**Focus:** Clarifying the default power stack on Fedora 43.

**Work done:**
- Confirmed: Fedora 43 defaults to `tuned` + `tuned-ppd`, not `power-profiles-daemon`
- `tuned-ppd` presents the PPD D-Bus API transparently — `asusctl` works with it
- Decision: leave `tuned`/`tuned-ppd` as Fedora default; do not install `power-profiles-daemon` (conflict)
- `Architecture.md` and `Packages.md` updated to reflect correct power stack

**Decisions locked:**
- `tuned` + `tuned-ppd` is the canonical power stack on Fedora 43
- `power-profiles-daemon` must NOT be installed (conflicts with tuned-ppd)

---

### Session 3: Git Branching Strategy Revised + Base OS Pivot

**Focus:** Repeated scope creep recognized. Structural correction.

**Work done:**
- Base OS pivoted from **Fedora 43 KDE spin** to **Fedora 43 Sway spin** — eliminates KDE purge problem, gives Sway as native fallback, minimal base
- Branching strategy refined: permanent category branches (`RaBbLE-OS-UX`, `RaBbLE-OS-System`) rejected as too broad; short-lived `feat/*` branches are the pattern
- `BaBbLE` branch flagged for purge
- ML4W confirmed as system-breaking — removed from consideration
- Single GRUB2 deployment strategy locked
- Grimoire reduced: `KnownIssues.md` absorbed roadmap status; `Index.md` stripped to 6 docs; `DistilledNonZense.md` absorbed 7 archived docs

---

## 2026-04-16

### Session 1: Sway Spin Architecture + Packages/Config Split

**Focus:** Full structural port to Fedora 43 Sway spin base.

**Work done:**
- New layer model documented for Sway base:
  - Layer 0: Fedora 43 Sway Spin + RPM Fusion + COPRs + core packages
  - Layer 1: ASUS ProArt P16 hardware
  - Layer 2: GRUB2 → Plymouth → SDDM
  - Layer 3: Hyprland (primary) + Sway (fallback, already present)
  - Layer 4: Apps
  - Layer 5: Entity (Phase 2+)
- Packages/config separation locked as core design principle: every layer gets `*-packages.yml` and `*-config.yml` as separate entry points
- Role path hierarchy confirmed: `hardware/x64/asus_proart_p16/` (hierarchical, not numbered)
- `layer-ctl.sh` maps human layer names to Ansible tags internally
- `scaffold.sh` hard-blocked from running on `main` branch
- Old role migration map produced:
  - `core/` → `roles/core/`
  - `hardware/` + `system-services/power/` + `runtime/xrt.yml` → `hardware/x64/asus_proart_p16/`
  - `dev-tools/` → `apps/`
  - `config/hypr/` → `dotfiles/hyprland/`

---

### Session 2: RaBbLE Logo / Identity Art

**Focus:** Visual identity work — interpreting and refining the RaBbLE logo.

**Work done:**
- ANSI terminal art of two overlapping diamonds (magenta + cyan) identified as the RaBbLE logo concept
- Python script written to generate `rabble_logo.ansi` programmatically with proper ANSI escape codes
- Dual-diamond design with portal rings above/below each diamond tip
- Gap variable for breathing room between diamond tips and portal rings

---

### Session 3: Curl Bootstrap + Install Script Fixes

**Focus:** Making the install process curl-able for fresh machines.

**Work done:**
- Three-script system reviewed: `RaBbLE-OS-Install.sh`, `RaBbLE-OS-Bootstrap.sh`, `RaBbLE-OS-layerctl.sh`
- **Clone ordering bug fixed:** SSH-first clone is impossible on a fresh machine (no key to register yet). New order: install tools → HTTPS clone → optional SSH setup afterward
- Repo URL changed from `git@github.com:YOUR_ORG/RaBbLE-OS.git` placeholder to `https://github.com/markm1206/RaBbLE-OS.git`
- `MAGENTA` color variable defined in Bootstrap.sh (was referenced but never defined — broke post-install banner)
- `PLAYBOOK` path aligned between scripts: `ansible/site.yml` (not `ansible/playbook.yml`)
- curl one-liner established: `curl -fsSL https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS-Install.sh | bash`

---

## 2026-04-26

### Session: Sway Desktop + swayOSD Research

**Focus:** Desktop layer work on Sway/Hyprland base. OSD component research.

**Work done:**
- swayOSD confirmed not in official Fedora repos — requires `erikreider/swayosd` COPR
- Ansible install pattern documented: `community.general.copr` + `ansible.builtin.dnf`
- swayOSD systemd user service: `swayosd-libinput-backend.service` (must be enabled)
- swayosd-server must autostart via compositor `exec-once`
- Compositor-agnostic keybind pattern established:
  - Keybind logic lives in shell scripts (`roles/desktop/<role>/files/scripts/`)
  - Each compositor role imports a bind config that calls those scripts
  - One script change propagates to both Hyprland and Sway
- Role structure proposed for swayOSD, launcher, screenshot following portability pattern
- `wayland` role scope defined — slim core only (xdg-desktop-portal, Wayland env vars, wl-clipboard)
- Hyprland confirmed as PRIMARY; Sway as stable fallback only
- Claude Code AGENT.md context doc drafted for the session handoff pattern

---

## 2026-04-28 — 2026-04-29

### Session: RaBbLE-Collective Scaffolded

**Focus:** Expanding project scope — RaBbLE-OS becomes one member of a multi-repo Collective.

**Work done:**
- `RaBbLE-Collective` repository scaffolded as coordination hub
- Three additional repos registered:
  - `RaBbLE-OS` — OS substrate (existing)
  - `RaBbLE-WEB` — agentic web server (initialized, not yet built)
  - `RaBbLE-Frontend` — animated frontend (initialized, not yet built)
- Collective conventions established:
  - Each project owns an `AGENT.md` as its primary context file
  - `CLAUDE.md` and `CODEX.md` symlink TO `AGENT.md` (not the reverse)
  - `setup.sh` handles all symlinks across the Collective on a fresh clone
  - `new-member.sh` scaffolds a new project and registers it in the manifest
- Directory structure locked:
  ```
  RaBbLE-Collective/
  ├── AGENT.md          ← master index / project registry
  ├── CLAUDE.md         ← symlink → AGENT.md
  ├── CODEX.md          ← symlink → AGENT.md
  ├── CONTEXT.md        ← current epoch, active tracks
  ├── REFERENCES.md     ← decisions, repos
  ├── registry/         ← member manifests + epoch state
  │   ├── epochs/
  │   └── manifests/
  ├── scripts/          ← Collective tooling
  └── grimoire/         ← identity and philosophy
  ```
- Epoch 0 "Foundation" declared as active epoch
- Exit condition: all project repos initialized, `setup.sh` verified, AGENT.md index current

**Decisions locked:**
- `RaBbLE-WEB` uses all-caps suffix (acronym-style, matching `RaBbLE-OS`)
- `RaBbLE-Frontend` uses title case (descriptive word, not acronym)
- Projects are self-contained modules — the Collective wires them, doesn't own them

---

## Open Issues (as of last session)

| Area | Issue | Opened |
|---|---|---|
| GRUB2 | 4K font (`ter-v32b`) not applied | 2026-04-10 |
| GRUB2 | Background bit depth (8/16-bit only) | 2026-04-13 |
| Plymouth | Mid-boot visual reload artifact | 2026-04-13 |
| SDDM | `Main.qml` Qt6 API issues — falls back to Breeze | 2026-04-09 |
| TTY | Font unreadable at 4K | 2026-04-10 |
| Hyprland | KDE theming artifacts — depends on purge-kde | 2026-04-13 |
| Hyprland | Wallpaper not managed by Ansible | 2026-04-11 |
| hypridle | Crash/instability reported | 2026-04-11 |
| Quickshell | Build from source fragile on Fedora 43 | 2026-04-11 |
| `purge-kde/` | Ansible role not written | 2026-04-09 |
| `deploy-dotfiles` | Intermittent false success (symlinks not created) | 2026-04-13 |
| asusd | Intermittent start failure on boot | 2026-04-13 |
| NPU/XRT | Fedora 43 XRT package availability unverified | 2026-04-10 |
| Suspend | Full stability unverified in current state | 2026-04-10 |

---

```
transcribe ~ grimoire >> dev history distilled // %LOG_CURRENT%
```
