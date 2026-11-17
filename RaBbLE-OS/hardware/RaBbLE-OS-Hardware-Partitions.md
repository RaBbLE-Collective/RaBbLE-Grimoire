# RaBbLE-OS Partition Layout — Reference

**System:** ASUS ProArt P16 · Fedora 43 · Hyprland · NVMe SSD  
**Updated:** 2026-05-20

---

## Partition Scheme

```
Device          Size    Filesystem  Label        Mount Point     Purpose
──────────────────────────────────────────────────────────────────────────
nvme0n1p1       1GB     FAT32       (EFI)        /boot/efi       UEFI boot partition
nvme0n1p5       2GB     ext4        (boot)       /boot           Kernel + initramfs
nvme0n1p6      32GB     BTRFS       RaBbLE-VM    /mnt/vms        VM images & storage
nvme0n1p7     198.6GB   BTRFS       RaBbLE       /               Daily driver root
```

---

## Rationale

### Boot Partitions (3GB total)

- **`nvme0n1p1` (EFI, 1GB):** UEFI firmware partition. Standard 1GB is safe buffer.
- **`nvme0n1p5` (boot, 2GB ext4):** Separate /boot on ext4 (not BTRFS) for:
  - GRUB2 compatibility (more reliable than BTRFS /boot)
  - Atomic boot environment (no subvol complications)
  - Easy maintenance of multiple kernels + initramfs images

### VM Storage (32GB, BTRFS)

- **`nvme0n1p6`:** Dedicated BTRFS partition for VM workloads.
- **Format:** `mkfs.btrfs -L RaBbLE-VM /dev/nvme0n1p6`
- **Mount:** `/mnt/vms` with subvolumes:
  ```
  @vms              # Active VM disk images
  @vm-snapshots     # Point-in-time snapshots of VMs
  @vm-backups       # Offline archival backups
  ```
- **Mount options:**
  ```
  /dev/nvme0n1p6  /mnt/vms  btrfs  defaults,compress=zstd,subvol=@vms  0 0
  ```
- **Rationale:**
  - Isolated I/O: VM thrashing won't block desktop responsiveness
  - Copy-on-write snapshots: instant VM backups
  - Compression (zstd): ~30-50% space savings on disk images
  - Quota control: VMs cannot fill system partition
  - Label `RaBbLE-VM` for vmctl auto-detection

### Daily Driver Root (198.6GB, BTRFS)

- **`nvme0n1p7`:** Main system partition.
- **Subvolumes:**
  ```
  @                 # Root filesystem
  @home             # User home directories
  @snapshots        # System snapshots (via Snapper)
  ```
- **Features:**
  - Snapper integration for rollback capability
  - Atomic updates via Btrfs transactions
  - Compression enabled (reduces on-disk footprint)

---

## Installation Order

1. **UEFI/EFI partition** — Created by Fedora installer or manually with GParted
2. **Boot partition** — 2GB ext4, mounted at `/boot` during install
3. **Root partition** — Main BTRFS install target
4. **VM partition** — Formatted after OS install; mount via `/etc/fstab`

---

## Why This Layout?

| Aspect | Benefit |
|--------|---------|
| **Separate boot** | GRUB2 stability, atomic kernels, no BTRFS /boot quirks |
| **Separate VM partition** | I/O isolation, independent snapshots, quota control |
| **BTRFS for root + VMs** | Snapshots, compression, subvolumes, COW efficiency |
| **32GB VMs + 198GB system** | Balanced for daily driver + moderate VM workload |

---

## Management Commands

```bash
# Mount VM partition manually
sudo mount -L RaBbLE-VM /mnt/vms

# Create VM subvolume
sudo btrfs subvolume create /mnt/vms/@vms

# Snapshot active VM
sudo btrfs subvolume snapshot /mnt/vms/@vms/myvm.qcow2 /mnt/vms/@vm-snapshots/myvm-2026-05-20.qcow2

# Check compression ratio
sudo btrfs filesystem usage /mnt/vms

# Monitor BTRFS health
sudo btrfs filesystem show
```

---

## Adaptation for Other Systems

This layout is flexible:
- **Less RAM/more VM work?** Increase nvme0n1p6 (VM partition)
- **More daily work/less VM?** Decrease nvme0n1p6, increase nvme0n1p7
- **Fast NVMe setup?** Enable `nobarrier` mount option for marginal performance gain (risky on power failure)
- **Slow HDD?** Disable compression (`compress=none`), increase boot timeout

---

## Setup Workflow

Use `RaBbLE-OS-vmctl.sh partition-setup` to format and mount VM partitions:

```bash
./RaBbLE-OS-vmctl.sh partition-setup /dev/nvme0n1p6
```

This command:
1. Shows current partition state (lsblk)
2. Displays final confirmation
3. Triple-checks safeguards (device name + `yes` confirmation)
4. Formats as BTRFS with label `RaBbLE-VM`
5. Mounts at `/mnt/vms`
6. Adds to `/etc/fstab` for persistent mounting

---

→ `fix/RaBbLE-OS-KnownIssues.md` — GParted segfault on Hyprland (resolved), active issues
→ `ops/RaBbLE-OS-Ops-Vmctl.md` — VM lifecycle: cast, start, snapshot, restore
→ `ops/RaBbLE-OS-Ops-Bootstrap.md` — Bootstrap.sh internals
→ `ops/RaBbLE-OS-Ops-Install.md` — full install path and disk layout choices
