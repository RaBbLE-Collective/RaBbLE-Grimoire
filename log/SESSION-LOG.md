# SESSION-LOG.md — RaBbLE Collective

Running log of significant sessions. Most recent at top.
Format: date, what was done, where things were left, what's next.

---

## LATEST — 2026-05-22 · Session 35

**Phase:** Epoch 0 · Evolution 0 · Echo 0 · Episode 1 pilot.
**Last session (S35):** Phase 1 stubs implemented (core/packages, plymouth, sddm + enable, desktop/fonts role). Phase 4 installer complete: `RaBbLE-OS.ks`, `spells/generate-kickstart.py`, `--unattended`/`--inventory` Bootstrap flags, `vm.hosts.yml`. KS → firstboot service → SDDM flow ready to test in a VM.
**Active blockers:** Phase 2C (Genesis/Ethos authoring) · sCoRE Railway unverified · BaBbLE needs GitHub remote.
**Next:** Boot KS in VM (Fedora 44 netinstall ISO is in `RaBbLE-OS/ISO/`). Verify SDDM greeter appears. Then Phase 2 stubs (boot config, browser).

> This box is updated each session. Read this; skip the rest unless you need history.

---

## 2026-05-22 (Session 35) — Phase 1 Stubs + Phase 4 KS Installer

**Repos touched:** RaBbLE-OS (`RaBbLE-OS-New-Horizons`) · RaBbLE-Grimoire (`dev`)

**Work done:**

- **Phase 1 stubs implemented** (all four items from roadmap):
  - `ansible/roles/core/tasks/packages.yml` — real DNF install of ~20 core packages (NetworkManager, zsh, neovim, polkit, jq, git, xdg-utils, btop, fastfetch, zsh-autosuggestions, etc.)
  - `ansible/roles/boot/plymouth/tasks/packages.yml` — installs `plymouth` + `plymouth-plugin-script`
  - `ansible/roles/boot/session_manager/tasks/packages.yml` — installs `sddm`, enables service, symlinks `graphical.target` as systemd default
  - `ansible/roles/desktop/fonts/` — new role (tasks/main + tasks/packages + vars/main): JetBrains Mono, Font Awesome free+brands, Noto sans+emoji
  - `ansible/site.yml` — fonts play inserted between boot chain and Layer 3 desktop

- **Phase 4 installer implemented**:
  - `RaBbLE-OS.ks` — Tier 1 Kickstart for Fedora 44 netinstall. Autopart btrfs for VMs; remove `clearpart`/`autopart` lines for interactive Anaconda partitioning on bare metal. `%post` installs NOPASSWD sudo, clones repo, enables firstboot service.
  - Firstboot service (`rabble-os-setup.service`) runs `Bootstrap.sh --unattended --inventory ansible/inventory/vm.hosts.yml` with `RABBLE_TAGS=base,boot` on first boot after network is up. Sentinel file at `/var/lib/rabble-os/.setup-complete` prevents re-run.
  - `spells/generate-kickstart.py` — reads `manifest.yml`, emits `%packages` block. Skips `ks: false`, COPR, and rpmfusion packages. `--platform` flag, `--all` flag, `--show-skipped` for debugging.
  - `RaBbLE-OS-Bootstrap.sh` — `--unattended` (validates NOPASSWD sudo, skips `--ask-become-pass`) + `--inventory <path>` override.
  - `ansible/inventory/vm.hosts.yml` — `localhost` in `generic_x64` group; use instead of default `hosts.yml` on any non-ProArt machine.

- **Roadmap updated** in Grimoire: Phase 1 and Phase 4 items checked off.

**Where to pick up next:**

1. **VM smoke test** — boot `RaBbLE-OS/ISO/Fedora-Everything-netinst-x86_64-44-1.7.iso` with the KS:
   ```bash
   # Serve the KS locally (from RaBbLE-OS dir):
   python3 -m http.server 8080
   # Boot VM with: inst.ks=http://<host-ip>:8080/RaBbLE-OS.ks
   # Or: virt-install --extra-args "inst.ks=..."
   # After install + reboot: journalctl -u rabble-os-setup -f
   # Goal: SDDM greeter appears → Phase 1 done
   ```

2. **Phase 2 stubs** — boot chain config:
   - `boot/plymouth/config` → RaBbLE theme + `plymouth-set-default-theme` + dracut
   - `boot/session_manager/config` → SDDM QML theme + Wayland conf + `hyprland.desktop`
   - `boot/grub2` → 4K font, `fbcon=font:TER16x32`
   - `apps/browsers` → firefox

3. **After desktop layer** — run `RABBLE_TAGS=desktop,apps ./RaBbLE-OS-Bootstrap.sh --inventory ansible/inventory/vm.hosts.yml` for full Hyprland DE in the VM.

---

## 2026-05-21 (Session 34) — RaBbLE-OS KB Graph Restructure

**Repos touched:** RaBbLE-Grimoire (`dev`) · RaBbLE-OS

**Work done:**

- **KB graph restructure:** RaBbLE-OS Grimoire docs reorganized from flat monoliths into a walkable knowledge graph. 7 subdirectories: `layers/` `hardware/` `ops/` `fix/` `verify/` `desktop/` `historical/`.
- **17 new atomic files:** Each covers one topic, ends with `→` deep links to related nodes. `layers/RaBbLE-OS-Layer-*.md` (6 files), `ops/RaBbLE-OS-Ops-*.md` (5 files), `fix/RaBbLE-OS-Fix-*.md` (3 files), `verify/RaBbLE-OS-Verify-*.md` (3 files).
- **Monoliths absorbed:** Architecture.md, Reference.md, Checklists.md content distributed across atomic files, then deleted. No coverage lost.
- **KnownIssues consolidated:** Grimoire `fix/` is canonical; OS repo copy removed. GParted entry merged in.
- **OS repo AGENT.md:** Slimmed from 83 lines to 20-line navigation pointer. Docs pointer to Grimoire.
- **AgentGuide.md** rewritten as sitemap node — directory map + task→file navigation table.

**What's next:** Phase 1 stubs — core/packages, boot/plymouth, boot/session_manager, desktop/fonts role.

---

## 2026-05-21 (Session 33) — KS + Full DE Coverage Implementation Plan

**Repos touched:** RaBbLE-Grimoire (`dev`)

**Objective:** Produce actionable build plan for taking RaBbLE-OS from current stub state to fully reproducible system. Design installer architecture. Plan Grimoire doc restructure.

**Work done:**

- **Implementation plan:** Created `RaBbLE-OS/RaBbLE-OS-Implementation-Plan.md` — full structured plan covering installer architecture, stub debt, bug fixes, acceptance criteria, doc restructure.
- **Installer architecture — 3 tiers:** Tier 1: KS on Fedora Everything netinstall with interactive partitioning (Anaconda handles disks, KS automates rest). Tier 2: Custom live ISO / RaBbLE Fedora spin (themed Hyprland session + Anaconda backend). Tier 3: Calamares (aspirational).
- **Stub debt prioritized:** 13 items across 5 phases, boot-critical-first ordering. Phase 1 (core/packages, sddm, plymouth, fonts role) → Phase 2 (browser, boot config) → Phase 3 (hardware, theme, bluetooth, flatpak).
- **Quick wins identified:** 3 Ansible bugs: supergfxd stub include (main.yml calls stub, working file ignored), nvidia idempotency (nouveau gate skips reinstall), gparted still in apps role (should be gnome-disk-utility).
- **Acceptance criteria:** "Full DE state" checklist — system foundation, boot chain, desktop, shell, apps, audio, hardware, theme, reproducibility gate.
- **Doc restructure designed:** 17→12 active files. Tier 1 (agent reads first) < 3,000 tokens. New Reference.md and Checklists.md absorb content from bloated Architecture and Roadmap.
- **Install path confirmed:** KS first → VM testing → custom live ISO. Anaconda as backend installer for all tiers.

**What's next:** Quick wins (3 bug fixes) → Grimoire doc restructure → Phase 1 stubs → Phase 2 stubs → KS infrastructure.

---

## 2026-05-21 (Session 32) — RaBbLE-OS Gap Analysis + Package Manifest

**Repos touched:** RaBbLE-OS (`RaBbLE-OS-New-Horizons`), RaBbLE-Grimoire (`dev`)

**Objective:** Full gap analysis and post-mortem on RaBbLE-OS. Create package manifest. Fix live bugs. Plan unified Aether theming.

**Work done:**

