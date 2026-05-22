# RaBbLE-OS-VM-Guide.md — VM Dev Workflow

```
spark ~ substrate >> VM dev workflow: QEMU/KVM + vmctl + bootstrap path // %VM_WORKFLOW%
```

> Use this guide to build and maintain a Fedora KVM development VM for testing RaBbLE-OS
> bootstraps without touching your daily driver. A clean snapshot becomes your reset point —
> run the bootstrap, verify, revert, repeat.

---

## What You'll End Up With

- A QEMU/KVM VM running Fedora (Sway spin) — tested with 43 and 44
- SPICE display — renders in a virt-viewer window on your host desktop
- virgl 3D acceleration when conditions allow (auto-detected at cast time)
- A `clean-install` snapshot you can restore in seconds for clean bootstrap tests
- `RaBbLE-OS-vmctl.sh` — the CLI spell for all VM lifecycle operations

---

## Where the VM Lives

The VM has **two runtime components** — neither lives inside the RaBbLE-OS git repo.

| Component | Location | Managed by |
|---|---|---|
| VM definition (XML) | `/etc/libvirt/qemu/rabble-os-dev.xml` | libvirt (system daemon) |
| Disk image (qcow2) | `/var/lib/libvirt/images/rabble-os-dev.qcow2` | libvirt storage pool |

The RaBbLE-OS repo holds only:
- `RaBbLE-OS-vmctl.sh` — the spell
- `ISO/` — installation media (gitignored, not tracked)

This is why most vmctl commands need sudo — those paths are owned by root/libvirt.

### Using an alternate disk location

If you have a dedicated partition for VM work (e.g. an old RaBbLE-OS install partition), point vmctl at it:

```bash
RABBLE_VM_DISK_DIR=/mnt/old-rabble-partition ./RaBbLE-OS-vmctl.sh cast ISO/...
```

Or set it permanently in your shell env. The partition just needs to be mounted and writable by root.

### ISO storage convention

Keep ISOs in `RaBbLE-OS/ISO/` — that directory is gitignored. vmctl sets the necessary ACLs on cast so the qemu user can read ISOs in place from your home directory; you don't need to copy them to `/var/lib/libvirt/images/`.

---

## Agent Handoff Checklist

If another agent is picking this up: read these first.

- [ ] Read `RaBbLE-OS-AgentGuide.md` — VM dev workflow section
- [ ] Read this guide from top to bottom before touching anything
- [ ] Check `RaBbLE-OS/CONTEXT.md` for current track status on VM workflow
- [ ] Run `./RaBbLE-OS-vmctl.sh status` to see if a VM already exists
- [ ] Run `./RaBbLE-OS-vmctl.sh snapshots` to see if a clean snapshot exists
- [ ] Do NOT re-cast the VM if one already exists — restore the snapshot instead

---

## Prerequisites

| Requirement | Check |
|---|---|
| KVM hardware support | `lsmod \| grep kvm` — should show `kvm_amd` or `kvm_intel` |
| Ansible installed | `ansible --version` |
| Virtualization role applied | `virsh --version` — if missing, run Part 1 |

---

## Part 1 — Install the KVM Host Stack

Apply the `virtualization` Ansible role. This installs QEMU/KVM, libvirt, virt-manager, and adds your user to the `libvirt` and `kvm` groups.

```bash
cd ~/RaBbLE/RaBbLE-OS
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags virtualization
```

After it completes, add yourself to the groups if not already done:

```bash
sudo usermod -aG libvirt,kvm $USER
```

**Group membership only takes effect in a new login session.** Open a new terminal rather than using `newgrp` — on Fedora 43+ with yescrypt password hashing, `newgrp` has a known crypt bug and will fail.

Verify:
```bash
groups | grep libvirt     # should show libvirt
virsh --version           # should print a version
ls /dev/kvm               # should exist
```

---

## Part 2 — Get a Fedora Sway Spin ISO

Download the Fedora Sway spin. The VM has been tested with Fedora 43 and 44.

**Download page:** https://spins.fedoraproject.org/sway/

Save it to `RaBbLE-OS/ISO/` (gitignored):

```bash
mv ~/Downloads/Fedora-Sway-Live-*.iso ~/RaBbLE/RaBbLE-OS/ISO/
```

**osinfo-db note:** `virt-install` uses an osinfo variant for CPU/driver hints. The `osinfo-db` package in the Fedora repo may lag behind by one release — e.g. on a Fedora 43 host, `fedora44` may not be in the db yet. `vmctl cast` auto-selects the highest available variant at runtime, so this is handled transparently.

