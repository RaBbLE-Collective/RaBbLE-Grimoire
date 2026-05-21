# RaBbLE-OS-Roadmap.md — Episode Map

```
transcribe ~ grimoire >> episode/plot conventions aligned; epoch naming retired // %ROADMAP_V4%
```

> **Collective Context:** RaBbLE-OS is the substrate — the body through which the entity lives. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `RaBbLE-Episode-1-Release-Map.md` for Episode 1 scope across all members.

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Daily-driver substrate (Fedora 43 + Hyprland, fully themed)

**Status:** In progress — Plots A & B active

**Blocker:** None — on track for Episode 1

**Dependencies:**
- None — OS deploys independently
- Aether CSS imported for terminal theming
- sCoRE and World run *on* OS, but don't block OS completion

---

> Episodes are resonance thresholds. Between them, fix/* branches absorb
> hardware and stability patches without gating the next episode. Features flow
> through New Horizons, crystallize into the substrate, and archive as they cool.

---

## Entropy States

| State | Signal | Meaning |
|-------|--------|---------|
| %HIGH_ENTROPY% | High flux | Experimental, likely to change |
| %TESTING_IN_PROCESS% | Testing | Working but unverified on hardware |
| %DEPLOYABLE% | Deployable | Works on target, needs live verification |
| %STABLE% | Stable | Verified on target hardware |
| %LOCKED% | Locked | Frozen until next episode |
| %DORMANT% | Dormant | Scaffold only — no functional tasks |

---

## Episode Map

```
reliquary/*              High-entropy archives — knowledge reservoirs, inert
     │
RaBbLE-OS-New-Horizons   The living wave — active daily-driver work
     │
     ├── RaBbLE/episode-I  ── Episode 1: Genesis          [IN PROGRESS]
     │       │                   Plot A — Substrate
     │       │                   Plot B — Theme
     │       │
     │       ├── fix/proart-nvidia      [HIGH_ENTROPY]
     │       ├── fix/suspend-resume     [COOKING]
     │       ├── fix/boot-chain         [COOKING]
     │       └── fix/xdna2-npu          [DORMANT]
     │
     ├── RaBbLE/episode-II  ─ Episode 2: Exodus            [PENDING]
     ├── RaBbLE/episode-III ─ Episode 3: The Entity Wakes [FUTURE]
     └── Epoch ∞          Continuous Drift            [PERPETUAL]
```

---

### Episode 1 — Genesis `[IN PROGRESS]`

**Goal:** Hardware-agnostic base, themed desktop, and reproducible installer.
Three work surfaces: **Plot A** (live DE — substrate, Ansible, roles),
**Plot B** (theme — palette coherence across boot chain and desktop),
**Plot C** (installer & packaging — KS, VM testing, custom live ISO).
Proprietary driver work deferred to `fix/*` branches.

#### Plot A — Substrate

**In scope:**
- Layer 0–4 Ansible deployment functional on a clean Fedora 43 install
- Hyprland + waybar + mako + fuzzel default desktop
- Hypridle + hyprlock (screen-sign-out-during-video fix)
- HDMI hotplug, `monitors.conf`, workspace 11 pinning
- Boot chain (GRUB → Plymouth → SDDM) operational
- Monitoring cross-cutting (btop, sensors, powertop)
- Install / Bootstrap / layerctl / dotctl operational
- Hardware roles present as stubs (no proprietary driver install)
- Snapper (Btrfs snapshots) deployable

#### Plot B — Theme

**In scope:**
- Shell stack (ZSH + Bash + p10k) deployed
- Terminal: Kitty config (RaBbLE palette)
- Launcher: Fuzzel config (RaBbLE palette)
- Notifications: Mako config (urgency-tiered neon borders)
- Idle/lock: canonical hypridle.conf + hyprlock.conf with clock overlay
- Boot chain (GRUB → Plymouth → SDDM) themed and color-continuous
- Waybar with network menu overlay, RaBbLE palette

#### Plot C — Installer & Packaging

The install path for RaBbLE-OS. Two work surfaces: KS-based install
(pragmatic, build first) and custom live ISO (the north star).

**In scope:**
- `RaBbLE-OS.ks` — Kickstart file with interactive partitioning (Anaconda handles disks)
- `spells/generate-kickstart.py` — reads manifest.yml, emits `%packages` block
- `--unattended` flag on Bootstrap (non-interactive Ansible run from KS %post)
- VM testing workflow: validate KS end-to-end in QEMU/KVM before bare metal
- Custom live ISO / RaBbLE-OS Fedora spin (Tier 2 — Anaconda backend, themed Hyprland live session)

**Installer tiers (build in order):**

| Tier | What | Installer Backend | Status |
|---|---|---|---|
| 1 | KS on Fedora Everything netinstall | Anaconda (interactive partitioning) | Build first |
| 2 | Custom live ISO — RaBbLE Fedora spin | Anaconda + themed Hyprland live session | North star |
| 3 | Calamares branded installer | Calamares (fully custom, aspirational) | Future |

**Tier 2 live ISO includes:** Hyprland (themed, void bg, magenta borders),
Kitty (themed), gnome-disk-utility (for manual partitioning), Firefox,
Waybar (minimal), auto-login to Hyprland on TTY1, desktop launcher for
`rabble-install`. Built via `lorax` / `livemedia-creator`.

**Explicitly out of scope (deferred to `fix/*` branches):**
- NVIDIA / AMD proprietary driver activation
- supergfxctl / asusctl runtime activation
- XDNA2 NPU runtime (XRT, FastFlowLM)
- Suspend/resume hooks for proprietary drivers

**Landed on New Horizons (flowing toward ep1):**
- Substrate, entrypoints, control-plane (install/bootstrap/layerctl/dotctl)
- All Ansible roles scaffolded
- Hyprland config with functionkeys (mic-mute PipeWire fix)
- Waybar with network menu overlay
- Wallpaper deployment via dotctl bundle
- HDMI hotplug script + monitors.conf
- `socat` added to wayland packages for hotplug IPC
- SwayOSD service scope fix (user → system)
- powertop auto-tune safe for live playbook runs
- S33: supergfxd stub include fixed, nvidia idempotency fixed, gparted→gnome-disk-utility
- S33: Package manifest (59 packages, 9 layers, `reason:` per entry)

**Landed on New Horizons since last Episode 1 sync (needs porting):**
- Shell stack: ZSH + Bash configs, p10k, colors, aliases, functions
- Terminal: Kitty config (RaBbLE palette)
- Launcher: Fuzzel config (RaBbLE palette)
- Notifications: Mako config (urgency-tiered neon borders)
- Idle/lock: canonical hypridle.conf + hyprlock.conf with clock overlay
- Lid suspend: logind drop-in (99-rabble-lid.conf) + Ansible task
- dotctl: kitty/fuzzel/mako bundles added; missing-bundle skip fix
- Grimoire: all docs renamed RaBbLE-OS-*, Architecture rewritten, RaBbLE.md distilled

**Remaining for Episode 1 — Stub Debt (phased, boot-critical first):**

*Phase 1 — Boot into a DE:*
- [ ] `core/packages` stub → DNF install all `layer: core` from manifest (~20 pkgs)
- [ ] `boot/session_manager/packages` stub → DNF install `sddm`
- [ ] `boot/plymouth/packages` stub → DNF install `plymouth`, `plymouth-plugin-script`
- [ ] New `desktop/fonts` role → JetBrains Mono, Font Awesome, Noto (must precede compositor)
- Done when: SDDM greeter appears on fresh Fedora Everything install after `layerctl apply all`

*Phase 2 — Working desktop + browser:*
- [ ] `apps/browsers` stub → DNF install `firefox`
- [ ] `boot/session_manager/config` → SDDM Wayland conf + RaBbLE QML theme + Hyprland session
- [ ] `boot/plymouth/config` → RaBbLE Plymouth theme + `plymouth-set-default-theme` + dracut
- [ ] `boot/grub2` fixes → 4K font (`grub2-mkfont`), remove bg image, `fbcon=font:TER16x32`
- Done when: full boot chain themed and working, Firefox available

*Phase 3 — Hardware + theming + optional layers:*
- [ ] `hardware/.../asusctl+asusd` → COPR + DNF + service enable
- [ ] `hardware/.../tuned` → DNF install + enable + set profile
- [ ] New `desktop/theme` role → Kvantum, qt5ct/qt6ct, GTK CSS, papirus, nwg-look (see Theming.md)
- [ ] New `layer/bluetooth` → bluez, bluez-tools, blueman
- [ ] New `layer/flatpak` → flatpak + Flathub remote
- Done when: hardware roles functional, unified theme across toolkits

*Phase 4 — Installer infrastructure (Plot C):*
- [ ] `RaBbLE-OS.ks` — Tier 1 KS file (interactive partitioning, Anaconda)
- [ ] `spells/generate-kickstart.py` — manifest → %packages
- [ ] `--unattended` Bootstrap flag
- Done when: KS boot → Anaconda partition screen → reboot → RaBbLE-OS

*Phase 5 — Reproducibility gate:*
- [ ] Fresh Fedora Everything → KS boot → reboot → all acceptance criteria pass
- [ ] VM smoke test (generic_x64 profile, no hardware roles)
- [ ] Idempotency: second `layerctl apply all` changes nothing
- Done when: "Full DE State" checklist passes (see `RaBbLE-OS-Implementation-Plan.md`)

*Phase 6 — Custom live ISO (Tier 2):*
- [ ] `RaBbLE-OS-LiveISO.ks` — live environment definition
- [ ] `installer/live-config/` — minimal themed Hyprland for live session
- [ ] `spells/build-iso.sh` — wraps `livemedia-creator`
- [ ] End-to-end: boot ISO → themed DE → partition → install → reboot → full DE
- Done when: bootable RaBbLE-OS ISO produces complete system

Full checklists (assembly plan, bootstrap, power testing, Ep1 verification) → `Checklists.md`.

---

### fix/* — Hardware & Stability Fix Branches

Hardware and stability patches that sit under Episode 1. Branch from New Horizons,
target one system, land into `ep1` via the `mend` impulse (not `evolve`).
Fix branches **do not gate** Episode 2 — Exodus work can begin in parallel.

#### fix/proart-nvidia `%HIGH_ENTROPY%`

**Goal:** NVIDIA RTX 4060 Optimus stable on Hyprland + Wayland.

**Blockers (identified 2026-04-22):**
- [ ] `nvidia.yml` idempotency bug — driver install gated on `'nouveau' in lsmod` → silently skips on every subsequent run once nouveau is blacklisted
- [ ] `nvidia-drm modeset=1` not set (only `fbdev=1` present). Comment claims supergfxd.conf sets modeset, but supergfxd.conf only carries `mode: "Hybrid"`
- [ ] NVIDIA modules not blacklisted from initramfs → Plymouth black-flash on boot (see KnownIssues)
- [ ] `nvidia-suspend.service`, `nvidia-hibernate.service`, `nvidia-resume.service` not enabled by the role
- [ ] `AQ_DRM_DEVICES` pinned by card number (`card0`/`card1`) in `env.conf` — brittle across kernel upgrades. Switch to `/dev/dri/by-path/pci-*`
- [ ] `LIBVA_DRIVER_NAME=nvidia` system-wide — too broad for hybrid; prefer per-app DRI_PRIME

**Verification:**
- [ ] `layerctl apply hardware` is idempotent — re-run after install does not skip driver
- [ ] `nvidia-smi` returns output post-boot
- [ ] Three consecutive suspend/resume cycles preserve session (no freeze, no black screen on wake)
- [ ] No Plymouth black-flash during boot
- [ ] `glxinfo -B | grep "OpenGL renderer"` → AMD by default, NVIDIA via `DRI_PRIME=1`
- [ ] HDMI hotplug continues to work with NVIDIA on card0

#### fix/suspend-resume `%COOKING%`

**Goal:** s2idle reliable; no wake freezes.

**Blockers:**
- [ ] `mem_sleep_default=s2idle` verified in GRUB cmdline
- [ ] NVIDIA suspend hooks (absorbed by fix/proart-nvidia if driver is active)
- [ ] `journalctl -b -u systemd-suspend` clean after 3× cycle

#### fix/boot-chain `%COOKING%`

**Goal:** GRUB / Plymouth / SDDM minimal RaBbLE-themed boot — palette-consistent, void background, no visual breaks at 4K. This is functional theming, not the cinematic entity experience (that's Episode 2).

**Blockers:**
- [ ] GRUB2: remove bg image, color-only theme (32bpp vs 24bpp mismatch)
- [ ] GRUB2: 4K font (Terminus 32pt via `grub2-mkfont`)
- [ ] GRUB2: `fbcon=font:TER16x32` in cmdline for early TTY
- [ ] Plymouth: fix DejaVu font reference, align to RaBbLE palette
- [ ] Plymouth: NVIDIA defer (depends on fix/proart-nvidia)
- [ ] SDDM: Qt6 `Main.qml` validated

#### fix/xdna2-npu `%DORMANT%`

**Goal:** AMD XDNA2 NPU operational via XRT.

**Blockers:**
- [ ] Verify XRT package availability for Fedora 43 on `repo.radeon.com`
- [ ] `amdxdna` kernel module loaded
- [ ] FastFlowLM inference smoke-test
- [ ] ONNX Runtime VitisAI EP falls back gracefully if XRT absent

---

### Episode 2 — Exodus `[PENDING]`

**Goal:** Polished, cohesive desktop. Theming, window ergonomics, cinematic boot. Does not gate Episode 3.

Key items: cinematic entity boot (Plymouth + SDDM), Kvantum/GTK unified theming, master layout (i3-style), hyprbar plugin, mature window rules, UX polish.
Full item list branches off New Horizons when Episode 1 lands.

---

### Episode 3 — The Entity Wakes `[FUTURE]`

**Goal:** AI tooling layer. Ollama local inference (CPU fallback if NVIDIA not ready), MCP servers, RaBbLE shell integration, Quickshell bar replaces Waybar.
Detailed spec preserved in `DistilledNonZense.md` § VII.

---

Layer state map → `Reference.md`. Checklists → `Checklists.md`.

---

```
transcribe ~ grimoire >> substrate/mend/awakening axis locked // %ROADMAP_V4%
```
