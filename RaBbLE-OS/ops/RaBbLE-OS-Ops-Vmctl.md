# RaBbLE-OS-VM-Guide.md — VM Dev Workflow

> Use this guide to build and maintain a Fedora KVM development VM for testing RaBbLE-OS
> bootstraps without touching your daily driver.

---

## What You'll End Up With

- A QEMU/KVM VM running Fedora 44 (minimal + Ansible bootstrap)
- Automated Kickstart install via `cast-ks` — no manual Anaconda interaction
- SPICE display — renders in a virt-viewer window on your host desktop
- virgl 3D acceleration when conditions allow (auto-detected at cast time)
- A `clean-install` snapshot you can restore in seconds for clean bootstrap tests
- `RaBbLE-OS-vmctl.sh` — the CLI spell for all VM lifecycle operations

---

## Storage Decisions

### qcow2 (Default) vs Raw Partition

| | qcow2 | Raw Partition (`--raw-disk`) |
|---|---|---|
| **Storage** | `/var/lib/libvirt/images/rabble-os-dev.qcow2` | Direct block device (e.g. `/dev/nvme0n1p6`) |
| **Snapshots** | Full support via libvirt | Not supported by libvirt |
| **Size** | 20GB thin-provisioned (grows on demand) | Fixed — uses entire partition |
| **Performance** | Slightly slower (copy-on-write overhead) | Native disk speed |
| **Portability** | Easy to move/backup | Tied to hardware |
| **Use case** | Dev testing, snapshot-restore loops | Bare-metal-like performance testing |

**Decision (S36):** qcow2 is the default. Raw partition is available via `--raw-disk` flag but is not the primary workflow. Snapshots are essential for the test loop — restore-bootstrap-verify-repeat.

### Where the VM Lives

The VM has **two runtime components** — neither lives inside the RaBbLE-OS git repo.

| Component | Location | Managed by |
|---|---|---|
| VM definition (XML) | `/etc/libvirt/qemu/rabble-os-dev.xml` | libvirt (system daemon) |
| Disk image (qcow2) | `/var/lib/libvirt/images/rabble-os-dev.qcow2` | libvirt storage pool |

The RaBbLE-OS repo holds only:
- `RaBbLE-OS-vmctl.sh` — the spell
- `RaBbLE-OS.ks` — Kickstart file for automated installs
- `ISO/` — installation media (gitignored, not tracked)

If your user is in the `libvirt` group, most vmctl commands work without sudo. Only `setup`, `partition-setup`, and disk operations on system paths need root.

### Using an alternate disk location

```bash
RABBLE_VM_DISK_DIR=/mnt/vms ./RaBbLE-OS-vmctl.sh cast-ks ISO/...
```

Or set it permanently in your shell env. The partition just needs to be mounted and writable by root.

If you have a dedicated BTRFS partition labeled `RaBbLE-VM`, use `partition-setup` to format and mount it (see `hardware/RaBbLE-OS-Hardware-Partitions.md`).

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

## Part 2 — Get a Fedora Everything Netinstall ISO

Download the Fedora Everything netinstall ISO. Tested with Fedora 44.

**Download page:** https://fedoraproject.org/everything/download

Save it to `RaBbLE-OS/ISO/` (gitignored):

```bash
mv ~/Downloads/Fedora-Everything-netinst-x86_64-44-*.iso ~/RaBbLE/RaBbLE-OS/ISO/
```

**Why netinstall, not Sway spin?** The KS automation needs `--location` (to extract kernel/initrd and inject the KS file). The netinstall ISO is designed for this. The Sway spin is a live ISO — `cast` (interactive) still supports it, but `cast-ks` (automated) requires the netinstall.

**osinfo-db note:** `virt-install` uses an osinfo variant for CPU/driver hints. The `osinfo-db` package may lag behind by one release. `vmctl` auto-selects the highest available variant at runtime (currently falls back to `fedora43` for Fedora 44 ISOs).

---

## Part 3 — Prepare the Host

Run setup once per machine. It checks group membership, starts libvirtd, and brings up the default NAT network:

```bash
sudo ./RaBbLE-OS-vmctl.sh setup
```

---

## Part 4 — Create the VM

Two modes: **automated** (KS, recommended) or **interactive** (manual Anaconda).

### Automated (cast-ks) — Recommended

```bash
cd ~/RaBbLE/RaBbLE-OS
sudo ./RaBbLE-OS-vmctl.sh cast-ks ISO/Fedora-Everything-netinst-x86_64-44-*.iso
```

**What cast-ks does:**
1. Extracts kernel+initrd from the netinstall ISO via `--location`
2. Injects `RaBbLE-OS.ks` into the initrd via `--initrd-inject`
3. Boots the VM — Anaconda reads the KS and runs unattended
4. KS downloads ~510 packages from Fedora mirrors (~723 MB)
5. `%post` clones the canonical Collective structure:
   - `~/RaBbLE/` (Collective root)
   - `~/RaBbLE/RaBbLE-Grimoire/` (knowledge layer)
   - `~/RaBbLE/RaBbLE-OS/` (OS member — working branch)
6. Creates `rabble-os-setup.service` (firstboot) → runs Bootstrap with `base,boot`
7. VM reboots into the installed OS
8. Opens SPICE display for you to watch (reconnect with `connect` after reboot)

**After reboot:** reconnect to watch firstboot progress:
```bash
sudo ./RaBbLE-OS-vmctl.sh connect
# or serial: sudo virsh console rabble-os-dev
```