---

## Part 3 — Prepare the Host

Run setup once per machine. It checks group membership, starts libvirtd, and brings up the default NAT network:

```bash
sudo ./RaBbLE-OS-vmctl.sh setup
```

---

## Part 4 — Create the VM

```bash
cd ~/RaBbLE/RaBbLE-OS
sudo ./RaBbLE-OS-vmctl.sh cast ISO/Fedora-Sway-Live-44-*.iso
```

**What cast does automatically:**
- Detects virgl 3D capability — enables `spice,gl=on` + `accel3d=yes` if a display session and DRI render node are available; falls back to software rendering (llvmpipe) otherwise
- Sets ACLs so the qemu user can read the ISO from `ISO/` without moving it
- Selects the highest available `fedoraNNN` osinfo variant
- Cleans up any previous failed cast before starting
- Opens the SPICE display window automatically when the VM is ready

**Override VM specs via env vars:**
```bash
RABBLE_VM_RAM=8192 RABBLE_VM_VCPUS=6 sudo ./RaBbLE-OS-vmctl.sh cast ISO/...
RABBLE_VM_DISK_DIR=/mnt/old-rabble-partition sudo ./RaBbLE-OS-vmctl.sh cast ISO/...
```

---

## Part 5 — Install Fedora Inside the VM

The Fedora Sway live environment boots into the SPICE window. Open the Anaconda installer.

**SPICE keyboard grab:** virt-viewer captures keyboard input when focused. Press `Ctrl+Alt` to release the grab back to your host compositor.

**Installer settings:**

| Setting | Value |
|---|---|
| Installation destination | The 40 GB virtio disk (`vda`) |
| Partitioning | Automatic (Btrfs recommended — Snapper works with it) |
| Root account | Disable root login; create your user with sudo |
| Hostname | `rabble-os-dev` |
| Software selection | Sway spin defaults |

Takes ~10–20 minutes. When complete: **shut down the VM from inside the guest** (`poweroff`). Do not just close the virt-viewer window.

---

## Part 6 — Snapshot Clean State

After the installer finishes and the VM has shut down cleanly:

```bash
sudo ./RaBbLE-OS-vmctl.sh snapshot clean-install
sudo ./RaBbLE-OS-vmctl.sh snapshots   # verify
```

This is your **reset point** — restore to this before every bootstrap test.

---

## Part 7 — Run the RaBbLE-OS Bootstrap

Each bootstrap test starts from a restore:

```bash
sudo ./RaBbLE-OS-vmctl.sh restore clean-install
sudo ./RaBbLE-OS-vmctl.sh start
./RaBbLE-OS-vmctl.sh connect
```

Inside the VM:

```bash
# Option A — curl install
curl -fsSL https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS-Install.sh | bash

# Option B — if repo already cloned in VM
bash ~/RaBbLE-OS/RaBbLE-OS-Install.sh
```

---

## Part 8 — Verify the Bootstrap

After bootstrap completes and the VM reboots:

```bash
./RaBbLE-OS-layerctl.sh status
ls -la ~/.config/hypr/
echo $WAYLAND_DISPLAY       # wayland-1 or similar
hyprctl version
```

Visual checklist:
- [ ] SDDM greeter on boot
- [ ] Hyprland session starts
- [ ] Waybar renders
- [ ] `Super+Space` → Fuzzel opens
- [ ] Terminal opens with RaBbLE palette
- [ ] `notify-send "test" "body"` → Mako fires

---

## The Test Loop

```bash
# 1. Edit Ansible roles / configs on the host

# 2. Reset
sudo ./RaBbLE-OS-vmctl.sh restore clean-install

# 3. Boot and connect
sudo ./RaBbLE-OS-vmctl.sh start
./RaBbLE-OS-vmctl.sh connect

# 4. Inside VM — pull and bootstrap
cd ~/RaBbLE-OS && git pull && bash RaBbLE-OS-Bootstrap.sh

# 5. Verify
./RaBbLE-OS-layerctl.sh verify all

# 6. If good — commit on host; repeat
```

---

## vmctl Reference