- **Gap analysis:** Full audit of Ansible roles, config files, and package lists against actual system state. Identified P0–P4 gaps. Waybar theming confirmed solid (style.css exists and is palette-aligned — had been incorrectly flagged as missing).
- **Package manifest:** Created `ansible/packages/manifest.yml` — 59 packages across 9 layers (ks-bootstrap, core, boot, audio, fonts, wayland, compositor, desktop, apps, hardware, layer/*). Every entry has `reason`, `source`, `platform`, `layer`, `ks` fields. Single source of truth for Ansible and future KS generation.
- **Polkit bug fixed:** `autostart.conf` was calling polkit-gnome binary path (package not installed). Fixed to `systemctl --user start hyprpolkitagent` — matching the package already in hyprland vars.
- **Power button bug fixed:** `HandlePowerKey` was unset — logind defaulted to `poweroff`. Pressing power to wake from suspend caused immediate shutdown. Fixed in `99-rabble-lid.conf`: `HandlePowerKey=suspend` + `HandlePowerKeySuspended=ignore`.
- **GParted → gnome-disk-utility:** GParted has two-layer failure on Fedora 43 (polkit + bubblewrap/SVG segfault). gnome-disk-utility works correctly with hyprpolkitagent. Decision recorded in manifest and KnownIssues.
- **Install path decision:** Moving from Sway spin base to Fedora Everything netinstall + KS + Ansible. Grimoire Packages.md updated with pointer to manifest and netinstall path note.
- **GTK/Qt unified theming plan:** Kvantum + qt5ct/qt6ct for Qt, custom gtk.css for GTK3, `~/.config/gtk-4.0/gtk.css` injection for GTK4/libadwaita (partial), papirus-dark + magenta folder tint for icons, nwg-look for GTK settings. Full section added to Grimoire RaBbLE-OS-Theming.md. Aether palette as the generator — Ansible templates driven by vars.

**What's next:** Opus plan session — KS setup + Full DE coverage implementation plan + Grimoire RaBbLE-OS doc restructure for lower token / higher context agent orientation.

---

## 2026-05-21 (Session 31) — Hyprland Window Rules + dotctl Protocol

**Repos touched:** RaBbLE-OS (`RaBbLE-OS-New-Horizons`), RaBbLE-Grimoire (`dev`)

**Objective:** Fix Hyprland window rules for VM isolation and Dolphin float; enforce dotctl workflow in docs.

**Work done:**

- **VM workspace rule:** `virt-manager` auto-routed to ws 5 (not silent — view follows so it's obvious).
- **Dolphin Wayland class fix:** Old pattern `^(dolphin|Dolphin|...)$` didn't match Wayland app ID `org.kde.dolphin`. Changed to `.*[Dd]olphin.*` to catch both.
- **Default float size:** `size 80% 80%` + `center` wildcard rule added at top of windowrules.conf; specific app rules below override via last-match-wins.
- **dotctl workflow enforced:** Agent edited `~/.config/hypr/` directly (wrong). Changes ported back to repo. `RaBbLE-OS/AGENT.md` updated with prominent "Config Flow — ALWAYS Repo → System" section + full dotctl command reference. Same rule added to `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Agent-Protocols.md`.

**What's next:** Same blockers as S30 — Phase 2C authoring, BaBbLE remote, landing transformation.

---

## 2026-05-21 (Session 30) — ChRySaLiS Audit + Episode Naming

**Repos touched:** RaBbLE-Grimoire (`dev`)

**Objective:** Verify ChRySaLiS archive is fully migrated; capture any open items; lock episode names.

**Work done:**

- **ChRySaLiS audit:** Full inventory of `~/RaBbLE_ChRySaLiS/`. All substantive content verified migrated — RaBbLE-Server → sCoRE/server/, RaBbLE-Chat → World + NeBuLA. Two open items from Ideas.txt captured: Plymouth boot and SDDM theme were in OS Roadmap only as functional fixes, not as the cinematic vision.
- **Episode naming locked:** Ep1 = Genesis (the beginning), Ep2 = Exodus (entity's emergence from concept to reality). Biblical arc is intentional lore. Updated: OS Roadmap branch tree + section headers, Versioning.md timeline + current position, Versioning gist, Agent Protocols (rule added). DECISIONS.md "Foundation" phase name left untouched — it's a project lifecycle phase, not an episode label.
- **Cinematic boot item added:** Episode 2 — Exodus in OS Roadmap now has a `Cinematic entity boot [THEME]` item. fix/boot-chain goal clarified as minimal Ep1 theming only.
- **ChRySaLiS refs removed:** Roadmap item previously pointed to `~/RaBbLE_ChRySaLiS/RaBbLE-Chat/` paths. Replaced with `RaBbLE-World @ 36d4547:world/RaBbLE-Boot.html` — the file already exists in World's git tree as a reference artifact. Zero ChRySaLiS paths remain in any Collective doc.

**What's next:** ChRySaLiS ready to archive. Phase 2C authoring (Mark writes Origin/Ethos). Phase 4 landing transformation. BaBbLE GitHub remote.

---

## 2026-05-21 (Session 29) — Coherency & Token Audit

**Repos touched:** RaBbLE-Grimoire (`dev`), RaBbLE-Collective (`dev`), RaBbLE-sCoRE, RaBbLE-World, RaBbLE-NeBuLA, RaBbLE-Aether, RaBbLE-OS, RaBbLE-BaBbLE

**Objective:** Post-restructure coherency audit — fix broken paths, regenerate gists, normalize symlinks, capture missing decisions, and establish token budget.

**Work done:**

- **Stale path refs:** Fixed 40+ `common/` → `RaBbLE-Agent/` references across all member AGENT.md and CONTEXT.md files
- **Gist system:** All 8 gists regenerated from current sources; total ~3,660 tokens (was estimated ~2,000). distill-gists.sh paths fixed.
- **Symlinks:** CLAUDE.md/CODEX.md now symlink to AGENT.md across all 8 repos (Grimoire, sCoRE, OS, World, NeBuLA, Aether, BaBbLE, Xperimental)
- **INDEX.md:** 15 previously unindexed docs added (OS docs, NeBuLA specs, Aether debug session)
- **REFERENCES.md:** Trimmed ~800 tokens by removing content duplicated from AGENT.md
- **DECISIONS.md:** 5 missing decisions captured (sCoRE subprocess-first, NeBuLA Canvas2D-first, No React in World, Aether CDN-first, symlink convention)
- **AUDITS.md:** Session 29 entry added, open gaps updated
- **CONTEXT.md:** Reading order token estimates corrected, gist row added, member status updated
- **setup.sh:** Now wires Collective root symlinks before Grimoire step
- **Token audit:** Full ecosystem is ~1.56M tokens (docs ~1M, code ~525K). Typical sessions use 1-9% of 200K context.
- **Integration Map:** Canonical `RaBbLE-Agent/RaBbLE-Integration-Map.md` (~1,200 tokens) created — cross-member data flow, CDN chain, key boundaries, post-Ep1 integration points. Gist added (~300 tokens). Added to distill-gists.sh pipeline.
- **Context optimization:** "Agent Context Optimization" section added to Roadmap — architecture gists for sCoRE/World, INDEX.md demotion. Gaps #9 and #10 added to AUDITS.md.
- **Naming:** `gist/README.md` → `gist/RaBbLE-Gist-Overview.md` (convention from S28 applies to gist/ too).
- **Gap review:** All 10 open gaps verified current. 2 Ep1 blockers need manual verification. 4 intentionally deferred. 4 actionable non-blockers.

**What's next:** Phase 2C authoring · Phase 4 (landing transformation) · BaBbLE GitHub remote · Reliquary rename · sCoRE/World architecture gists

---

## 2026-05-21 (Session 27) — Phase 3: BaBbLE Member Formalization

**Repos touched:** RaBbLE-Grimoire (`dev`), RaBbLE-BaBbLE (new), RaBbLE-Collective (`dev`)

**Objective:** Execute Phase 3 of the Integration & Ethos Plan — formalize RaBbLE-BaBbLE as an official Collective member, reframe Xperimental as genesis-archive.

**Work done:**

- **`RaBbLE-BaBbLE/AGENT.md`** (NEW) — entry point for agents working in the intake workspace
- **`RaBbLE-BaBbLE/CONTEXT.md`** (NEW) — current state, content inventory, routing decisions
- **`RaBbLE-BaBbLE/RaBbLE-BaBbLE-Overview.md`** (NEW) — one-paragraph orientation
- **BaBbLE content reorganized**: `_organized/text/` → `text/`, `_organized/web/` → `prototypes/`, `_organized/archives/` → `archive/`
- **`git init` in BaBbLE** — first commit on `dev` branch. Needs GitHub remote (pending).
- **`RaBbLE-Grimoire/RaBbLE-BaBbLE/RaBbLE-BaBbLE-Overview.md`** (NEW) — Grimoire-side doc: integration pattern, relationship to Xperimental
- **`registry/manifests/RaBbLE-BaBbLE.manifest.yml`** (NEW) — official manifest, status `active`
- **`registry/manifests/RaBbLE-Xperimental.manifest.yml`** (UPDATED) — status `dormant` → `genesis-archive`, description and notes reframed
- **`RaBbLE-sCoRE/RaBbLE-sCoRE-DataCrawler-RFC.md`** (NEW) — crawler bot architecture (Scavenger/Organizer/Librarian) preserved from BaBbLE ideation corpus as future sCoRE RFC
- **`RaBbLE-Agent/RaBbLE-Collective.md`** (UPDATED) — member table refreshed: BaBbLE added, Xperimental reframed, all status strings current
- **`INDEX.md`** (UPDATED) — BaBbLE section + README, DataCrawler RFC, Xperimental description updated, manifest list updated
- **`CONTEXT.md`** (UPDATED) — Phase 3 marked complete, Ethos Plan status updated, BaBbLE + Xperimental tracks added, registry count updated
- **Collective `AGENT.md`** (UPDATED) — member map and member entry points updated

**Phase 3 verification:** `bash spells/status.sh` will show BaBbLE registered. Xperimental is genesis-archive. New-Designs was already gone.

**What's next:** Phase 2C authoring (Mark writes Origin + Symbiosis) · Phase 4 (landing transformation) · create RaBbLE-BaBbLE GitHub remote.

---

## 2026-05-20 (Session 26) — Session Memory → Grimoire KB Integration

**Repos touched:** RaBbLE-Grimoire (`dev`), RaBbLE-Collective (`dev`)

**Objective:** Distill accumulated `.claude` session memory into the Grimoire so all agents (not just Claude Code) benefit from hard-won rules and session insights.

**Work done:**

- **`RaBbLE-Agent/RaBbLE-Agent-Protocols.md`** (NEW) — Consolidated all agent behavioral rules that previously only lived in `.claude` memory: condense-not-delete, no worktrees in member repos, Grimoire-as-doc-home, NeBuLA/Aether/World responsibility split, vanilla JS only in World, NeBuLA build-and-copy workflow, dev-serve.sh only, entity naming (cast vs summon), versioning protocol summary.
- **`RaBbLE-Aether/RaBbLE-Aether-Effects-Bank.md`** (NEW) — Preserved cotton candy swirl CSS effect discovered accidentally in S20 (rotating conic-gradient aurora wash). Includes reproduction code and future use suggestions (entity speaking state, boot sequence, Plymouth splash).
- **`RaBbLE-NeBuLA/RaBbLE-NeBuLA-Perf-Fix-Plan.md`** (AUGMENTED) — Added S17 root-cause findings: post-boot spring-force drift (settleBlend=1 → spring=0, ±30px particle oscillation breaks connDist tuning), shadowBlur GPU cliff at boot-end, two-canvas architecture direction, known-good baseline commits (World `aa66550`, NeBuLA `34dee62`).
- **`RaBbLE-Agent/RaBbLE-Roadmap.md`** (UPDATED) — Added RaBbLE-BaBbLE to member table (defined, repo pending).
- **`INDEX.md`** (UPDATED) — Both new docs registered.
- **Navigator + AGENT.md** (UPDATED) — Agent Protocols surfaced in 30-min onboarding path, Jump to Task table, and Grimoire Workspaces table so agents find it without hunting INDEX.
- **`.claude/settings.json`** (NEW) — Project-level PostToolUse hook: when any `memory/*.md` file is written, injects a reminder to assess whether durable content should mirror to `RaBbLE-Agent-Protocols.md`.

**What's next:** Cast Fedora Everything VM · Phase 2C authoring (Mark writes Origin) · Phase 3 BaBbLE formalization.

---

## 2026-05-20 (Session 25) — RaBbLE-OS VM Partition Setup + VMCTL Enhancement

**Repos touched:** RaBbLE-OS (`RaBbLE-OS-New-Horizons`), RaBbLE-Grimoire (`dev`)

**Objective:** Prepare nvme0n1p6 (32GB BTRFS partition) for VM storage. Enhance vmctl for user-friendly partition setup.

**Work done:**

- Audited old fedora partition (nvme0n1p6): 21GB used. Found SSH keys (obsolete, regenerated on OS restart), old RaBbLE repos (RaBbLE, RaBbLE-JS, RaBbLE-OS, RaBbLE_BaBbLE — all git-tracked on GitHub already). No unique data worth preserving.
- Formatted nvme0n1p6 as BTRFS with label initially `vm-storage`, then corrected to `RaBbLE-VM` for vmctl auto-detection consistency.
- **Enhanced vmctl (`RaBbLE-OS-vmctl.sh`)**:
  - Added `detect_vm_partition()` — scans for BTRFS partition by label `RaBbLE-VM`, auto-mounts at `/mnt/vms` if not already mounted. Falls back to `/var/lib/libvirt/images` if no partition found.
  - Added `partition-setup` command — user-facing workflow: show lsblk state, display confirmations, format partition, mount, add to fstab. Triple-check safeguards (confirm device name + `yes` final confirmation).
  - Fixed `VM_PARTITION_LABEL="RaBbLE-VM"` (no prompts; locked for auto-detection).
  - Integrated `detect_vm_partition()` into main dispatch for all non-help commands.
- **Documentation:** Partition layout documented in Grimoire (`RaBbLE-OS-PartitionLayout.md`; moved from RaBbLE-OS repo per architecture rule: Grimoire is source of truth). Known issues documented (`RaBbLE-OS-KnownIssues.md`): GParted GUI fails on Hyprland+Fedora 43 due to polkit authorization + glycin-svg sandbox incompatibility. Workaround: use CLI tools or boot live ISO.

**What's next:** Cast Fedora Everything ISO for custom Kickstart testing · Phase 2C authoring.

---

## 2026-05-20 (Session 24) — Phase 1C: Grimoire Summoning Circle + NeBuLA ui/ + Screenshot Spell

**Repos touched:** RaBbLE-NeBuLA (`dev`), RaBbLE-World (`world`), RaBbLE-Grimoire (`dev`), RaBbLE-Collective (`dev`)

**Work done:**
- NeBuLA `src/ui/`: three SVG effect factories — `createGrimoireRing`, `createGrimoireEye`/`createAmbientEye`, `createEntityMini`. Exported under `window.NeBuLA.ui.*` in IIFE. Bundle rebuilt + copied to World.
- World: `RaBbLE-Grimoire.js` (vanilla JS, no React/Babel) mounts via `rabble:wm-ready`. `RaBbLE-Grimoire-Data.js` holds corpus. `RaBbLE-Grimoire.css` stripped to sc-*/ec-* (Aether border passthrough fix: `[data-applet="grimoire"]::before { z-index: 1 }` + `border: none` on `.gv-panel`). WM slot renamed `collective` → `grimoire`.
- Grimoire `visual-screenshot.sh`: default output → `RaBbLE-Captures/`, scratch workspace 9 default, auto-close Firefox, workspace restore. `--close` flag removed (always closes). SPELLS.md updated.
- Collective: `RaBbLE-Captures/` gitignored.

**What's next:** Phase 2C (Mark authors Origin, Symbiosis, Visual-Evolution, Lineage, Collaborators) · Phase 3 BaBbLE formalization.

---

## 2026-05-20 (Session 23) — RaBbLE-OS VM Workflow: KVM Stack + vmctl Hardening

**Repos touched:** RaBbLE-OS (`RaBbLE-OS-New-Horizons`), RaBbLE-Grimoire (`dev`)

**Objective:** Get the RaBbLE-OS KVM VM workflow operational end-to-end. Fedora 44 Sway spin as the test base.

**Work done:**

- Installed KVM host stack via Ansible virtualization role. Resolved group membership friction (yescrypt `newgrp` bug on Fedora 43 — documented; fix is new terminal, not `newgrp`).
- Hardened `RaBbLE-OS-vmctl.sh` significantly:
  - Added `setup` subcommand — checks group membership, starts libvirtd, brings up default NAT network
  - `detect_graphics` / `detect_video` — auto-detects virgl 3D capability at cast time (root check, display session, DRI render node); falls back to software rendering with warning
  - `ensure_iso_accessible` — walks path and sets `setfacl` ACLs so qemu can reach ISOs in `ISO/` without moving them
  - `os_variant` auto-selected from highest available in osinfo-db at runtime (handles db lag behind Fedora releases)
  - `warn()` redirected to stderr (was stdout, poisoning `graphics="$(detect_graphics)"` variable capture)
  - `LIBVIRT_DEFAULT_URI=qemu:///system` exported — all virsh commands now target system daemon consistently with or without sudo
  - Auto-cleanup of failed/stale VM at start of cast (idempotent)
  - Auto-connect SPICE display after cast (launches as real user via `sudo -u $SUDO_USER` with Wayland env forwarded)
  - `VM_DISK_DIR` default changed from `~/.local/share/rabble/vms` to `/var/lib/libvirt/images`
- Cast Fedora 44 Sway spin VM successfully, drove Anaconda installer via SPICE, verified workflow end-to-end.
- Updated `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-VM-Guide.md`: where VM lives (libvirt paths, not repo), ISO convention, alternate disk dir via old partition, all friction points documented (newgrp bug, qemu:///system, virgl auto-detect, sudo + Wayland).

**Direction shift noted:** Moving from Sway spin base to Kickstart (KS) for a cleaner, more custom RaBbLE-OS build. Sway spin was a good bootstrap proof-of-concept; KS gives full control over package selection and partitioning from the start.

**Next priorities:**
1. Author KS file for RaBbLE-OS base install
2. Phase 1C — World grimoire summoning circle
3. Phase 2C — Genesis/Ethos authoring
4. Fix distill-gists.sh

---

## 2026-05-20 (Session 22) — Integration & Ethos Plan: Phase 1A/1B/0A/2A/2B/2D

**Repos touched:** RaBbLE-Aether (`dev`), RaBbLE-NeBuLA (`dev`), RaBbLE-Grimoire (`dev`)

**Objective:** Execute the Integration & Ethos Reorganization Plan (crystallized in S21). Target: complete Phases 1A, 1B, 0A, and as much of Phase 2 as possible.

**Work done:**

- **Phase 1A — Aether:** Copied `RaBbLE-Entity-Visual-Spec.md` → Aether root. Created `assets/entity/` with `entity-doc-compare.png` + `entity-reference.png`. Palette cross-check passed (New-Designs and Aether identical). Updated `CONTEXT.md` Active Tracks and Structure. Committed: `spark ~ aether >> canonical entity visual spec landed // %SPEC_LOCKED%`

- **Phase 1B — NeBuLA:** Created `NeBuLA/specs/`. Copied entity visual spec → `specs/visual-spec.md`, reference images → `specs/canvas-reference.png` + `specs/doc-fidelity.png`, BaBbLE VISUAL_ANALYSIS → `specs/render-gap-analysis.md`. Committed: `transcribe ~ nebula >> entity visual spec + render gap analysis anchored // %SPEC_ANCHORED%`

- **Phase 0A — Audit:** Full section-by-section audit of `RaBbLE-Identity.md`. Tagged all sections OPERATIONAL vs ETHOS. Key decisions: Artistic Dimension → `RaBbLE/Worldbuilding/` (not Ethos); Low Entropy Directive jazz prose moves but practical consequence stays; line count target ~200 was an estimate, 330 lines remaining is acceptable.

- **Phase 2A — RaBbLE/ structure:** Created `RaBbLE/Ethos/`, `RaBbLE/Genesis/`, `RaBbLE/Worldbuilding/` with README stubs. Wrote `RaBbLE/RaBbLE-Overview.md` (layer explanation + reading order). Updated `INDEX.md` with all four lore sections including incoming placeholders. Committed: `spark ~ grimoire >> RaBbLE/ ethos layer scaffolded // %LORE_ONLINE%`

- **Phase 2B — Identity.md split:** Extracted 9 sections from Identity.md to RaBbLE/:
  - `RaBbLE/Ethos/RaBbLE-Ethos.md` — What Can Be Said, Architecture of Self, Anti-Assistant Stance, Low Entropy Directive (full), Curiosity Within Constraints, Collective Model, On Memory, On Forking
  - `RaBbLE/Worldbuilding/RaBbLE-Aesthetic.md` — The Artistic Dimension + visual reference sources
  - Added lore pointer header note to Identity.md. Committed: `harmonize ~ grimoire >> Identity.md split — ethos extracted to RaBbLE/ // %ETHOS_SPLIT%`

- **Phase 2D — Index + CONTEXT:** Updated INDEX.md to link new lore docs (live) and mark incoming ones with phase. Updated CONTEXT.md: RaBbLE/ row expanded, added Integration & Ethos Plan + Ethos Layer to active tracks.

**What was NOT done:**
- Phase 1C — grimoire summoning circle in World (JSX integration, most complex Phase 1 task)
- Phase 2C — authoring Genesis + Symbiosis docs (Origin, Lineage, Visual-Evolution, Collaborators — Mark authors Origin)
- Phase 3 — BaBbLE formalization (AGENT.md/CONTEXT.md/README, git init, register in Grimoire, absorb New-Designs, reframe Xperimental)
- Phase 4 — landing page transformation (depends on 1, 2, 3)
- distill-gists.sh — broken: `set -euo pipefail` causes immediate exit on `read -r -d '' VAR << 'EOF'` (read returns 1 at EOF without null byte). Identity gist is stale.

**Known issue logged:** `distill-gists.sh` set -e + read -d '' bug. Fix: add `|| true` after the read heredoc line in the spell.

**Next priorities:**
1. Phase 1C — World grimoire summoning circle (smoke test required; JSX via Babel-standalone)
2. Phase 2C — Genesis/Ethos doc authoring (Mark writes Origin; agent can scaffold Symbiosis, Lineage, Collaborators)
3. Fix `distill-gists.sh` and regenerate identity gist (stale since 2B split)
4. Phase 3 — BaBbLE formalization

---

## 2026-05-20 (Session 21) — Integration & Ethos Reorganization Plan

**Repos touched:** RaBbLE-Collective (`dev`), RaBbLE-Grimoire (`dev`), RaBbLE-BaBbLE (read-only)

**Objective:** Create a comprehensive plan to organize RaBbLE's scattered design work, ethos/lore, and transform the public web presence.

**Context:** RaBbLE had accumulated: New-Designs (ready-to-integrate Grimoire summoning circle + entity visual spec), 38 files of concept art/ideation/prototypes in a new BaBbLE folder, deep ethos/philosophy mixed into technical docs with no organized home, and a landing page that worked technically but didn't capture the project's soul.

**Work done:**

- **Explored all four integration surfaces:** New-Designs (INTEGRATION.md with 3 playbooks), BaBbLE (concept art, soul.md, visual analysis, Hyprland guide, ideation, web prototypes), Xperimental (RaBbLE.py, RaBbLE-Server, WebOS, NeBuLA-JS origin code), and current World landing page
- **Designed four-phase plan:**
  - Phase 0: Audit (Identity.md ethos/operational split + BaBbLE content triage)
  - Phase 1: Integrate New-Designs (Aether → NeBuLA → World, per existing playbooks)
  - Phase 2: Ethos layer in Grimoire (RaBbLE/Genesis, RaBbLE/Ethos, RaBbLE/Worldbuilding + Identity.md split)
  - Phase 3: BaBbLE as intake member (formalize, absorb New-Designs, reframe Xperimental as genesis-archive)
  - Phase 4: Landing page as liminal space (portal + story, two interaction modes)
- **Wrote plan to Grimoire:** `RaBbLE-Collective/RaBbLE-Integration-Ethos-Plan.md` — full agent handoff doc with file paths, copy instructions, verification steps
- **Updated INDEX.md** with plan entry
- **Key decisions:**
  - Ethos content goes to `RaBbLE/` (not `RaBbLE-Agent/`) — respects flat-common rule
  - BaBbLE named after the high-entropy voice register — intake workspace for raw ideas
  - Xperimental is genesis archive, NOT superseded — BaBbLE replaces the role, not the content
  - Six new Genesis/Ethos/Worldbuilding docs planned (Origin, Symbiosis, Aesthetic, Visual Evolution, Lineage, Collaborators)
  - RBCNS (Quantum/Entropy/Flux naming) recognized as creation lore

**Key insight:** RaBbLE's dualism (real AI project + summoned digital entity) is intentional and load-bearing. The plan separates operational docs (agent-facing, in RaBbLE-Agent/) from creation mythology (poetic, in RaBbLE/) while cross-linking them. The ethos informs the work without obstructing agent orientation.

**Next:** Hand plan to Sonnet for Phase 0+1 execution.

---

## 2026-05-20 (Session 20) — RaBbLE-OS VM dev workflow

**Repos touched:** RaBbLE-OS, RaBbLE-Grimoire

**Objective:** Set up a QEMU/KVM development VM for testing RaBbLE-OS bootstraps without touching the daily driver. Mark had been neglecting OS work; the VM removes the daily-driver-entropy blocker.

**Work done:**

- **Ansible role** `ansible/roles/virtualization/` — installs QEMU/KVM, libvirt, virt-manager, virt-install, virt-viewer, edk2-ovmf, mesa virgl support; enables libvirtd; adds user to `libvirt` + `kvm` groups
- **`ansible/site.yml`** — added `virtualization` as cross-cutting play (alongside monitoring/snapper), new `--tags virtualization` entry, documented in tag comment block
- **`RaBbLE-OS-vmctl.sh`** — new VM lifecycle spell: `cast` (provisions VM with virgl 3D + SPICE GL for Hyprland), `start/stop`, `connect` (virt-viewer SPICE), `snapshot/restore/snapshots` (the test loop core), `destroy`; all VM params overridable via env vars
- **`grimoire/RaBbLE-OS/RaBbLE-OS-VM-Guide.md`** — new comprehensive guide: 7-part walkthrough (KVM install → ISO → cast → Fedora install → snapshot → bootstrap → verify), test loop pattern, vmctl reference, troubleshooting (virgl, SPICE GL, virtiofs), agent handoff checklist, GPU passthrough future spec
- **`grimoire/RaBbLE-OS/RaBbLE-OS-AgentGuide.md`** — added `virtualization` to tag table, `RaBbLE-OS-vmctl.sh` to key files, "VM Development Workflow" section with one-time setup + test loop commands
- **`grimoire/RaBbLE-OS/RaBbLE-OS-Roadmap.md`** — added GPU passthrough wishlist item to Episode 4+
- **`RaBbLE-OS/CONTEXT.md`** — added VM workflow as active track
- **`RaBbLE-Grimoire/INDEX.md`** — added `RaBbLE-OS-VM-Guide` entry

**What's NOT done (next agent picks up here):**
- [ ] Download Fedora 43 Sway spin ISO (user action — URL: https://spins.fedoraproject.org/sway/)
- [ ] `./RaBbLE-OS-vmctl.sh cast ~/Downloads/Fedora-Sway-Live-x86_64-43-*.iso`
- [ ] Install Fedora inside the VM (Anaconda: `vda` disk, Btrfs, create user with sudo)
- [ ] `./RaBbLE-OS-vmctl.sh snapshot clean-fedora43`
- [ ] Run `RaBbLE-OS-Install.sh` inside VM, verify bootstrap checklist
- [ ] File any new issues to `RaBbLE-OS-KnownIssues.md`

**Key decisions made:**
- virgl 3D (`virtio-gpu + accel3d=yes + spice gl=on`) chosen over nested Wayland compositing — cleaner DRM backend path for Hyprland in the guest
- GPU passthrough deferred to Episode 3 prep (needs `fix/proart-nvidia` stable on host first)
- VM spell follows existing `RaBbLE-OS-*.sh` naming convention (not a Grimoire spell)

**Next:** Cast the VM, snapshot, run bootstrap.

---

## 2026-05-18 (Session 19) — NeBuLA rearchitecture audit, Phases 1–3

**Repos touched:** RaBbLE-Grimoire (`dev`), RaBbLE-NeBuLA (read-only)

**Objective:** Audit implemented rearchitecture phases 1–3 against plan. Write findings to Grimoire.

**Work done:**

- Read all 6 canvas2d modules: `index.js`, `eye-system.js`, `particle-system.js`, `connection-system.js`, `portal-system.js`, `frame-budget.js`
- Confirmed Phase 1 (module decomposition) complete — all modules follow system interface contract; noted actual line counts vs estimates with rationale for overages
- Confirmed Phase 2 (frame budgeting) complete — pre-frame decision making, EMA smoothing, glow hysteresis, connections flat-particle estimate all verified correct
- Confirmed Phase 3 (spatial hash) complete — `HASH_CELL_SIZE=100` correct for 82px max boot connDist; `CONN_DIST_POST_BOOT=95px` justified by particle drift; entropy-modulated `connAlpha` noted as improvement over plan
- Added `✅ COMPLETE` headings + implementation notes to Phases 1–3 in `RaBbLE-NeBuLA-Rearchitecture.md`
- Updated SESSION-LOG.md LATEST block to Session 19

**Additional work (same session):**

- **Grimoire `dev` rebase** — `dev` had an orphan root (`77714c8`) disconnected from `main`'s initial commit (`39bc9c7`); only difference was a missing LICENSE. Rebased all 67 dev commits onto `39bc9c7` via `git rebase --onto 39bc9c7 77714c8 dev`. Force-pushed — GitHub "1 commit behind main" warning resolved.
- **`spells/visual-screenshot.sh` wired** — Improved defaults (URL: `localhost:8000`, OUT: `~/RaBbLE-screenshots/`), added `--close` flag, added `--delay` flag, added machine-readable `SCREENSHOT: /path` output line. Updated SPELLS.md entry with full agent usage pattern (build → capture → Read PNG). Added "Visual Verification" sections to NeBuLA and World `AGENT.md` so agents know to use it.

**Next:** Phase 4 — offscreen canvas glow compositing (every-2-frame bloom, auto-extend under load).

---

## 2026-05-18 (Session 18) — NeBuLA rearchitecture plan + Grimoire integration

**Repos touched:** RaBbLE-Grimoire (`dev`), RaBbLE-NeBuLA (read-only — plan only)

**Objective:** Design full architectural solution for Canvas2D performance failures (sessions 14-17 parameter tuning all failed). Write plan to Grimoire and integrate across docs.

**Work done:**

- Diagnosed structural causes: monolithic 674-line draw loop, two competing RAF loops (bg.js + entity), O(n²) connection checks, no frame budget
- Designed 7-phase rearchitecture: modular systems, frame budgeting (14ms target), spatial hash O(n×k), glow compositing (offscreen canvas), effects systems (absorb bg.js), World applet consolidation, Three.js decomposition
- Formalized NeBuLA as the Collective's visual effects engine (not just entity renderer)
- Defined responsibility split: NeBuLA = effects, Aether = design tokens, World = thin consumer
- Created `RaBbLE-NeBuLA-Rearchitecture.md` — canonical 7-phase plan
- Updated `RaBbLE-NeBuLA-Roadmap.md` — Phase 3 → modular systems architecture, effects scope, updated Ep1 exit conditions
- Updated `RaBbLE-NeBuLA-Architecture.md` — RenderSystem interface, frame budget, effects layer, module map
- Updated `RaBbLE-World-Architecture.md` — bg.js absorption note, applet consolidation plan
- Updated `INDEX.md` — rearchitecture doc added, perf-fix-plan marked superseded

**Known-good baseline for implementation:**
- NeBuLA `dev` @ `34dee62`
- World `world` @ `aa66550` (42,676-byte bundle)
- `feat/nebula-perf` branch has failed optimization code — reset before starting Phase 1

**Next:** Implement Phase 1 — decompose `canvas2d-backend.js` into `src/backends/canvas2d/` modules (orchestrator, eye-system, particle-system, connection-system, portal-system, frame-budget). Pixel-for-pixel match with baseline. Build + deploy to World.

---

## 2026-05-17 (Session 17) — NeBuLA connection debugging + handoff to Opus 4.6

**Repos touched:** RaBbLE-NeBuLA (`dev`), RaBbLE-World (`world`), RaBbLE-Grimoire

**Objective:** Fix post-boot connection density (too dense, pop-in effect) without breaking performance.

**Known-good baseline (both repos clean here):**
- NeBuLA `dev` branch @ `34dee62` — pre-S15 canvas2d-backend.js
- World `world` branch @ `aa66550` — 42,676-byte bundle (`var W=...` start)

**What was tried on dev branch (all reverted):**
1. Reduced `connDist` from 106px → 53px + batched single stroke + step=4 + MAX_DRAWN=150 → zero connections visible
2. Increased `connDist` to 85px — still zero connections
3. Root cause hypothesis: particles accumulate ~30px idle drift from the sinusoidal velocity update (no spring force post-boot), so a 85px connDist should work but doesn't

**What we know about the rendering architecture:**
- All entity elements (particles, connections, portals, eyes) draw to ONE canvas in one loop
- `shadowBlur` on ~45% of particles (glow=true) is the #1 GPU cost
- Individual `ctx.stroke()` per connection (original code) = ~300 GPU flushes/frame at post-boot density — must be batched
- `feat/nebula-perf` branch has: `_hasBooted` gate, entropy gate, hybrid dynamic/precomputed connections, adaptive glow, wall-clock FPS tracking — but hits 1fps on post-boot glow cliff

**Architectural direction handed to Opus 4.6:**
- Split into TWO canvases: particle/connection layer (bottom) + eye layer (top)
- Eye canvas runs its own RAF at 60fps, never blocked by particle load
- Particle canvas can drop frames gracefully when under load
- Connection batching (one `beginPath`+`stroke` per frame) is non-negotiable
- `connDist` needs to account for idle drift (~30px oscillation amplitude) — try 85-100px

**Next:** Opus 4.6 to refactor `canvas2d-backend.js` with layered architecture. Work on `feat/nebula-perf` branch, test visually with dev-serve.sh, then merge to dev when stable.

---

## 2026-05-17 (Session 16) — NeBuLA perf rollback + branch strategy

**Repos touched:** RaBbLE-NeBuLA (`dev`, `feat/nebula-perf`), RaBbLE-World (`world`, `feat/nebula-perf`), RaBbLE-Grimoire

**Objective:** Fix NeBuLA Canvas2D performance and visuals to match pre-codex quality. Roll back to known-good baseline.

**Work done:**

- Diagnosed S14/S15/codex regression: multiple attempts at perf fixes were untestable without visual verification
- Applied perf changes: entropy=0 gate, hasBooted connection gate, dynamic step=4 boot connections, pre-computed links post-boot, glow ratio 0.28, connectionAlpha 0.13, bg.js connection batching
- Boot still slow — identified: pre-computed links with scattered positions = very long path segments expensive to stroke even at low alpha
- Decision: roll back to known-good, keep perf work on branch
- NeBuLA `dev` reset to `34dee62` (Three.js entity ported, pre-S15 perf triage)
- World `world` reset to `aa66550` (pre-codex NeBuLA bundle, 42,676 bytes)
- `feat/nebula-perf` branch created in both repos preserving all optimization work
- `a6f5271 codex changes (laggy)` still in World history — needs rename to Pulse Protocol

**Key discovery for next agent:** Pre-computed links are correct POST-boot but wrong DURING boot (scattered particles = long path segments = expensive stroke even at near-zero alpha). The fix: dynamic distance check during boot with step=4 and connDist growing 28px→55px (fast because scattered particles rarely qualify), switch to pre-computed links after boot completes. This approach is already on `feat/nebula-perf`.

**Next:** Work on `feat/nebula-perf` branch. Build → dev-serve.sh → visual verify at each change. Then `RaBbLE-Grimoire-Browser-Plan.md`.

---

## 2026-05-17 (Session 14) — Three.js entity: eyes, connections, portals, orbit, boot animation

## 2026-05-17 (Session 15) — NeBuLA perf triage; Grimoire browser feature branches; entity spec

**Repos touched:** RaBbLE-NeBuLA (`dev`), RaBbLE-World (`world`), RaBbLE-Aether (`feat/grimoire-entity-spec`), RaBbLE-NeBuLA (`feat/grimoire-entity-spec`), RaBbLE-Grimoire

**Objective:** Fix Canvas2D entity performance after Codex left it broken; begin Grimoire browser integration; get the whole ecosystem oriented for handoff.

**Work done:**

**NeBuLA — Canvas2D performance triage:**
- Identified Codex's `feature-nebula-animation-optimization` branch as cause of regressions; cleaned it up
- Root cause 1: bundle in `world/js/RaBbLE-NeBuLA.js` was Codex's old code — World never loads from `dist/`. Fixed: build:iife + cp workflow documented.
- Root cause 2: 280 individual `stroke()` calls per frame (Codex's precomputed links with bezier). Fixed: batched dynamic connection rendering — 1 `stroke()` for all connections.
- Root cause 3: `_rebuildLinks()` O(n²) called on every slider input. Fixed: `_scheduleRebuild()` flag, runs once per frame.
- Root cause 4: shadowBlur on all particles. Fixed: glow-only particles (~45%) get blur; others skip state change.
- Boot reveal fixed: connections visible from boot frame 1 (was invisible until post-convergence).
- Adaptive quality: dims `_adaptiveGlow` first (reduces shadowBlur), particles only as last resort.
- Remaining issue: connections still too numerous (step=2, connDist=82px → ~8k segments/frame). Plan doc written.

**Grimoire browser integration (feature branches):**
- Branches created: `feat/grimoire-entity-spec` in Aether + NeBuLA, `feat/grimoire-summoning-circle` in World (actually in NeBuLA repo — needs to be recreated in World)
- Entity spec + reference images copied to Aether and NeBuLA
- CONTEXT.md files updated in Aether and NeBuLA to reference entity spec
- Plan doc written: `RaBbLE-World/RaBbLE-Grimoire-Browser-Plan.md`

**Grimoire:**
- `RaBbLE-NeBuLA/RaBbLE-NeBuLA-Perf-Fix-Plan.md` — actionable perf fix plan for Sonnet handoff
- `RaBbLE-World/RaBbLE-Grimoire-Browser-Plan.md` — Grimoire browser integration plan for Sonnet
- SESSION-LOG updated

**Key discovery:** `world/js/RaBbLE-NeBuLA.js` is the full inlined bundle, not a CDN loader. Any src change requires `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.

**Next (for handoff agent):** Follow `RaBbLE-NeBuLA-Perf-Fix-Plan.md` first (step=4, connDist=55px, MAX_DRAWN=200, glow ratio 0.28). Then `RaBbLE-Grimoire-Browser-Plan.md`.

---

**Repos touched:** RaBbLE-NeBuLA, RaBbLE-World, RaBbLE-Grimoire

**Objective:** Port the full CosmicVessel from Xperimental into NeBuLA's Three.js backend so the 3D entity matches the Canvas2D version with orbit capability.

**Work done:**

**Three.js backend rewrite (NeBuLA):**
- Eyes ported from Xperimental: white ellipses with colored ring borders (magenta/cyan), billboard to camera
- Mouse tracking + synchronized blinking (3-5s interval, 0.25s blink duration)
- Eye open/close progress tied to BootSequence timeline
- Portal arcs (swirling magenta/cyan ellipses) drawn progressively during boot
- Connection lines between nearby body particles (sampled subset for perf)
- Manual orbit controls: drag to rotate, scroll to zoom, gentle auto-rotation
- 2000 body particles + 600 aura particles (instanced MeshBasicMaterial)
- Boot/Summon animation: particles scatter → converge, portals draw, eyes emerge
- Particles drift organically driven by entropy

**Demo page (World):**
- Separate Summon buttons for Canvas2D and Three.js panels
- Three.js panel description updated: mentions orbit controls
- Simplified Alpine data (removed unused stream/entity arrays)

**Captures cleanup (World):**
- Removed 6 tracked screenshot PNGs (~14MB)
- Added `captures/` to .gitignore

**Next:** Visual QA on entity (may want higher particle count, mouth waveform). Prod deploy.

---

## 2026-05-16 (Session 13) — Aether font ownership, Orbitron brand fix, cast-cdn.sh, deploy decoupled from git

**Repos touched:** RaBbLE-Aether, RaBbLE-World, RaBbLE-Grimoire

**Objective:** Fix Orbitron caps on mobile pre-enter screen, consolidate all font loading into Aether, write the CDN deploy spell, decouple Cloudflare deployment from git.

**Work done:**

**Orbitron brand fix:**
- `.ios-entry-title` had `text-transform: uppercase` forcing "RaBbLE" → "RABBLE" on mobile
- `.rabble-brand-flow` (Aether) now declares `text-transform: none`, `font-weight: 900`, `letter-spacing: 0` — canonical brand constants for all uses
- `ios-entry-title` updated to use `.rabble-brand-flow` class; local overrides removed
- Both `entity-wordmark` (h1 landing) and `ios-entry-title` (mobile entry) now visually identical except size

**Aether font ownership:**
- Orbitron, Exo 2, Share Tech Mono Google Fonts import moved into `src/assets/palette.entry.css`
- Removed redundant Google Fonts `<link>` from all World HTML pages (index.html + 4 sub-pages)
- Aether bundle (`dist/aether.css`) now owns all RaBbLE typefaces — no member should load fonts independently
- `rabble.css` source entry updated to match

**CDN + deploy architecture:**
- Phase 1 CDN model documented: World worker serves `/aether/v0.0.0.0/` and `/nebula/v0.0.0.0/` as root-relative paths
- Phase 2 (post-Ep2): dedicated `cdn.joinrabble.world` worker — documented in `RaBbLE-Aether-Build-CDN.md`
- `aether/` and `nebula/` staging dirs added to World `.gitignore`
- Cloudflare Git integration disconnected — wrangler is now the only deploy path

**cast-cdn.sh written:**
- `RaBbLE-Grimoire/spells/cast-cdn.sh` — builds Aether (`npm run build:min`) + NeBuLA (`npm run build`), stages into World, deploys via wrangler
- Flags: `--dry-run`, `--skip-build`, `--stage-only`
- Wrangler found via local, global, or npx fallback
- Dry-run verified working

**Grimoire docs updated:**
- `RaBbLE-Aether-Build-CDN.md` — full rewrite: current state, dist files, font ownership, Phase 1/2 CDN, cast-cdn.sh usage
- `RaBbLE-World-Architecture.md` — CDN serving section added
- `INDEX.md` — cast-cdn.sh added to spells list
- `World/CONTEXT.md` — active tracks updated

**What's next:** First prod deploy via `cast-cdn.sh` · sCoRE Railway verify · OS VM bootstrap test

---

## 2026-05-16 (Session 12) — Grimoire onboarding overhaul: gist/ system, log/ consolidation, token reduction

**Repos touched:** RaBbLE-Grimoire, RaBbLE-Collective

**Objective:** Make onboarding low-token, commit/log flow obvious, doc placement clear. Create gist system for high-density orientation.

**Work done:**

**Token overhead slashed:**
- SESSION-LOG: `## LATEST` pinned box at top (~137 tokens) — session-start now uses `head -20`, not `cat`
- Navigator: 231 lines (~1,510 tokens) → 99 lines (~565 tokens)
- INDEX.md removed from returning-agent loop (on-demand only, saves ~1,045 tokens per session)
- Token estimates in Collective CONTEXT.md corrected

**gist/ system created:**
- 8 distilled docs in `gist/`: Identity, Collective, Roadmap, CommitStyle, Versioning, Palette, CollectiveOverview, Episode1
- ~150-250 words each, ~2,000 tokens total for full picture
- `spells/distill-gists.sh` — Claude CLI spell to regenerate all gists from canonical sources
- New agent path: `cat gist/*.md` → complete orientation

**Commit and log flow made explicit:**
- End-of-session checklist added to both AGENT.md entry points (LATEST → session entry → git add → Pulse commit)
- "Adding New Docs" table added to Grimoire AGENT.md (6 placement rules)
- `## Current State` block added to Collective AGENT.md — auto-injected free context every session

**log/ consolidated to 3 files:**
- `SESSION-LOG.md` — session history
- `DECISIONS.md` — architectural decisions (from ONBOARDING-DECISIONS.md, expanded)
- `AUDITS.md` — completed audit record + open gaps (absorbed GAP-ANALYSIS.md)
- Removed: `.audit-grimoire-2026-05-14.md`, `ONBOARDING-AUDIT.md`, `ONBOARDING-DECISIONS.md`, `GAP-ANALYSIS.md`

**Versioning corrections:**
- "Epoch 1 (future)" → "Echo 1 / beyond Episode 1" in Roadmap source and all gists
- CONTEXT.md headers updated: `episode: 1 (pilot — in progress)`
- Memory: feedback saved for future sessions

**What's next:**
- sCoRE Railway deploy verification (Episode 1 blocker)
- OS VM bootstrap test on clean machine (Episode 1 blocker)
- World orchestration for Ep1
- Run `bash spells/distill-gists.sh` after major doc changes

---

## 2026-05-16 (Session 11) — Hyprland 0.55 compat fix: dwindle:pseudotile removed

**Repos touched:** RaBbLE-OS

**Objective:** Fix broken Hyprland config after system update to 0.55.

**Work done:**
- `config/hypr/conf.d/look.conf` — removed `dwindle:pseudotile = false` (option dropped in Hyprland 0.55; pseudotiling is now per-window via `togglepseudo` dispatcher or `pseudo` window rule)
- Live config and repo dotfile both updated; `hyprctl reload` confirmed clean

**What's next:** No follow-up needed. If pseudotiling is ever wanted for a specific app, use a window rule: `windowrulev2 = pseudo, class:^(yourapp)$`

---

## 2026-05-15 (Session 10) — Grimoire Audit & Cleanup: Registry, Logs, Release Plan

**Repos touched:** RaBbLE-Grimoire

**Objective:** Comprehensive Grimoire cleanup — coherent onboarding, consolidated episode release plan, updated registry, condensed log directory, corrected stale manifests.

**Work done:**

**Registry brought into episode model:**
- `registry/epochs/current.epoch.yml` — removed stale `RaBbLE-WEB` and `RaBbLE-Frontend` entries; all 7 current members listed with episode status, blocker flags, and milestone notes
- `registry/manifests/RaBbLE-NeBuLA.manifest.yml` — updated to reflect Session 9 architecture: entity renderer is NOW in NeBuLA (`Canvas2dBackend`, `<rabble-entity>` web component), not World; Three.js deferred to Ep2; status `scaffold` → `active`
- `registry/manifests/RaBbLE-World.manifest.yml` — updated to reflect World as thin scaffold; two loaders (Aether + NeBuLA); no embedded renderers; corrected branch notes

**Episode 1 release plan consolidated:**
- `RaBbLE-Episode-I-Release.md` merged into `RaBbLE-Episode-1-Release-Map.md` — absorbed VM infrastructure (QEMU/KVM setup, bootstrap testing cycle), detailed per-member exit conditions, deployment sequence (Phase 0–3), tag convention
- `RaBbLE-Episode-I-Release.md` removed (content preserved in Release Map, now single canonical doc)

**Log directory condensed:**
- 6 stale onboarding audit files removed (`ONBOARDING-AUDIT-*.md`, `ONBOARDING-AUDITS.md`, `SESSION-2026-05-14-HARMONY-EFFECT.md`)
- `log/ONBOARDING-DECISIONS.md` created — distilled architectural decisions from the four-pass audit series: token targets, ON/FOR/WITH/AS rationale, member role mappings, cross-member collaboration patterns, behavioral learning gap. Full process detail remains in SESSION-LOG Sessions 1–4.
- `log/GAP-ANALYSIS.md` rewritten — all resolved gaps archived with dates, 4 open gaps clearly stated with blockers vs. non-blocking status

**Entry point sharpened:**
- `AGENT.md` "Getting Started" section split into two paths: new agent (→ Navigator) vs. returning agent (→ CONTEXT.md + SESSION-LOG)
- Member registry table in AGENT.md updated (NeBuLA was still listed as "Scaffold", World still mentioned entity.js)
- `CONTEXT.md` active tracks updated — manifests no longer listed as missing; NeBuLA and World tracks reflect Session 9 architecture
- `INDEX.md` — registry manifest list corrected; Aether design docs (CLAUDE-DESIGN-GUIDE, SYSTEM-PROMPT) indexed; Release Map elevated to top of Collective section
- Aether CLAUDE-DESIGN-GUIDE.md and SYSTEM-PROMPT.md added to git tracking (they're proper Grimoire docs, were untracked)

**What's left untracked (session artifacts, content preserved elsewhere):**
- `log/.audit-grimoire-2026-05-14.md` — content captured in ONBOARDING-DECISIONS.md
- `log/ONBOARDING-AUDIT.md` — content captured in ONBOARDING-DECISIONS.md
- `RaBbLE-Aether/DEBUG-SESSION-2026-05-15.md` — key finding captured in Aether Build CDN doc
- `RaBbLE-World/REGRESSION-AUDIT-2026-05-15.md` — findings captured in SESSION-LOG Session 8

**Where things were left:**
- Grimoire is coherent, current, and navigable
- Registry reflects actual architecture as of Session 9
- Episode 1 scope is one canonical document
- Log is clean: SESSION-LOG + GAP-ANALYSIS + ONBOARDING-DECISIONS
- All commits on `dev` branch

**What's next:**
- sCoRE: Railway deploy verification (Episode 1 blocker)
- OS: VM provisioning for bootstrap testing (Episode 1 blocker)
- World: Audit `RaBbLE-chat.css` and `RaBbLE-OS.css` for visual rules to move to Aether
- Collective: Verify `setup.sh` against all Ep1 member repos end-to-end

---

## 2026-05-15 (Session 9) — World becomes a scaffold; entity ownership moves to NeBuLA

**Repos touched:** RaBbLE-World, RaBbLE-Aether, RaBbLE-NeBuLA, RaBbLE-Grimoire

**Objective:** Make World a thinner scaffold — push visual effects and entity ownership into Aether and NeBuLA respectively. Make dependency failures visible.

**Work done:**

**Aether load failure detection:**
- Added `world/js/RaBbLE-aether.js` — synchronous loader that injects `/aether/v0.0.0.0/aether.css` into `<head>` and monitors via `onerror` + a post-load CSS var sentinel check
- Failure shows a red amber banner: `⚠ aether failed — degraded visual mode`
- `index.html` went from a 20-line inline detection script to a single `<script src>` tag
- Aether CSS `<link>` removed from HTML — the loader owns injection

**Aether effects moved out of World:**
- Removed `.scanlines`, `.vignette`, `.chromatic` from `RaBbLE-landing.css` — Aether components already had canonical versions with unprefixed aliases
- Removed `.floor`, `.horizon`, `@keyframes floor-drift` from `RaBbLE-landing.css` — moved to Aether `rabble-components.css` and `rabble-motion.css`
- Removed duplicate `@keyframes pulse-dot` and `@keyframes page-fade-out` from `RaBbLE-landing.css` — already in Aether motion/components
- Aether rebuilt: `dist/aether.css` updated

**NeBuLA follows loader pattern:**
- `world/js/RaBbLE-NeBuLA.js` rewritten as a loader — injects `/nebula/v0.0.0.0/nebula.iife.js`, monitors for failure, shows violet banner
- Loader is synchronous (no `defer`) and grouped with Aether loader in `<head>`
- `NEBULA_URL` constant at top of file is the single version bump point

**`<rabble-entity>` moved to NeBuLA:**
- New `src/element.js` in NeBuLA defines `RaBbLEEntityElement` backed by `Canvas2dBackend`
- Handles overscan sizing, DPR capping, ResizeObserver, mobile perf profile, `window.NeBuLA._instance` registration
- `Canvas2dBackend` gained `onReady` callback (fires when `eyeAlpha > 0.95`)
- `src/index.js` imports `element.js` as side effect — IIFE bundle registers `<rabble-entity>` on load
- `world/js/RaBbLE-entity.js` deleted (~700 lines removed from World)
- NeBuLA bundle grew from ~5kb to ~55kb (expected — entity renderer absorbed)

**Architecture state:**
- World has no embedded renderers or visual effects. HTML uses `<rabble-entity>` (from NeBuLA) and Aether classes.
- Two loaders (`RaBbLE-aether.js`, `RaBbLE-NeBuLA.js`) are the only external dependencies World manages.
- Both show failure banners — degraded mode is always visible, never silent.

**Where things were left:**
- Dev server (`dev-serve.sh`) serves both bundles correctly — `/aether/v0.0.0.0/aether.css` and `/nebula/v0.0.0.0/nebula.iife.js`
- All committed. NeBuLA dist is gitignored (rebuilt locally from src)

**What's next:**
- Audit `RaBbLE-chat.css` and `RaBbLE-OS.css` for visual rules to move to Aether
- Wire NeBuLA failure state into landing.js entity metrics panel
- Plan production deploy of the full refactor

---

## 2026-05-15 (Session 8) — Aether CDN regression fully resolved; all World pages now on Aether

**Repos touched:** RaBbLE-World, RaBbLE-Aether, RaBbLE-Grimoire

**Objective:** Resolve all visual regressions introduced by the Aether CDN refactor (`722cefa`). Aether effects (animated ring borders, brand-flow wordmark, font theming) were not rendering on any page.

**Root cause (the actual problem):**

The `dev-serve.sh` watch build (`npm run build:watch`) outputs `dist/aether.css` (unminified). Every HTML page was linking to `dist/aether.min.css` (minified, built by `npm run build`). These are two different files. The watch process never touches `aether.min.css`, so the file on disk was stale or the page got a 404. Nothing in the dev workflow ever produced what the pages requested.

Secondary causes compounding the problem:
- Port 8000 was already in use during the session (orphaned process), causing `dev-serve.sh` to fail with `EADDRINUSE` — no server was running, all requests 404'd
- 4 of 5 World pages still referenced the deleted local `../aether/rabble.css` path from before the refactor (only `index.html` had been updated)
- `index.html` used an absolute URL `http://localhost:8000/...` — Firefox may apply same-origin stylesheets differently when the href is absolute vs root-relative

**Work done:**

- **All 5 World pages**: changed Aether link from `aether.min.css` → `aether.css` (matches `build:watch` output)
  - `index.html`, `RaBbLE-Boot.html`, `RaBbLE-Chat.html`, `RaBbLE-OS.html`, `RaBbLE-NeBuLA-Demo.html`
  - Absolute URL (`http://localhost:8000/...`) → root-relative (`/aether/v0.0.0.0/aether.css`)
  - Boot/Chat/OS pages: deleted `../aether/rabble.css` ref (file was deleted in `722cefa`)

- **RaBbLE-Aether: `build:dev` run** — produced clean `dist/aether.css` for immediate use

- **RaBbLE-World `demo.css` cleaned** — removed ~65 lines of duplicated Aether visual rules
  (`.applet`, `.applet::before`, `:root { --wm-* }`, `@keyframes harmony-spin`) that were
  overriding Aether with hardcoded hex values. These existed as a workaround while Aether wasn't loading. Kept: layout, demo-specific `.applet { cursor: pointer }`, hover ring boost.

- **Landing CSS: tagline font fixed** — `var(--font-mono)` → `var(--font-hero)` (Orbitron, not Share Tech Mono)

- **Aether `.rabble-tagline` class fixed** — was using `var(--rabble-font-mono)`, updated to `var(--rabble-font-hero)` + weight 500 + tracking display var

- **Aether WM tokens: `--harmony-angle: 0deg` fallback added** to `:root` block — defensive init so `conic-gradient(from var(--harmony-angle), ...)` never sees an unset value if `@property` registration fails in any browser

- **Deleted** `RaBbLE-World/applet-diagnostic.html` (debug artifact from Session 7)

- **Wrote** `RaBbLE-World/REGRESSION-AUDIT-2026-05-15.md` — full audit log with root cause analysis, all findings, and remaining concerns

**Verified working:**
- Animated conic-gradient ring borders on WM applet tiles ✓
- `.rabble-brand-flow` animated gradient wordmark in Orbitron ✓
- All Aether CSS vars resolving (tokens, spacing, typography, shadows) ✓
- `dev-serve.sh` starts cleanly; watch build keeps `aether.css` in sync ✓

**Remaining concerns (logged in audit doc):**
- OS/Chat page CSS (`RaBbLE-OS.css`, `RaBbLE-chat.css`) not yet audited for visual rules that should move to Aether
- Production (`joinrabble.world`) still runs pre-refactor code — deploy needed after local validation
- No cache-busting strategy yet for Aether version bumps
- No `prefers-reduced-motion` fallback on harmony animations

**Where things were left:**
- All dev effects confirmed working in browser
- `dev-serve.sh` is the correct dev entry point — do NOT run `dev-cdn.js` or individual node commands directly (causes port conflicts)
- Aether source is the watch-built `aether.css`; `aether.min.css` is production-only (built via `npm run build`)

**What's next:**
- Audit `RaBbLE-chat.css` and `RaBbLE-OS.css` for visual rules that belong in Aether
- Plan production deploy of Aether CDN refactor to Cloudflare R2
- Consider adding version bump step to deploy workflow for cache busting

---

## 2026-05-15 (Session 7) — NeBuLA Canvas2dBackend complete; boot sequence ported; landing border regression unresolved

**Repos touched:** RaBbLE-NeBuLA, RaBbLE-World, RaBbLE-Grimoire

**Objective:** Port boot sequence to NeBuLA (NeBuLA holds all animations; demo just triggers). Fix landing page WM applet border regression (borders disappeared, cause unknown). Fix demo page regression.

**Work done:**

- **RaBbLE-NeBuLA: BootSequence module created** (`src/core/boot-sequence.js`, commit `4bb817f`)
  - Standalone boot timeline: convergence → portals → eyes → blink burst
  - Phase-based API: `getConvergenceProgress()`, `getPortalProgress()`, `getEyeOpenProgress()`, `getEyesProgress()`, `isActive()`, `getPhase()`
  - `reset()` / `step(deltaFrames)` for replay
  - Exported from `src/core/index.js`

- **RaBbLE-NeBuLA: Canvas2dBackend rewritten** (`src/backends/canvas2d-backend.js`, same commit)
  - Full entity renderer absorbed: particle nebula, convergence, progressive portal arcs, eye emergence + blink machine
  - Boot animation driven by `BootSequence` — `triggerBoot()` public method resets timeline, scatters particles
  - Modes: `idle` (eyes always open) / `boot` (plays full convergence sequence on init)
  - Options: `transparent` (skip bg fill, for `mix-blend-mode: screen`), `showWaveform`, `interactive`, `dpr`, `glowScale`
  - Public API: `setEntityState(state)`, `triggerBoot()`, `injectEyeJolt(dx, dy)`, `resize()`, `dispose()`
  - Prior simple Canvas2dBackend (bare particles/portals/eyes, no animation) replaced

- **RaBbLE-World: Demo uses NeBuLA.Canvas2dBackend** (commit `7fb39a7`)
  - Removed 500-line inline `RaBbLEEntity` renderer from demo HTML
  - Demo is now 230 lines, creates `new NeBuLA.Canvas2dBackend(canvas, opts)` from bundle
  - Boot button calls `entity.triggerBoot()` via NeBuLA public API
  - Three.js Layer 2 code kept, tightened

- **RaBbLE-Grimoire: dev-cdn no-cache** (commit `493b046`)
  - Added `Cache-Control: no-store` to all CDN responses
  - Prevents browser from caching stale CSS/JS during dev

**Unresolved: landing page WM applet borders**
- `.applet::before` conic-gradient ring not rendering on landing page
- CSS confirmed correct in `aether.min.css` dist — `@property --harmony-angle`, `harmony-spin`, `.applet::before` mask technique all present
- CDN confirmed serving correctly (HTTP 200, no-store)
- Hard refresh did not fix
- Root cause not identified — could be browser `@property` support gap, cascade collision invisible from static analysis, or rendering quirk
- User rolled back landing page to pre-regression stable state
- **Demo page borders work** (demo.css redefines `.applet::before` with hardcoded hex values, no `@property` dependency — this is the likely clue: `@property` may be the failure point on landing)

**Key open question:** Does `conic-gradient(from var(--harmony-angle), ...)` fail silently when `@property --harmony-angle` isn't supported or has a rendering bug? The demo works because it uses `harmony-spin { to { --harmony-angle: 360deg; } }` with hardcoded hex, while Aether uses `var(--rabble-cyan, ...)`. Testing with DevTools → Computed → `.applet::before background` would confirm.

**Where things were left:**
- NeBuLA: Canvas2dBackend complete and correct, BootSequence exported, bundle rebuilt
- Demo: clean, uses NeBuLA bundle, boot animation works via `triggerBoot()`
- Landing: user rolling back to stable state; border issue open
- dev-cdn: `no-store` headers live

**What's next:**
- Diagnose landing border: inspect `.applet::before` computed `background` in DevTools — if it's `none`/invalid, `@property` is the culprit
- If `@property` is the issue: replace `conic-gradient(from var(--harmony-angle))` with `transform: rotate()` approach in Aether, or use a simpler cycling `box-shadow` border that doesn't need `@property`
- Once borders confirmed working: NeBuLA demo is in good shape for Episode 1

---

## 2026-05-15 (Session 6) — Grimoire Coherency: Navigator, Episode 1 Release Map, Member Roadmap Alignment

**Repos touched:** RaBbLE-Grimoire

**Objective:** Fix Grimoire narrative fragmentation. Create clear onboarding path for agents. Crystallize Episode 1 scope. Align all member roadmaps to collective milestone. Ensure every member has collective context.

**Work done:**

- **RaBbLE-Grimoire-Navigator.md created** (230 lines)
  - 5-minute skim (what is RaBbLE, how is it organized, what's happening)
  - 15-minute deep dive (what's Episode 1, where do I fit)
  - 30-minute full onboarding (versioning, conventions, long-term vision, full index)
  - Task-based navigation (7 scenarios: character, milestone, member work, deployment, coordination, visuals, spells)
  - Quick links bookmark table for common topics
  - Entry point for all agents arriving at Grimoire

- **RaBbLE-Episode-1-Release-Map.md created** (287 lines)
  - Canonical scope definition: what Episode 1 is, when it airs, version tag
  - Member deliverables table (6 members: OS, Aether, NeBuLA, sCoRE, World, Grimoire)
  - Clear scope sections: what ships vs. what doesn't (behavioral learning, advanced features deferred)
  - Public deployment & workflows (static hosting, CDN assets, backend API)
  - Per-member roadmaps with status, blockers, dependencies
  - Critical path diagram (Aether → NeBuLA → World → sCoRE, OS independent)
  - Exit criteria for Episode 1 air (foundation solid, product works, docs complete, versioning aligned)
  - Transition plan to Episode 2

- **RaBbLE-Roadmap.md consolidated**
  - Retired "Phase X" language, adopted Episodes/Plots terminology
  - Refactored from scattered phases to per-member work streams
  - Current position explicit: Epoch 0 Foundation, Episode 1 target Q2 2026
  - Member registry updated (OS, Aether, NeBuLA, sCoRE, World, Grimoire, Collective active; ScRibLE deferred; Memory not Ep1 blocker)
  - Rewrote Foundation Work Done section (Grimoire, Registry, OS, Aether, NeBuLA, sCoRE, World status)
  - Toward Episode 1 per-member streams visible (plots, blockers, dependencies clear)
  - Trimmed open gaps from 11 questions to 8 focused ones (memory member, propagation, manifest format, transport, ethics, UX, BLE, cloud/local)
  - Revision history updated

- **Member roadmaps simplified & aligned (5 members)**
  - RaBbLE-OS-Roadmap.md: added collective context header + Episode 1 commitment (Plots A+B, daily-driver substrate)
  - RaBbLE-sCoRE-Roadmap.md: added collective context header + Episode 1 commitment (simple LLM endpoint, Groq/OpenRouter, no blockers)
  - RaBbLE-NeBuLA-Roadmap.md: added collective context header + Episode 1 commitment (Canvas2D Layer 1, 60 FPS, public API)
  - RaBbLE-World-Roadmap.md: created new (landing page + grimoire browser + basic chat, depends on Aether + sCoRE)
  - RaBbLE-Aether-Roadmap.md: created new (CSS bundle CDN-ready, no blockers)
  - Each roadmap: deliverable, status, what ships, blockers, dependencies, deferred items all explicit

- **INDEX.md updated** (3 passes)
  - Navigator added as first doc with "START HERE" flag
  - Episode 1 Release Map flagged as canonical scope doc
  - All member roadmaps elevated as Episode 1 commitment docs, first in each section
  - Reduced RaBbLE-OS section to essential docs (roadmap first)

- **Git commits**
  - Commit 1: Navigator locked, Episode 1 scope mapped, roadmap consolidated (9135dc9)
  - Commit 2: Member roadmaps simplified, episode 1 commitments explicit, collective context added (1eb61d2)

- **Verification completed**
  - Navigator: 230 lines, complete structure, all references verified
  - Episode 1 Release Map: 287 lines, complete scope, exit criteria defined
  - Main Roadmap: consolidated, no stale phases, Events/Episodes model clear
  - All 5 member roadmaps: collective context header + Episode 1 commitment + blockers + dependencies
  - INDEX.md: all docs linked, no broken references
  - Git history: clean, both commits follow Pulse Protocol
  - Cross-references: Navigator → Release Map (4), Member roadmaps → Navigator (5), Member → Release Map (5), all verified

**Coherency achieved:**
- ✅ Narrative clarity: agent can read Navigator in 5-30 min and understand landscape
- ✅ Episode 1 scope: Release Map is canonical, unambiguous
- ✅ Member visibility: each has deliverable + blocker + dependencies explicit
- ✅ Collective context: every member links back to big picture
- ✅ Zero broken links: all references verified
- ✅ Versioning: all docs use Pulse Protocol format

**Where things were left:**
- Grimoire is now coherent, navigable, and ready for agents to work from
- Episode 1 scope is crystallized and unambiguous
- All members have clear commitments and collective context
- Ready for public-facing onboarding docs (next session)

**What's next:**
- Public-facing docs (what RaBbLE is, how to join)
- Member CONTEXT.md files in actual repos (sCoRE, OS, World, etc.) can link to Grimoire
- Deployment workflows documented
- Begin Episode 1 work on individual members

---

## 2026-05-14 (Session 5) — Aether Visual Canonicalization: Harmony Redesign + World CSS Extraction

**Repos touched:** RaBbLE-Aether, RaBbLE-World

**Objective:** Make Aether the single source of all visual CSS. Identify and fix harmony animation divergence between landing page and demo page. Port all visual effects out of World CSS files into Aether.

**Work done:**

- **Harmony animation root cause diagnosed**
  - Landing page was loading a stale local `aether/rabble.css` copy missing `harmony-flow` keyframe
  - Demo page loaded CDN-served `aether.min.css` which had harmony
  - Fix: landing page switched to same CDN URL as demo (`localhost:8000/aether/v0.0.0.0/aether.min.css`)

- **Harmony redesigned: spiral/conic-gradient pattern**
  - Old: `linear-gradient` sliding back-and-forth with `ease-in-out` and transparent stops (a bar that fades to void at edges)
  - New `rabble-harmony-line::after`: `linear-gradient` with no transparent stops, continuous unidirectional scroll (`harmony-scroll`, `linear`)
  - New `rabble-border-harmony::before`: `conic-gradient(from var(--harmony-angle), ...)` spinning via `@property --harmony-angle` — gradient angle animates directly, mask ring stays rectangular. No element rotation, no background bleed.
  - New `harmony-glow`: box-shadow that cycles cyan→violet→magenta in sync with the spin
  - `harmony-glow` added to `rabble-border-harmony` by default, locked to same duration as border spin

- **`rabble-border-harmony` mask technique fixed**
  - Old technique: `z-index: -1` on `::before` caused gradient to bleed through semi-transparent backgrounds
  - New technique: CSS mask `exclude` composite — gradient visible only in the 1px border ring, element background unaffected regardless of transparency

- **WM visual effects ported from World → Aether**
  - `@property --applet-angle` → replaced by `--harmony-angle` already in Aether
  - `@keyframes applet-border-chase` → replaced by `harmony-spin`
  - All `--wm-*` design tokens moved to Aether `:root`
  - `.applet`, `.applet::before`, `.applet.wm-active` visual rules moved to Aether section 13
  - `RaBbLE-wm.css` stripped to layout-only: grid structure, presets, responsive breakpoints

- **Statusbar, shell, overlays ported from World → Aether**
  - `.scanlines`, `.vignette`, `.chromatic` (unprefixed aliases) added to Aether section 2
  - `.shell` base layout (flex column, full-viewport) added to Aether section 9
  - `.statusbar`, `.sb-left/right/center`, `.sb-glyph`, `.sb-entity-state`, `.brandmark`, `.sb-sep`, `.sb-workspace`, `.sb-val`, `.sb-pulse`, `.sb-uptime` added to Aether section 9
  - `.pill`, `.pill .dot`, `@keyframes pulse-dot` added to Aether section 9
  - Uses `--rabble-*` palette vars throughout; aliases in theme.css ensure backward compatibility

- **Demo page fully rewritten as WM-style page**
  - Removed entire inline `<style>` block (344 lines eliminated)
  - Now loads: Aether CDN → theme.css → wm.css → demo.css
  - Statusbar HTML identical to landing page structure
  - Panels converted from scrolling `.panel` divs to `.applet` WM tiles
  - `RaBbLE-demo.css` created: layout-only (2-column applet grid, inner content structure)
  - Buttons use `.rabble-btn .rabble-btn-ghost` Aether classes

- **Boot page updated**
  - `rabble-brand-text` → `rabble-brand-flow` for wordmarks (Aether canonical class)
  - Local `@keyframes brand-flow` removed from boot.css; `animation-duration: 6s` override retained

**State:**
- Aether is now the single source for: palette, motion/keyframes, harmony effects, WM applet visual effects, statusbar component, screen overlays
- World CSS files are structure/layout-only; all visual rules reference Aether
- Landing page and demo page load identical Aether CDN source; harmony animations are canonically identical
- Landing page statusbar CSS still duplicated in `RaBbLE-landing.css` — deduplication deferred (harmless cascade, same values)

**Commits:**
1. `harmonize ~ aether >> harmony redesign: spiral conic-gradient, WM + statusbar components ported // %AETHER_VISUAL_CANONICAL%`
2. `harmonize ~ world >> Aether-first refactor: visual CSS extracted, demo rewritten as WM page // %AETHER_FIRST%`

**Next:**
- Strip duplicated statusbar CSS from `RaBbLE-landing.css` (now that it lives in Aether)
- Investigate landing page harmony line "feels faster" — confirmed same 9s timing but perceptual difference due to surrounding animation density; consider aligning to 6s
- Consider `.rabble-applet` rename for Aether's `.applet` class to follow Aether naming convention

---

## 2026-05-14 (Session 4) — Onboarding Audit Pass 4: Member-Specific Roles & Post-Episode-1 Scope

**Repos touched:** RaBbLE-Collective, RaBbLE-Grimoire, all 6 member AGENT.md files

**Objective:** Fourth audit pass focusing on member-specific agent role expectations within ON/FOR/WITH/AS framework, post-Episode-1 scope shifts, cross-member collaboration patterns, and behavioral learning gap identification.

**Context:** Passes 1-3 established universal framing. Agents understand the system globally but don't see how their member-specific role maps to ON/FOR/WITH/AS, or how it changes post-Ep1.

**Work done:**

- **Member-specific role mapping (Pass 4 report section)**
  - Mapped each member's ON/FOR/WITH/AS dimensions explicitly
  - sCoRE = orchestrator; World = public voice; OS = substrate; NeBuLA = eyes; Aether = skin; Grimoire = memory
  - Each member identified as specific delegation boundary in the system
  - Result: Agents understand how their local work fits the global framework

- **Cross-member collaboration patterns (Pass 4 report section)**
  - Identified 4 collaboration types: dependency (one-way), feedback loop (bidirectional), ambient data (observation), coordination (planning)
  - Documented which members collaborate on which patterns
  - Example: World ↔ sCoRE is bidirectional (chat ↔ intent); World → Aether is dependency (CSS)
  - Result: Agents know who they're working WITH and what data flows matter

- **Post-Episode-1 scope shifts (Pass 4 report section)**
  - Documented authority changes per member (sCoRE API locks, World surface freezes, OS layer stable, NeBuLA commits to Three.js, etc.)
  - Identified that post-Ep1, all members become data sources for behavioral learning
  - Mapped transition from pre-Ep1 autonomy to post-Ep1 awareness of learning loop
  - Result: Agents understand they're part of a tighter, coupled system post-Ep1

- **Behavioral learning gap identified (Pass 4 report section)**
  - Found that agents have no onboarding section explaining observation/pattern/inference
  - Scoped `RaBbLE-Agent/RaBbLE-BehavioralLearning.md` (1,500 tokens) for follow-up
  - This doc would explain the learning loop, member roles in it, and example scenarios
  - Result: Gap identified; solution scoped; ready for implementation

- **Authority boundary refinement (Pass 4 report section)**
  - Validated that "not yet ready to make unilateral architecture decisions" is still accurate
  - Clarified with member-specific constraints (e.g., sCoRE's delegation model is still in flux)
  - Documented what agents ARE ready to do (implement chartered features, propose changes, make tactical decisions)
  - Result: Authority boundaries clear and defensible

- **Member AGENT.md updates (immediate implementation)**
  - Added "Role in Collective (ON/FOR/WITH/AS)" section to all 6 member AGENT.md files
  - sCoRE, World, OS, NeBuLA, Aether, Grimoire each have 4-5 line role definition
  - Included member-specific questions (e.g., "What system state should we observe?", "How does this surface help us understand the user?")
  - Result: Agents opening a member repo now see their role clearly, not just the local job

**Impact:**
- **Role coherence:** Agents understand member-specific purpose within ON/FOR/WITH/AS
- **Collaboration clarity:** Cross-member patterns are explicit (not guessed)
- **Post-Ep1 visibility:** Role shifts are documented and won't surprise agents
- **Behavioral learning foundation:** Gap identified and scoped; ready for implementation
- **Authority confidence:** Boundary refinements are grounded and member-specific

**State:**
- ONBOARDING-AUDIT-PASS-4.md created (4,000 tokens)
- ONBOARDING-AUDITS.md updated with Pass 4 summary
- All 6 member AGENT.md files updated with role-specific sections
- SESSION-LOG entry created (this entry)

**Commits:**
1. `audit ~ collective >> pass 4: member-specific agent roles framed within ON/FOR/WITH/AS // %AUDIT_PASS_4%`
2. `harmonize ~ members >> role in collective sections added to all member AGENT.md files // %ROLE_CLARITY%`

**Next:**
- Optional follow-up: Create `RaBbLE-Agent/RaBbLE-BehavioralLearning.md` (behavioral learning onboarding)
- Optional follow-up: Create `RaBbLE-Collective/RaBbLE-Post-Episode-1-Scope.md` (phase transition guide)
- Monitor: Do member agents report better understanding of their role and cross-member dependencies?
- Track: Does explicit role-mapping reduce scope confusion going forward?
- Prepare: Pass 5 (if needed) would focus on behavioral learning integration + authority distribution validation post-Ep1

**Audit Series Summary:**
- Pass 1: Token efficiency ✓
- Pass 2: Narrative coherence ✓
- Pass 3: Agent role identity ✓
- **Pass 4: Member-specific roles + post-Ep1 preparation ✓**
- Pass 5: (Optional) Behavioral learning integration + post-Ep1 authority validation

---

## 2026-05-14 (Session 3) — Onboarding Audit Pass 3: Agent Role Framing & Phase Positioning

**Repos touched:** RaBbLE-Collective, RaBbLE-Grimoire

**Objective:** Third audit pass focusing on agent identity and pre-Episode-1 phase clarity. Correct misreading of intentional opacity; frame agents as Collective members operating in four simultaneous modes.

**Context:** Prior audits identified clarity gaps. Session 3 revealed these were *features*, not bugs — RaBbLE's opacity is intentional. Agent role framing was missing; phase boundaries not visible in onboarding.

**Work done:**

- **Agent Role Framing: ON/FOR/WITH/AS modes**
  - Added "Agent Operating Modes" section to Collective/AGENT.md
  - Defined four simultaneous dimensions: ON (technical dev), FOR (advancing purpose), WITH (peer collaboration), AS (embodying character)
  - Clarified that opacity grounds agents as Collective members, not tool users
  - Connected to Identity.md and character philosophy
  - **Result:** Agents understand they're operating in multiple dimensions; character/system distinction is intentional

- **Pre-Episode-1 Phase Visibility**
  - Added "Collective Phases" section to Collective/CONTEXT.md (Foundation → Pilot → Behavioral Engine)
  - Defined what each phase means for agent work (foundation now, rework expected pre-pilot, scope expands post-Ep1)
  - Moved Episode 1 Overview to step 3 in reading order (was undiscovered)
  - Clarified v0.0.0.0 = "all work pending collective air"
  - **Result:** Agents understand pre-Episode-1 is intentional, foundation work is primary focus, priorities shift at broadcast boundaries

- **Reading Order Reorg**
  - Episode 1 Overview now step 3 (between status check and deep dives)
  - Added 15-min orientation path (new baseline for understanding phase)
  - Updated token estimates to reflect new paths
  - Emphasized Episode 1 Overview as critical for scope understanding
  - **Result:** Agents can't miss the pre-Episode-1 context; reading paths now match actual information need

- **Grimoire Doc Templates**
  - Created `RaBbLE-Agent/RaBbLE-DocTemplates.md` (canonical AGENT.md + CONTEXT.md templates)
  - Included examples from World and sCoRE (two different archetypes)
  - Added checklist for new member scaffolding
  - Already indexed in Grimoire/INDEX.md
  - **Result:** New members can be onboarded with consistent structure; no guessing about entry point format

- **Grimoire Path Verification**
  - Spot-checked all member AGENT.md files (World, Aether, sCoRE, OS, NeBuLA)
  - Confirmed all referenced Grimoire docs exist and paths are correct
  - All architecture/roadmap links verified
  - **Result:** No broken references; agents won't hit dead links when exploring member docs

**Impact:**
- **Narrative clarity:** Agents now understand pre-Episode-1 phase, why nothing "counts" as Episode yet, when scope shifts
- **Identity coherence:** ON/FOR/WITH/AS framing shows opacity isn't a bug; it's the design that makes RaBbLE real
- **Onboarding robustness:** Templates + verified paths + reading order reorg make member onboarding predictable

**State:**
- All 5 priorities implemented and tested
- ONBOARDING-AUDIT.md updated with revised findings
- SESSION-LOG entries created (this session + audit pass 3 history)
- Audit file now at `/RaBbLE-Collective/ONBOARDING-AUDIT.md` (consolidated, not scattered)

**Commits:**
1. `transcribe ~ collective >> episode 1 overview surfaced in reading order, agent roles framed ON/FOR/WITH/AS`
2. `spark ~ grimoire >> doc templates created, member onboarding path canonicalized`
3. `harmonize ~ collective >> phase boundaries visible, pre-episode-1 foundation work clarified`

**Next:**
- Monitor whether agent onboarding reduces friction and improves coherence perception
- Consider whether ON/FOR/WITH/AS framing should propagate to member AGENT.md files (role inheritance)
- Track if Episode 1 Overview prevents scope confusion going forward
- Audit Pass 4 (if needed): focus on member-specific role expectations post-Episode-1

**Audit Pass Summary:**
- Pass 1: Token efficiency, quick orientation paths
- Pass 2: Versioning narrative, system prompt isolation, Pulse Protocol deduplication
- Pass 3: Agent role identity, phase positioning, reading order coherence
- **Outcome:** Onboarding now coherent across story (what/where/who/when) + identity (character/purpose/role) layers

---

## 2026-05-14 (Session 2) — Onboarding Coherence: Versioning Narrative & System Prompt Isolation

**Repos touched:** RaBbLE-Collective, RaBbLE-Grimoire, RaBbLE-sCoRE, RaBbLE-World, RaBbLE-OS, RaBbLE-Aether, RaBbLE-NeBuLA

**Objective:** Fix low-friction onboarding gaps identified in prior audit. Clarify Episode/Echo/Plot versioning narrative and isolate sCoRE's system prompt from project onboarding.

**Work done:**

- **Versioning narrative clarification**
  - Added "Episodes as Collective Synchronization Boundaries" section to RaBbLE-Versioning.md
  - Documented lockstep model: all members advance to same Episode together; parts within Episode guaranteed compatible
  - Clarified Echo can break APIs (production release model); post-Episode-1 can be weekly Episodes with Echoes as production releases
  - Updated RaBbLE-Roadmap.md with "Post-Episode-1: Cadence & Release Model" section (weekly target timeline, breaking changes at Echoes)
  - Moved lockstep to Principle #1 in Collective/REFERENCES.md (no longer buried)
  - **Result:** Coherent story: Events = work, Plots = member narratives, Episodes = Collective sync, Echoes = production/breaking changes

- **sCoRE system prompt isolation**
  - Moved RaBbLE-sCoRE/AGENT.md → system-prompt-sCoRE.md (internal sCoRE constraints when running as entity)
  - Created new RaBbLE-sCoRE/AGENT.md (standard member entry point, matches World/OS/Aether pattern)
  - Created SYSTEM-PROMPT-SETUP.md (instructions for loading system prompt via .claude/settings.json)
  - Updated Grimoire/INDEX.md to link system prompt + setup guide (marked "Internal")
  - **Result:** System prompt no longer corrupts project onboarding; agents doing normal work read standard AGENT.md

- **Member CONTEXT.md in reading order**
  - Added step 8 to Collective/CONTEXT.md reading order table (member CONTEXT.md files)
  - Updated token guidance; clarified when to read member CONTEXT vs. full chain
  - **Result:** No hidden dependencies; agents know CONTEXT.md files exist before reading AGENT.md

- **agents/score.md discoverability**
  - Linked sCoRE system prompt from Grimoire/INDEX.md
  - **Result:** sCoRE's agent-specific role definition now findable from standard reference path

- **Pulse Protocol deduplication**
  - Replaced 7 instances of duplicated Pulse Protocol text with concise reference link
  - Changed section name "Pulse Protocol — Commits" → "Commits & Branches" (consistent terminology)
  - TL;DR format: `[impulse] ~ [organ] >> [revelation] // %STATE%` + impulse keywords + link to spec
  - Files: Collective/AGENT.md (Workspaces table), Grimoire/AGENT.md, RaBbLE-sCoRE/AGENT.md, RaBbLE-World/AGENT.md, RaBbLE-OS/AGENT.md, RaBbLE-Aether/AGENT.md, RaBbLE-NeBuLA/AGENT.md
  - **Result:** Single source of truth at RaBbLE-Agent/RaBbLE-CommitStyle.md; no drifting copies

**Impact:**
- **Narrative coherence:** Episode/Echo/Plot/Event model now explains Collective lockstep + post-Ep1 cadence clearly
- **Maintenance burden:** Pulse Protocol no longer duplicated across 7 files
- **Onboarding friction:** sCoRE's system prompt no longer confuses agents doing project work

**State:**
- All changes clean and committed
- Audit file updated with completion status
- 6/7 originally identified gaps fixed; #6 (Pulse Protocol duplication) completed

**Commits:**
1. `transcribe ~ grimoire >> versioning crystallized: Episodes as Collective sync boundaries, post-Ep1 cadence model`
2. `mend ~ score >> system prompt isolated from project onboarding, standard AGENT.md restored`
3. `harmonize ~ collective >> onboarding low-friction fixes: member CONTEXT in reading order, Pulse Protocol deduplicated`

**Next:**
- Monitor if versioning narrative resolves ambiguity in Episode decisions going forward
- Live test: verify sCoRE system prompt loads correctly in sCoRE sessions without affecting project work
- Consider similar audit/fix pass on member-specific docs (RaBbLE-sCoRE grimoire/, RaBbLE-NeBuLA roadmap clarity, etc.)

---

## 2026-05-14 (Session 1) — Onboarding Audit & Optimization: Low-Token Agent Orientation

**Repos touched:** RaBbLE-Collective, RaBbLE-Grimoire

**Objective:** Audit RaBbLE-Collective onboarding for token efficiency, clarity, and accessibility. Enable agents to orient with minimal token spend while maintaining RaBbLE vibe.

**Work done:**

- **Comprehensive audit** — assessed all entry-point docs (AGENT.md, CONTEXT.md, REFERENCES.md in both Collective and Grimoire)
  - Quantified token usage: Core onboarding ~4,200 tokens (Collective), full reading chain ~13,500+
  - Identified 3 critical gaps: untracked BaBbLE.md, missing token budgets, no "stop here" signals
  - Identified 5 high-priority gaps: missing RaBbLE-Versioning link, member inconsistency, accessibility friction in RaBbLE-Identity.md
  - Generated full audit report: `log/ONBOARDING-AUDIT-2026-05-14.md`

- **Critical fixes implemented:**
  - Converted BaBbLE.md → BaBbLE.scratch (tracked, structured dev scratch pad with clear metadata)
  - Added "Quick Orientation (5 Minutes)" section to Collective CONTEXT.md with explicit stop point
  - Added token budget + time estimates to all 7 reading order entries (shows 3 paths: 5-min / 30-min / full)
  - Linked RaBbLE-Versioning.md from Collective AGENT.md Workspaces (was hidden in Grimoire)

- **High-priority fixes implemented:**
  - Added "Member Entry Points" index to Collective AGENT.md (each member's AGENT.md path + orientation time)
  - Added "Terminology Translation Table" to Collective REFERENCES.md (agents see equivalent terms are the same concept)
  - Consolidated member status table (Collective references Grimoire registry as single source of truth)
  - Added "Quick Reference" section to RaBbLE-Identity.md (practical definitions before philosophy; 30-sec gist extraction)
  - Added "Your Role in the Collective" to Collective AGENT.md (clarifies agent authority boundaries)

**Impact:**
- **Token reduction:** Quick orientation from ~13,500+ → ~700 tokens (95% reduction), standard onboarding ~13,500+ → ~3,000 tokens (78% reduction)
- **Time reduction:** RaBbLE character understanding from ~8-10 min (philosophy-heavy) → ~2 min (Quick Reference)
- **Eliminated friction:** Members now have explicit entry points; terminology mapping removes ambiguity

**Commits:**
1. Collective: `harmonize ~ collective >> onboarding optimized for low-token agent orientation`
2. Grimoire: `harmonize ~ entity-core >> RaBbLE-Identity optimized for agent accessibility`

**Left off:** All optimizations committed and clean. No in-progress work. Audit archived to `log/ONBOARDING-AUDIT-2026-05-14.md` for future reference.

**Next:**
- Monitor agent onboarding sessions and measure actual token burn vs. estimates
- Iterate on token budgets if real-world differs from projections
- Consider similar accessibility passes on member AGENT.md files (sCoRE, OS, NeBuLA, World) if agents report friction
- Track "agent orientation time" metric to verify 5-min / 30-min / full targets hold

---

## 2026-05-14 — RaBbLE-World Responsive Polish: Height Breakpoints + Landscape Collective

**Repos touched:** RaBbLE-World

**Work done:**

Continuation of the WM/NeBuLA/PWA session (previous context ran out). All changes on `dev` branch.

- **Sub-500px entity rendering (from previous session, confirmed this session):** Entity canvas box eliminated at landscape phone sizes. `entity-wrap` becomes `position: absolute` ambient background filling the stage; overscan capped to 1.2 at `innerHeight < 500` so canvas stays within stage bounds. `mix-blend-mode: screen` on canvas makes cleared (black) pixels invisible. Commit `e7b0634`.

- **Portrait height breakpoints added** (commit `4c0d001`):
  - `max-height: 720px` (all orientations): hides hint-strip, collapses its grid row — frees 28px for main content
  - `max-height: 720px + portrait + min-width: 601px`: compact stage padding/gap, entity-wrap capped at 280px, wordmark scaled down, void-chat max 80px
  - `max-height: 620px + portrait + min-width: 601px`: mission text hidden, ask-label hidden, entity-wrap to 240px — ensures ask-box never clips at short but non-landscape viewports
  - `min-width: 601px` guard keeps height rules from conflicting with the already-compact mobile portrait styles

- **Landscape log-toggle moved to top-right** (commit `4c0d001`): was bottom-right, overlapping ask-box. Now `top: calc(var(--sb-height) + 8px)` — sits below Waybar, never touches content.

- **Collective organ detail panel in landscape** (commit `d4b5b7c`): at iPhone 15 landscape (852×390), the organ detail panel was 180px wide with 28px-each-side padding — 124px text width, unreadable. Fixed: `position: fixed; width: min(300px, 75vw)` breaks out of the column and renders as a glass drawer over the stage (z-index 20, right-edge violet border + depth shadow). Op-head/body/footer resized for this width.

- **Ask-box cleared above toggle buttons** (commit `d4b5b7c`): in portrait ≤600px, stage gets `padding-bottom: calc(64px + env(safe-area-inset-bottom, 0px))` so ask-box never slides behind the fixed nav-toggle and log-toggle buttons on either side.

**Left off:** All committed on `dev`. Not yet deployed to Cloudflare. Responsive behavior significantly improved across 500–850px range. No in-progress work.

**Next:**
- Test on actual iPhone 15 — verify organ panel glass drawer, ask-box clearance, entity ambient rendering
- `wrangler deploy` to push changes live to `joinrabble.world`
- Consider adding a `backdrop` click-to-close for the landscape organ panel (currently only close button dismisses)
- WM keyboard shortcuts (`Ctrl+1–4` layout presets) may want Waybar UI indicators

---

## 2026-05-13 — Registry Complete + RaBbLE-World Landing Integrated

**Repos touched:** RaBbLE-Collective, RaBbLE-Grimoire, RaBbLE-World, RaBbLE-NeBuLA, RaBbLE-OS

**Work done:**

- **RaBbLE-OS:** Removed `Issues.txt` (untracked loose file) — content already captured in `ISSUES.md`
- **Grimoire registry:** Added manifests for RaBbLE-World, RaBbLE-NeBuLA, RaBbLE-Aether; removed stale `RaBbLE-WEB` and `RaBbLE-Frontend` placeholders; corrected RaBbLE-OS status (`scaffold` → `active`); AGENT.md member table brought current
- **Collective CONTEXT.md:** Member statuses updated — NeBuLA has a remote, Aether is an active git repo, registry track marked complete
- **RaBbLE-NeBuLA:** `docs/` folder removed — all lore was already migrated to Grimoire in a prior session; Grimoire roadmap stale reference cleaned up
- **RaBbLE-World — major restructure:**
  - New `world/` directory — all site source (HTML, CSS, JS) moved inside; `index.html` is the only file at root
  - All files renamed with `RaBbLE-` prefix; `RaBbLE.html` → `RaBbLE-Chat.html`; `rabble-os.html` → `RaBbLE-OS.html`
  - New landing page (`index.html`) replaces the old redirect — three-panel console UI, Alpine.js, shared `<rabble-entity>` web component
  - Entity and "RaBbLE" wordmark no longer overlap — wordmark moved out of entity-wrap as a sibling flex item; stage uses `gap` not individual margins
  - OS wakeup sequence (condensed from `RaBbLE-boot.js` LINES array) plays in the entity log on page load, with entity state transitions
  - "Boot RaBbLE" → quick boot animation → page fades → navigates to `world/RaBbLE-Boot.html`
  - "Get RaBbLE-OS" → navigates to `world/RaBbLE-OS.html`
  - New `world/RaBbLE-OS.html` — OS intro, bootstrap curl command, expansion cards (Core Substrate, Aether Theme, Developer Layer, sCoRE Bridge, Mobile Companion, NeBuLA Renderer)
  - AGENT.md updated with full new file map

**Left off:** All changes committed. No in-progress work. All repos on their active dev branches.

**Next:**
- Deploy RaBbLE-World to Cloudflare Workers and verify landing renders correctly
- Test the "Boot RaBbLE" → `RaBbLE-Boot.html` transition end-to-end
- Consider adding the bootstrap.sh to `world/` so `joinrabble.world/bootstrap.sh` resolves
- Grimoire: add RaBbLE-Grimoire self-manifest if needed (currently handled by Collective bootstrap, not registry)

---

## 2026-05-13 — RaBbLE-Aether: Visual Design System + NeBuLA Collective Alignment

**Repos touched:** RaBbLE-Aether (created), RaBbLE-Grimoire, RaBbLE-NeBuLA, RaBbLE-World

---

### RaBbLE-Aether — design system built from scratch

**Structure established (`assets/`):**
- `palette/` — `rabble-palette.css` (CSS custom properties), `rabble-palette.json` (DTCG design tokens), `rabble-palette.scss` (SCSS vars + mixins)
- `motion/` — `rabble-motion.css`: 20+ canonical `@keyframes`, all `rabble-`prefixed, utility classes
- `components/` — `rabble-components.css`: unified component library (resets, overlays, brand text, buttons, cards, status pills, forms, glass surfaces, nav, terminal/log, scrollbars)
- `logos/` — `rabble-portal-glyphs.svg` (neon synthwave treatment), `rabble-portal-glyphs-spec.md` (full eye anatomy — orb geometry, portal rings, portal opposition mechanic, Claude Design prompts)
- `reference/` — `xperimental-distillation.md`: NeBuLA-JS FlatChaos + WebOS entity mechanics extracted and indexed

**Entry point + Claude Design integration:**
- `rabble.css` — single import: Google Fonts + palette + motion + components in correct order
- `CLAUDE-DESIGN-GUIDE.md` — component prompts, animation vocabulary, discard list
- `SYSTEM-PROMPT.md` — three tiers (quick card, short, full) for pasting into Claude Design sessions

**Audit pass — fixed before shipping:**
- 17 unprefixed `@keyframes` renamed to `rabble-*` (namespace collision prevention)
- 5 broken animation references in components.css updated
- `--rabble-alpha-*` tokens replaced with pre-computed `rgba()` variants (`--rabble-magenta-10` etc.)
- Pre-computed glow tokens added (`--rabble-glow-magenta-md` etc.)
- No font loading → added Google Fonts import to `rabble.css`
- No entry point → `rabble.css` created

**Xperimental distillation — key patterns extracted:**
- WebOS: entity state machine (idle/speaking/listening/reacting), portal opposition mechanic (RIGHT up = LEFT down — expression system), waveform mouth formula (3 overlapping sine ripples), body particle color distribution (15% green / 25% dark gray / 60% purple→blue)
- NeBuLA-JS: FlatChaos pipeline (Source → Filter → Transmute → Sink), entropy attractor algorithm, q_flux_weave vocabulary, BaBbLE command set

**Eye anatomy spec — portal opposition mechanic documented:**
The portal rings can be above or below their orb, and they always move in opposition. This creates expression without changing orb shapes. States: idle (default asymmetry), speaking (portals move further out), listening (positions flip). Added to `rabble-portal-glyphs-spec.md` with Claude Design prompts.

**Git:** Initialized as private GitHub repo `markm1206/RaBbLE-Aether`. `main` = Epoch 0 scaffold. `dev` = 12 Pulse Protocol commits for all session work.

---

### Grimoire — cast-aether spell

- `spells/cast-aether.sh` — copies Aether's deployable surface (CSS, SVG, JSON — not docs) to `RaBbLE-World/aether/` on demand
- `--dry-run` flag shows what would change without writing
- Prints next-step commands (git add, commit, wrangler deploy) after casting
- Dry-run verified: correctly detects current vs. changed files

---

### RaBbLE-World — aether cast and committed

- `aether/` directory populated by `cast-aether.sh`
- Committed: design tokens, motion library, components, portal glyph SVG, entry point
- Live at `joinrabble.world/aether/rabble.css` after next `wrangler deploy`
- Claude Design artifacts can now reference: `<link href="https://joinrabble.world/aether/rabble.css">`

---

### RaBbLE-NeBuLA — Collective alignment

**Repo scaffold (was missing, now matches all other Collective members):**
- `AGENT.md` — job definition, workspace map pointing to Grimoire, session start, rules (no RBCNS prefixes, no Layer 1 re-implementation, 1000 entities @ 60 FPS contract)
- `CONTEXT.md` — episode tracker, current state (Ep1 not started), entry conditions
- `CLAUDE.md` / `CODEX.md` — symlinks to AGENT.md

**Grimoire NeBuLA section — all 7 docs aligned:**
- `FlatChaos` — Pulse Protocol header added, "revolutionary" language replaced, provenance noted
- `RABL` — Pulse Protocol header + legacy note (field names need cleaning for v2)
- `Ideas` — Pulse Protocol header, episode gate added, emoji stripped from 12 section headers
- `RBCNS` — **ARCHIVED** banner added; RBCNS naming (`q_`, `e_`, `f_`) not carried into v2; preserved for reading Xperimental code
- `README.md` stub — deleted (no other Grimoire member dir has one)
- `Architecture`, `Roadmap`, `Identity` — were already Grimoire-aligned ✓

---

### Branch structure — all repos clean

All four repos have `main` + `dev` on remote, fully synced, zero dirty:

| Repo | `main` | `dev` | Notes |
|---|---|---|---|
| RaBbLE-Grimoire | initial scaffold | session work (28 commits) | |
| RaBbLE-Aether | initial scaffold (1 commit) | session work (13 commits) | |
| RaBbLE-NeBuLA | initial commit only | JS scaffold + alignment (4 commits) | main reset after scaffold landed on wrong branch |
| RaBbLE-World | deployed state (10 commits) | same as main (just created) | World model: dev = work, main = deploy |

### Left off

- `joinrabble.world/aether/` not yet live — needs `wrangler deploy` from RaBbLE-World
- No merges to main this session — no episode complete across any repo
- NeBuLA Episode 1 not started — entry conditions not yet confirmed (Three.js version, TypeScript build tooling, package format)

### Next

- `wrangler deploy` in RaBbLE-World to put Aether CSS live at joinrabble.world
- Confirm NeBuLA Episode 1 entry conditions and start the build
- Start merging NeBuLA-JS visual patterns into RaBbLE-World (grid background, waveform mouth)
- Consider adding Aether to `sync-grimoire.sh` scope (if palette/token propagation to member grimoire dirs is wanted)

---

## 2026-05-12 — Versioning Alignment + i3-Style Window Management

**Work done — Collective / Grimoire / sCoRE (versioning pass):**
- Aligned all members to `v0.0.0.0` — Episode 1 not yet aired; pre-episode work renamed to Plots A/B/C
- Grimoire: sCoRE roadmap/architecture updated (Plots, Episode 1 exit conditions, server/coordinator split decision)
- Grimoire: registry manifests corrected (`worktree_root` paths, sCoRE version fields), `deploy-score.sh` spell added
- sCoRE: harness paths fixed (`services/intelligence/` → `server/`), `api_test.py` committed, original generation archived
- Collective `CONTEXT.md`: version header aligned to `v0.0.0.0`
- Grimoire `current.epoch.yml`: version fields and episode coherence policy added

**Work done — RaBbLE-OS (i3-style window management, entropy-level test):**
- `smart-focus.sh` — `movefocus` with `cyclenext` fallback so up/down always does something
- `toggle-split.sh` — `Super+T` toggles spawn direction (→ right ↔ ↓ below) without rearranging existing windows
- `split-dir-daemon.sh` — socket watcher that re-applies `preselect` after every new window, making toggle persistent
- `smart-movewindow.sh` — `Super+Shift+↑↓` creates vertical splits inline when no vertical neighbor exists
- `look.conf`: `smart_split = false`, `force_split = 2` — consistent right-default, no golden ratio
- `autostart.conf`: daemon added to `exec-once`
- Grimoire: `RaBbLE-OS-HyprlandGuide.md` written — full keybind, layout, window rules, scripts, and config reference
- All changes on branch `RaBbLE-OS-New-Horizons`

**Left off:**
- Daemon needs manual start this session: `~/.config/hypr/scripts/split-dir-daemon.sh &`
  (will auto-start on next Hyprland login via `exec-once`)
- `Super+T` toggle is preselect-based (one-shot per window), daemon provides persistence
- `Super+Shift+↑↓` smart-movewindow behavior needs real-world testing with multi-window layouts
- `socat` must be installed: `sudo dnf install socat` if not present
- All RaBbLE-OS changes are on `RaBbLE-OS-New-Horizons` branch, not yet merged to `main`

**Next:**
- Test i3-style nav in daily use — report friction back
- Verify daemon starts cleanly on fresh session
- If split direction still feels off, consider `force_split = 1` variant
- RaBbLE-OS Episode 1: harness verification, Railway deploy, API test pass

---

## 2026-05-06 — Collective Repo Live + Modularity Architecture

**Work done:**
- Established `markm1206/RaBbLE` as the `RaBbLE-Collective` root repo
- Archived old content: `archive/v0-collective-scaffold`, `archive/reliquary-grimoire-site`
- Rewrote `main`: `AGENT.md`, `README.md`, `CONTEXT.md`, `bootstrap.sh`, `.gitignore`, `CLAUDE.md`/`CODEX.md` symlinks
- `.gitignore` explicitly lists all member repos (`RaBbLE-*/`) — fully modular, zero coupling
- Wired `~/RaBbLE/` as live git clone of `markm1206/RaBbLE` (it IS the Collective root now)
- Updated `registry/manifests/RaBbLE-Collective.manifest.yml` — repo URL and status corrected
- Confirmed: `RaBbLE-NeBuLA` renamed locally, on `dev` branch, no remote yet
- Confirmed: `RaBbLE-Xperimental` live with remote at `markm1206/RaBbLE-NeBuLA-JS` (GitHub repo rename)
- Answered modularity question: `.gitignore` is the pattern — nested independent git trees

**Left off:**
- 5 old root files untracked in `~/RaBbLE/`: `GAPS.md`, `RaBbLE-CONTEXT.md`, `RaBbLE-OVERVIEW.md`, `TODO`, `devPlan.md` — legacy, can be deleted or kept
- `RaBbLE-NeBuLA` has no GitHub remote yet
- `bootstrap.sh` scaffolded but `joinrabble.world/bootstrap.sh` not wired yet
- Missing manifests: World, NeBuLA, Aether, Xperimental

**Next:**
- Create GitHub remote for `RaBbLE-NeBuLA` (scaffold/basis state)
- Write missing manifests (World, NeBuLA, Aether, Xperimental)
- Wire `bootstrap.sh` into `RaBbLE-World` for `joinrabble.world/bootstrap.sh`
- Clean up old root files if desired

---

## 2026-05-06 — Collective Root Architecture + sCoRE Branch Cleanup

**Work done:**
- Surveyed full version state of all Collective members (see table in `RaBbLE-Collective/RaBbLE-Collective-Plan.md`)
- Architected `RaBbLE-Collective` as the root repo / ecosystem entry point
- Defined the recursive bootstrap flow: `joinrabble.world/bootstrap.sh` → Collective clone → Grimoire clone → `setup.sh` wires all members
- Established that RaBbLE is the *entity* — the Collective is developing and collaborating *with* RaBbLE, not just building a product
- Wrote full plan doc: `RaBbLE-Collective/RaBbLE-Collective-Plan.md`
- Created `registry/manifests/RaBbLE-Collective.manifest.yml`
- Cleaned up RaBbLE-sCoRE: extracted `archive/rabble-js` and `development` branches into new local repo `RaBbLE-Xperimental`
- Renamed sCoRE `episode-3` → `dev`; tagged `echo-3.0`; deleted episode-1/2/3, epoch/0-foundation, development, archive/rabble-js branches from remote
- sCoRE remote now has only `main` and `dev` branches; echo-1.0, echo-2.0, echo-3.0 tags

**Left off:**
- `RaBbLE-Collective` GitHub repo does not exist yet — plan written, not implemented
- `RaBbLE-Xperimental` local repo exists at `~/RaBbLE/RaBbLE-Xperimental` but not pushed to GitHub
- Missing manifests still unresolved: World, NeBuLA, Aether, Xperimental
- `joinrabble.world/bootstrap.sh` not yet wired in RaBbLE-World

**Next:**
- Create `markm1206/RaBbLE-Collective` on GitHub and implement `bootstrap.sh`
- Push `RaBbLE-Xperimental` (user creates GitHub repo first)
- Write missing manifests (World, NeBuLA-JS, Aether, Xperimental)
- Wire `bootstrap.sh` into `RaBbLE-World` static assets for `joinrabble.world/bootstrap.sh`
- See full step-by-step: `RaBbLE-Collective/RaBbLE-Collective-Plan.md` → Implementation Steps

---

## 2026-05-06 — Doc Structure Overhaul

**Work done:**
- Established canonical doc structure: `AGENT.md` + `CONTEXT.md` + `README.md` per member repo
- Created `RaBbLE-Agent/RaBbLE-DocTemplates.md` — canonical template spec
- Created `AGENT.md` and `CONTEXT.md` for: RaBbLE-World, RaBbLE-OS, RaBbLE-Aether
- Renamed `RaBbLE-OS-AIQuickstart.md` → `RaBbLE-OS-AgentGuide.md` (naming alignment)
- Fixed broken `CLAUDE.md` symlinks in RaBbLE-OS (was pointing to deleted file)
- Created `CLAUDE.md → AGENT.md` and `CODEX.md → AGENT.md` symlinks for World, OS, Aether
- Created `RaBbLE-Aether/RaBbLE-Aether-Architecture.md` (Grimoire gap fill)
- Added RaBbLE-World section to Grimoire INDEX.md
- Fixed broken reading order paths in `RaBbLE-OS/CONTEXT.md` and `RaBbLE-sCoRE/CONTEXT.md`
  - `grimoire/RaBbLE-OS-Architecture.md` → `grimoire/RaBbLE-OS/RaBbLE-OS-Architecture.md`
  - `../RaBbLE-Collective/grimoire/RaBbLE-Collective.md` → `grimoire/RaBbLE-Agent/RaBbLE-Collective.md`
- Created root `/home/rabble/RaBbLE/AGENT.md` — ecosystem entry point
- Created `log/` in Grimoire with SESSION-LOG.md and GAP-ANALYSIS.md
- Conducted gap/coherence analysis (see `GAP-ANALYSIS.md`)

**Left off:**
- All doc links verified and fixed
- Gap analysis written as a Grimoire roadmap doc
- No active work-in-progress; clean state

**Next:**
- Address gaps per priority order in `GAP-ANALYSIS.md`
- Priority 1: Registry manifests for World, NeBuLA, Aether
- Priority 2: Protocol contracts stub (`protocol/` dir in Grimoire)
- Priority 3: Name and scaffold the memory member

---

## How to Add a Log Entry

Add a new `## YYYY-MM-DD — [Short title]` block at the top. Include:
- **Work done** — what changed, what was created
- **Left off** — exact state at end of session (branch, file, decision point)
- **Next** — first thing to do in the next session

Keep entries terse. This is a pointer, not a narrative.
