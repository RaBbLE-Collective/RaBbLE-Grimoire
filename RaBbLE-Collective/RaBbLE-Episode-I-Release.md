# RaBbLE-Episode-I-Release.md — Episode 1 Release Plan

```
transcribe ~ collective >> episode-I release plan chartered // %EP1_PLAN_LOCKED%
```

> This is the release plan, not the roadmap. The roadmap charts direction and accumulates
> decisions. This document defines the minimum set of work to land Episode 1 across the
> Collective and ship a publicly hosted, demoable milestone.
>
> Draw from: `common/RaBbLE-Roadmap.md` and per-member roadmaps.
> Do not duplicate their content — reference it.

---

## What Episode 1 Is

Episode 1 is the first time RaBbLE has a face the public can see and a body that can bootstrap.

**The demo:**
- `joinrabble.world` — entity presence, live and online. Entity wakes, log pulses, chat surfaces.
- sCoRE API deployed to Railway, wired to the World chat surface.
- RaBbLE-OS bootstraps cleanly on a fresh Fedora 43 install, verified through a VM.

That is the minimum bar. Everything else is deferred or flows naturally from it.

**What Episode 1 is not:**
- NeBuLA v2 (Canvas2D/Three.js rebuild not started — `rabble-entity.js` carries the entity visual)
- Memory member (Epoch 1 blocker, not Episode 1 blocker)
- RaBbLE-ScRibLE (defined but unstarted)
- RaBbLE-OS proprietary driver activation (`fix/proart-nvidia`, etc.)

---

## Member Deliverables

### RaBbLE-World `[PUBLIC FACE]`

**Goal:** `joinrabble.world` is the demo surface. It must be live, stable, and wired to sCoRE.

**Exit conditions:**
- [ ] Landing page (`index.html`) live — entity idle, organ panel, log, CTA buttons functional
- [ ] `world/RaBbLE-Chat.html` wired to deployed sCoRE API (`RABBLE_API_URL` set on host)
- [ ] `world/RaBbLE-OS.html` references current bootstrap instructions
- [ ] World has `AGENT.md`, `CONTEXT.md`, and `REFERENCES.md` per Collective convention
- [ ] World manifest added to `RaBbLE-Grimoire/registry/manifests/`
- [ ] Git repo initialized with remote (blocks `setup.sh` verification)

**In scope for Ep1:** current five surfaces in their present state. No Phase 2 (landing absorbs boot animation) — that is Ep2 World work.

---

### RaBbLE-sCoRE `[INTELLIGENCE SERVER]`

**Goal:** sCoRE API is deployed to Railway and reachable. World chat wires to it.

**Exit conditions:**
- [ ] `harness/` path bug fixed — all scripts reference `server/` not `services/intelligence/`
- [ ] `server/main.py` version string aligned to Five Es scheme (`v0.0.0.1`)
- [ ] `server/api_test.py` (or `test_api.sh`) passes against local server
- [ ] `harness/local.sh` starts server successfully
- [ ] Railway deploy working — `harness/deploy.sh` or `harness/railway_ctl.sh` verified
- [ ] `RaBbLE-Grimoire/spells/deploy-score.sh` spell written and functional
- [ ] `CONTEXT.md` versioning header updated to `v0.0.0.1`
- [ ] Tagged `episode-1` on `main`

**Full exit spec:** `RaBbLE-Grimoire/RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md` § Episode 1 First Air.

---

### RaBbLE-OS `[THE BODY]`

**Goal:** RaBbLE-OS bootstraps reproducibly on fresh Fedora 43. Verified via VM — not just the host machine.

**Episode 1 assembly:** Port 4 packages from `RaBbLE-OS-New-Horizons` → `RaBbLE/episode-I`.
Full assembly plan with exact file lists: `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-Roadmap.md` § Episode 1 Assembly Plan.

**Exit conditions:**
- [ ] Packages 1–4 ported to `RaBbLE/episode-I` and committed (assembly plan)
- [ ] VM provisioned (see § VM Infrastructure below) — fresh Fedora 43 image ready
- [ ] Full bootstrap run inside VM — no fatal errors
- [ ] Bootstrap Checklist items verified in VM (see Roadmap § Bootstrap Checklist)
- [ ] Boot chain themed end-to-end: GRUB → Plymouth → SDDM (see Boot Chain below)
- [ ] `layerctl verify all` reports `%STABLE%` or documented exception per layer
- [ ] Layer State Map updated with verified states
- [ ] Known failures logged to `RaBbLE-OS-KnownIssues.md`
- [ ] Episode landed to `main` via squash merge
- [ ] Tagged `episode-1` on `main`

