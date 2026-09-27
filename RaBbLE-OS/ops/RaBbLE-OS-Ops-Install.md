# RaBbLE-OS-Ops-Install.md — Install Path

## Current Path: KS + Ansible (Tier 1) `[WORKING — S37]`

Automated VM install via `vmctl cast-ks`. The KS file drives the entire flow.

### How It Works

1. `vmctl cast-ks` extracts kernel+initrd from the Fedora Everything netinstall ISO
2. `--initrd-inject` embeds `RaBbLE-OS.ks` directly into the initrd (no HTTP server needed)
3. Anaconda boots, reads `inst.ks=file:/RaBbLE-OS.ks` from the injected initrd
4. KS automates: locale, timezone, user (`rabble`), network, partitioning, package selection
5. `%post` clones canonical Collective structure (see below) + creates firstboot service
6. `reboot` directive restarts into installed OS
7. Firstboot service runs Bootstrap with `base,boot,desktop,gnome` tags (+
   `RABBLE_EXTRA_VARS=rabble_enable_gnome_desktop=true`) → SDDM greeter appears
   listing both a Hyprland and a GNOME session (GNOME promoted to a first-class
   firstboot DE 2026-09 — see `desktop/RaBbLE-OS-Desktop-Gnome.md`)

### Clone Strategy (S37)

The KS `%post` sets up the canonical Collective directory structure, but only clones what the OS needs:

```
~/RaBbLE-Collective/                  ← Collective root (cloned)
~/RaBbLE-Collective/RaBbLE-Grimoire/  ← knowledge layer (cloned)
~/RaBbLE-Collective/RaBbLE-OS/        ← OS member (cloned, specific branch)
```

Other members (World, NeBuLA, sCoRE, etc.) are NOT cloned — they aren't needed for the OS install and would waste time/bandwidth during firstboot. The user can run the full Collective bootstrap later to expand.

**Why not clone just RaBbLE-OS?** The Collective is the canonical entry point. Placing RaBbLE-OS inside `~/RaBbLE-Collective/` (not `~/RaBbLE-OS/`) means a later `bootstrap.sh` run won't conflict or create duplicates. The Grimoire is included because Bootstrap roles may reference palette or config docs.

### KS Delivery Decision (S37)

**Chosen: `--initrd-inject`** — injects the KS file into the boot initrd.

Rejected alternatives:
- **HTTP server on host** — `python3 -m http.server` on `192.168.122.1:8888`. Failed because Fedora's nftables blocks arbitrary ports from guest→host on the libvirt bridge by default. Fragile, adds a process to manage, firewall-dependent.
- **`inst.ks=file:///path`** with `--cdrom` — can't use `--extra-args` with `--cdrom`; `--extra-args` requires `--location`.
- **Embedding KS in ISO** — requires `lorax`/`mkisofs` tooling, overkill for dev workflow.

### KS Package Source Decision (S37)

The Fedora Everything netinstall ISO contains no packages — only the installer. The KS must specify where to download packages:

```
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64
```

**Key finding:** `$releasever` and `$basearch` variables are NOT expanded by Anaconda when booting via `--initrd-inject`. Hardcode the version and arch.

**Package group:** `@core` (not `@^minimal-environment` which doesn't exist in Fedora 44 comps).

### VM Command

```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
sudo ./RaBbLE-OS-vmctl.sh cast-ks ISO/Fedora-Everything-netinst-x86_64-44-1.7.iso
```

### Bare Metal Path (first exercised 2026-09, Ventoy USB — not yet a completed install)

No `--initrd-inject` equivalent exists for bare metal, and `vmctl`'s templating (password
hash, branch) doesn't run either — the KS must be hand-prepped. Two delivery options:

**Recommended: OEMDRV auto-detect (no boot-line editing).** Anaconda auto-mounts any
partition labeled exactly `OEMDRV` and, if it finds `/ks.cfg` there, uses it automatically
— equivalent to `inst.ks=hd:LABEL=OEMDRV:/ks.cfg` with zero GRUB editing. Works fine
alongside a Ventoy USB (Ventoy's own data partition just holds the ISO; a separate small
`OEMDRV`-labeled partition on the same stick holds `ks.cfg`). Convention: keep the file
named `ks.cfg.unused` when inactive and rename to `ks.cfg` only right before booting the
target machine — otherwise *any* Anaconda-based ISO later booted from that same stick
(e.g. a Fedora Live image) will silently pick it up too. Rename back to `.unused` after.

**Alternative: GRUB boot-line edit.** Host the KS somewhere reachable and append at the
Anaconda boot menu (press `e` to edit):
```
inst.ks=https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS.ks
```

**Hand-prep needed either way, before use:**
- Replace `__RABBLE_PASSWORD_HASH__` with a real hash (`openssl passwd -6`) — or drop
  `--password=... --iscrypted` from the `user` line entirely to make Anaconda prompt for
  it interactively on the User Creation spoke instead (username itself must stay `rabble`
  — hardcoded through `%post` and the firstboot systemd unit's `User=`/`WorkingDirectory=`/
  `ConditionPathExists=`; see `idea_gui_installer_custom_de` local-memory note for what
  it'd take to lift that).
- `__RABBLE_BRANCH__` placeholders need no edit — the `%post` fallback already resolves
  them to `new-horizons` when untouched by `vmctl`.
- Remove `clearpart`/`autopart` entirely (not just for VMs) to get the interactive
  Installation Destination spoke — disk + partitioning-scheme choice on-screen.
- **WiFi-only targets:** kickstart's `network` command has no WPA support (WEP only, long
  deprecated) — drop any `--device=... --activate` line. Anaconda falls back to its normal
  WiFi picker (SSID + WPA passphrase) on the Network & Host Name spoke; the connection it
  establishes persists through package install and into `%post`/firstboot. Keep
  `network --hostname=...` — that still applies independent of device activation.
- Locale/keyboard/timezone are fine left hardcoded for a personal install (adjust the
  `timezone` line for your region) — only worth making interactive for a genuinely
  general-purpose installer aimed at other users.

Net effect: 3 interactive screens (destination, user password, WiFi) on an otherwise
unattended run through to firstboot — same automation as the VM path from there on.

## Manual Path (no KS)

```bash
# On a cloned repo with Fedora base:
ansible-galaxy collection install -r ansible/requirements.yml
./RaBbLE-OS-layerctl.sh apply all
./RaBbLE-OS-dotctl.sh apply all
```

## First-Contact Script

`RaBbLE-OS-Install.sh` — installs git + ansible, clones repo, calls Bootstrap.
Run on a bare Fedora system:
```bash
curl -fsSL https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS-Install.sh | bash
```

## Tier Roadmap

| Tier | What | Status |
|------|------|--------|
| **Tier 1** | KS + netinstall + Ansible | Working (S37) — VM smoke test in progress |
| **Tier 2** | Custom live ISO | Future (Phase 6) — `lorax`/`livemedia-creator` |

→ `ops/RaBbLE-OS-Ops-Bootstrap.md` — Bootstrap.sh internals
→ `ops/RaBbLE-OS-Ops-Vmctl.md` — VM lifecycle and storage decisions
→ `RaBbLE-OS-Roadmap.md` — Phase status and episode map