```bash
./RaBbLE-OS-vmctl.sh setup             # one-time host preparation
./RaBbLE-OS-vmctl.sh cast <iso>        # create VM from ISO (auto-cleans failed casts)
./RaBbLE-OS-vmctl.sh status            # show VM state + snapshot count
./RaBbLE-OS-vmctl.sh start             # start VM
./RaBbLE-OS-vmctl.sh stop              # graceful shutdown
./RaBbLE-OS-vmctl.sh connect           # open SPICE display
./RaBbLE-OS-vmctl.sh snapshot <name>   # create named snapshot
./RaBbLE-OS-vmctl.sh restore  <name>   # revert to snapshot (prompts)
./RaBbLE-OS-vmctl.sh snapshots         # list all snapshots
./RaBbLE-OS-vmctl.sh destroy           # delete VM + disk (prompts for name)
./RaBbLE-OS-vmctl.sh help              # show usage
```

**Environment variable overrides:**

| Var | Default | Description |
|-----|---------|-------------|
| `RABBLE_VM_NAME` | `rabble-os-dev` | VM name in all virsh commands |
| `RABBLE_VM_RAM` | `4096` | RAM in MB |
| `RABBLE_VM_VCPUS` | `4` | vCPU count |
| `RABBLE_VM_DISK_SIZE` | `40` | Disk size in GB |
| `RABBLE_VM_DISK_DIR` | `/var/lib/libvirt/images` | Where the qcow2 lives |

All vmctl commands target `qemu:///system` (set via `LIBVIRT_DEFAULT_URI`) — VMs are always visible regardless of whether you run with or without sudo.

---

## Troubleshooting

### `newgrp libvirt` fails with "invalid character in attribute value" or crypt error

Known Fedora 43+ bug — yescrypt password hashing breaks `newgrp`. Open a new terminal instead. Group membership from `usermod -aG` is active in any new login shell.

### virsh can't see the VM when run without sudo

All vmctl commands export `LIBVIRT_DEFAULT_URI=qemu:///system`, so this should not happen within vmctl. If running raw `virsh` commands, add `--connect qemu:///system` explicitly.

### SPICE window doesn't appear after cast

Cast runs as sudo and launches virt-viewer as your real user (via `sudo -u $SUDO_USER`) with your Wayland session forwarded. If it doesn't appear, connect manually — always without sudo:

```bash
./RaBbLE-OS-vmctl.sh connect
```

### virgl 3D not available / Hyprland won't start

`cast` auto-detects virgl. If it fell back to software rendering (llvmpipe), Sway works fine but Hyprland may not. Inside the VM:

```bash
glxinfo | grep "OpenGL renderer"   # "virgl" = hardware path, "llvmpipe" = software
WLR_NO_HARDWARE_CURSORS=1 Hyprland # workaround for cursor issues in software mode
```

### SPICE window is blank / black

VM may still be booting. Wait ~30 seconds. If it stays black:
```bash
sudo virsh console rabble-os-dev   # drop to serial console (Ctrl+] to exit)
```

### Share the host repo into the VM (virtiofs)

```bash
sudo dnf install -y virtiofsd
virt-xml rabble-os-dev --add-device \
  --filesystem "driver.type=virtiofs,source.dir=$HOME/RaBbLE/RaBbLE-OS,target.dir=rabble-os-host"

# Inside VM
sudo mount -t virtiofs rabble-os-host /mnt/rabble-os-host
```

---

## Future — GPU Passthrough `[WISHLIST]`

> Not needed for bootstrap testing. Relevant when testing NVIDIA-specific playbooks
> (`fix/proart-nvidia`) or GPU-accelerated inference (Episode 3+).

Full GPU passthrough (VFIO/IOMMU) lets the VM exclusively own a GPU.

**Host requirements:**
- CPU with AMD-Vi or Intel VT-d — verify: `dmesg | grep -i iommu`
- IOMMU enabled in BIOS
- Two GPUs: one for host, one to pass through

**Basic IOMMU check:**
```bash
for g in /sys/kernel/iommu_groups/*/devices/*; do
  n=$(basename $(dirname $g)); printf 'IOMMU group %s: ' "$n"; lspci -nns "${g##*/}"; done
```

**ProArt P16 note:** AMD iGPU stays with the host display; RTX 4060 is the passthrough candidate. Requires `fix/proart-nvidia` stable first.

**Roadmap:** GPU passthrough is a `fix/proart-nvidia` follow-on, Episode 3.

---

```
spark ~ substrate >> VM dev workflow documented // %VM_WORKFLOW%
```

→ `ops/RaBbLE-OS-Ops-Install.md` — full install path (KS + Ansible)
→ `ops/RaBbLE-OS-Ops-Bootstrap.md` — Bootstrap.sh internals
→ `hardware/RaBbLE-OS-Hardware-GenericX64.md` — VM hardware profile (generic_x64)
→ `verify/RaBbLE-OS-Verify-Checklist.md` — verification after VM bootstrap