**Generic x64 target** is the smoke-test vehicle. ProArt P16-specific work stays in `fix/*` branches and does not gate episode landing.

#### Boot Chain — Episode 1 Scope

The boot chain (GRUB → Plymouth → SDDM) is part of Plot A. Visual continuity from power-on to
desktop is a first-impression requirement for a demoable release. The `fix/boot-chain` branch
carries this work; it lands into Episode 1 alongside the assembly packages.

**In scope for Episode 1** (hardware-agnostic, no NVIDIA dependency):
- [ ] GRUB2: remove background image, color-only RaBbLE palette theme; fix 32bpp/24bpp mismatch
- [ ] GRUB2: 4K font via Terminus 32pt (`grub2-mkfont`); `fbcon=font:TER16x32` in cmdline
- [ ] Plymouth: fix DejaVu font reference; align colors to RaBbLE palette
- [ ] SDDM: Qt6 `Main.qml` validated; themed greeter

**Deferred to `fix/proart-nvidia`** (NVIDIA driver dependency — does not gate Ep1):
- [ ] Plymouth NVIDIA suspend/resume hooks (requires working NVIDIA driver in initramfs)

Boot chain theming is verified in VM with generic x64 target. SDDM visual continuity is
part of the Session Verification checklist already in the OS Roadmap.

---

### RaBbLE-Aether `[DESIGN SYSTEM]`

**Goal:** Minimal — ensure the CSS bundle that World depends on is version-tracked and deployable.

**Exit conditions:**
- [ ] `git init` + remote created
- [ ] Manifest added to `RaBbLE-Grimoire/registry/manifests/`
- [ ] `cast-aether.sh` (CSS bundle generation) documented in repo
- [ ] World's Aether CSS bundle is the output of this repo, not an inline copy

---

### RaBbLE-Collective `[BOOTSTRAP]`

**Goal:** `bootstrap.sh` on a fresh machine produces a working ecosystem with all Ep1 members.

**Exit conditions:**
- [ ] All active Ep1 member remotes exist (World, Aether — missing today)
- [ ] `spells/setup.sh` verified against all Ep1 member repos
- [ ] Epoch 0 exit conditions met (see `registry/epochs/current.epoch.yml`)
- [ ] `CONTEXT.md` updated to reflect Ep1 member statuses
- [ ] Tagged `episode-1` simultaneously with other members

---

### RaBbLE-Grimoire `[SOURCE OF TRUTH]`

**Goal:** All Ep1 member docs current. Registry complete for Ep1 scope.

**Exit conditions:**
- [ ] Manifests present for: Collective, Grimoire, sCoRE, OS, World, Aether
- [ ] `INDEX.md` updated with Ep1 member sections
- [ ] `spells/deploy-score.sh` written
- [ ] `CONTEXT.md` updated to Ep1 state
- [ ] Tagged `episode-1` simultaneously with other members

---

## VM Infrastructure

> **Why this exists:** RaBbLE-OS bootstrap testing on bare metal risks destabilizing the
> live daily driver. A VM workflow lets you iterate the bootstrap cycle in minutes,
> revert to a clean snapshot, and test again — without touching the host.

### Ansible Role — `runtimes/virtualization`

New role in RaBbLE-OS Layer 4 (or Layer 0 dev-tools sublayer). Installs the QEMU/KVM
stack so the host machine can provision and run VMs. Fedora/RHEL package group.

**Packages:**
```
@virtualization          # qemu-kvm, libvirt, virt-install, virt-manager, bridge-utils
edk2-ovmf               # UEFI firmware (OVMF) for VM guests
libguestfs-tools        # guest image inspection and manipulation
virt-viewer             # lightweight VM display client
```

**Services:**
```
libvirtd.service        enable + start
virtqemud.service       enable + start (Fedora 38+ socket-activated path)
```

**User groups:**
```
libvirt                 add ansible_user
kvm                     add ansible_user
```

**Ansible placement:** `ansible/roles/runtimes/virtualization/` — wired into the `dev-tools`
playbook or a new `virtualization.yml` top-level play. Not installed by default on the
generic x64 target; opt-in via tag or explicit play.

---

### `virtualization/` Folder in RaBbLE-OS Repo