### Interactive (cast)

```bash
sudo ./RaBbLE-OS-vmctl.sh cast ISO/Fedora-Sway-Live-44-*.iso
```

Uses `--cdrom` — boots into the live environment for manual Anaconda install.

**SPICE keyboard grab:** virt-viewer captures keyboard input when focused. Press `Ctrl+Alt` to release the grab back to your host compositor.

### Common options

**Override VM specs via env vars:**
```bash
RABBLE_VM_RAM=8192 RABBLE_VM_VCPUS=6 sudo ./RaBbLE-OS-vmctl.sh cast-ks ISO/...
RABBLE_VM_DISK_DIR=/mnt/vms sudo ./RaBbLE-OS-vmctl.sh cast-ks ISO/...
```

**Raw partition (not recommended for dev):**
```bash
sudo ./RaBbLE-OS-vmctl.sh cast-ks --raw-disk /dev/nvme0n1p6 ISO/...
```

---

## Part 5 — Snapshot Clean State

After the firstboot service completes (SDDM appears or Bootstrap finishes):

```bash
sudo ./RaBbLE-OS-vmctl.sh snapshot post-firstboot
sudo ./RaBbLE-OS-vmctl.sh snapshots   # verify
```

For a pre-bootstrap snapshot (right after KS install, before firstboot runs):
```bash
# Must catch it before firstboot — or re-cast
sudo ./RaBbLE-OS-vmctl.sh snapshot clean-install
```

These are your **reset points** — restore before each test cycle.

---

## Part 6 — Run Further Bootstrap Layers

After `cast-ks`, the firstboot service runs `base,boot` tags automatically. For the full desktop:

```bash
sudo ./RaBbLE-OS-vmctl.sh connect
```

Inside the VM:
```bash
cd ~/RaBbLE/RaBbLE-OS
RABBLE_TAGS=desktop,apps ./RaBbLE-OS-Bootstrap.sh \
    --inventory ansible/inventory/vm.hosts.yml
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
./RaBbLE-OS-vmctl.sh                        # dashboard (status if VM exists, else help)
./RaBbLE-OS-vmctl.sh --quiet <cmd>          # suppress info/success output

# Setup
./RaBbLE-OS-vmctl.sh partition-setup <dev>  # format + mount BTRFS VM partition
./RaBbLE-OS-vmctl.sh setup                  # one-time host preparation

# Create & Destroy
./RaBbLE-OS-vmctl.sh cast <iso>             # interactive Anaconda install
./RaBbLE-OS-vmctl.sh cast-ks <iso>          # automated KS install (recommended)
./RaBbLE-OS-vmctl.sh cast-ks --raw-disk <dev> <iso>  # cast-ks with raw partition
./RaBbLE-OS-vmctl.sh recast <iso>           # destroy + cast-ks in one step
./RaBbLE-OS-vmctl.sh destroy                # delete VM + disk (prompts for name)

# Lifecycle
./RaBbLE-OS-vmctl.sh status                 # dashboard: state, IP, uptime, disk, SPICE
./RaBbLE-OS-vmctl.sh start                  # start VM
./RaBbLE-OS-vmctl.sh stop                   # graceful shutdown (60s timeout, then prompts)
./RaBbLE-OS-vmctl.sh stop --force           # immediate force-stop
./RaBbLE-OS-vmctl.sh stop --timeout 120     # custom timeout before force prompt
./RaBbLE-OS-vmctl.sh connect                # open SPICE display (auto-starts if stopped)
./RaBbLE-OS-vmctl.sh ssh                    # SSH into VM as root
./RaBbLE-OS-vmctl.sh ssh <cmd>              # run a command over SSH
./RaBbLE-OS-vmctl.sh logs                   # tail rabble-os-setup journal
./RaBbLE-OS-vmctl.sh logs <unit>            # tail any systemd unit

# Snapshots
./RaBbLE-OS-vmctl.sh snapshot <name>        # create named snapshot
./RaBbLE-OS-vmctl.sh restore  <name>        # revert to snapshot (prompts)
./RaBbLE-OS-vmctl.sh snapshots              # list all snapshots
```

**Tab completions:** `source spells/vmctl-completions.sh` in your `.bashrc` or `.zshrc`.

**Environment variable overrides:**

| Var | Default | Description |
|-----|---------|-------------|
| `RABBLE_VM_NAME` | `rabble-os-dev` | VM name in all virsh commands |
| `RABBLE_VM_RAM` | `4096` | RAM in MB |
| `RABBLE_VM_VCPUS` | `4` | vCPU count |
| `RABBLE_VM_DISK_SIZE` | `20` | Disk size in GB (qcow2 only) |
| `RABBLE_VM_DISK_DIR` | `/var/lib/libvirt/images` | Where the qcow2 lives |
| `RABBLE_VM_QUIET` | *(unset)* | Set to `1` to suppress info/success output |

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

→ `ops/RaBbLE-OS-Ops-Install.md` — install path decisions (KS delivery, package source, tier roadmap)
→ `ops/RaBbLE-OS-Ops-Bootstrap.md` — Bootstrap.sh internals
→ `hardware/RaBbLE-OS-Hardware-Partitions.md` — partition layout + VM partition setup
→ `hardware/RaBbLE-OS-Hardware-GenericX64.md` — VM hardware profile (generic_x64)
→ `verify/RaBbLE-OS-Verify-Checklist.md` — verification after VM bootstrap