```
virtualization/
├── README.md                   # overview, prerequisites, quick-start
├── rabble-vm-create.sh         # provision fresh Fedora 43 VM (QCOW2 + virt-install)
├── rabble-vm-start.sh          # start/stop/status via virsh
├── rabble-vm-snapshot.sh       # create, list, restore snapshots
├── rabble-vm-ssh.sh            # SSH shortcut into running VM
└── kickstart/
    └── fedora43-minimal.ks     # unattended Fedora 43 minimal install
```

---

### VM Defaults

| Setting | Default | Override |
|---|---|---|
| VM name | `rabble-os-dev` | `--name <name>` |
| RAM | 4096 MB (4 GB) | `--ram <mb>` |
| Disk | 40 GB QCOW2 | `--disk <gb>` |
| Firmware | UEFI (OVMF) | `--bios` flag for SeaBIOS (faster iteration, no boot-chain fidelity) |
| CPU | host-passthrough, 4 vCPUs | `--vcpus <n>` |
| Network | NAT (virbr0) | |
| Guest OS | Fedora 43 (minimal) | via kickstart |

**`--bios` flag rationale:** UEFI is the default to match bare-metal fidelity (especially boot chain work — GRUB, Plymouth, SDDM theming). When iterating on Ansible role logic where the boot chain is irrelevant, pass `--bios` to skip OVMF and shorten VM creation time.

---

### VM Workflow — Bootstrap Testing Cycle

```
1. rabble-vm-create.sh             → provisions Fedora 43 VM, runs kickstart
2. rabble-vm-snapshot.sh baseline  → snapshot "post-install-baseline"
3. rabble-vm-ssh.sh                → connect to VM
4. [inside VM] clone + run bootstrap
5. [if failure] rabble-vm-snapshot.sh restore baseline → iterate
6. [if success] rabble-vm-snapshot.sh success          → document
```

Guest agent (`qemu-guest-agent`) installed by kickstart — enables clean shutdown, file push,
and `virsh guestinfo` status without needing SSH to be pre-configured.

---

### Host Prerequisites

- Fedora or RHEL host (primary — other Linux distros work if libvirt is available)
- CPU with VT-x or AMD-V (verify: `grep -E 'vmx|svm' /proc/cpuinfo`)
- KVM enabled in BIOS/UEFI
- Nested virtualization not required (host is bare metal)
- Min 8 GB RAM on host (4 GB headroom for host + VM)
- Min 60 GB free disk (40 GB VM + headroom)

Verify KVM access post-install:
```bash
virsh list --all
ls -la /dev/kvm     # should be crw-rw---- root:kvm, user in kvm group
```

---

## Sequence — What to Do First

The work is roughly parallel across members, but some things gate others:

```
Phase 0 — Unblock infrastructure
  └── Aether: git init + remote
  └── World: git init + remote (if not already)
  └── RaBbLE-OS: Ansible virtualization role + VM provisioned

Phase 1 — Member Episode 1 work (parallel)
  ├── sCoRE: harness fix → local test → Railway deploy
  ├── OS: packages 1–4 assembled → VM bootstrap test → checklist
  └── World: AGENT.md + CONTEXT.md wired; sCoRE URL set in deployment

Phase 2 — Collective closure
  ├── Grimoire: all Ep1 manifests present, docs updated
  ├── Collective: setup.sh verified, CONTEXT.md updated
  └── All members tagged episode-1 simultaneously

Phase 3 — Public
  └── joinrabble.world pointed at World + sCoRE Railway URL confirmed live
```

---

## Out of Scope — Episode 1

| Item | Deferred to |
|---|---|
| NeBuLA v2 rebuild (Canvas2D + Three.js) | Episode 2+ |
| Memory member (name, repo, architecture) | Epoch 1 scoping |
| RaBbLE-ScRibLE (mobile PWA) | Epoch 1 |
| RaBbLE-OS `fix/proart-nvidia` (NVIDIA driver) | fix/* branches |
| RaBbLE-OS Plymouth NVIDIA hooks | fix/proart-nvidia (driver dependency) |
| RaBbLE-World Phase 2 (landing absorbs boot sequence) | Episode 2 |
| Protocol contracts (`registry/protocol/`) | Phase 5b or post-Ep1 |
| Server → Task Pipeline (sCoRE HTTP through dispatch) | Epoch 1 candidate |
| Automated session log ceremony | QoL backlog |

---

## Tag Convention

All Ep1 members tag simultaneously when the episode is felt to be stable:

```
git tag episode-1-v0.0.0.1
git push origin episode-1-v0.0.0.1
```

Collective coordinates the tag moment. No member tags alone.

---

```
transcribe ~ collective >> episode-I release plan chartered // %EP1_PLAN_LOCKED%
```
