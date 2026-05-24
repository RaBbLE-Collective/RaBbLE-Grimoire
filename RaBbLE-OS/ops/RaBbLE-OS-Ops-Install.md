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
7. Firstboot service runs Bootstrap with `base,boot` tags → SDDM greeter appears

### Clone Strategy (S37)

The KS `%post` sets up the canonical Collective directory structure, but only clones what the OS needs:

```
~/RaBbLE/                  ← Collective root (cloned)
~/RaBbLE/RaBbLE-Grimoire/  ← knowledge layer (cloned)
~/RaBbLE/RaBbLE-OS/        ← OS member (cloned, specific branch)
```

Other members (World, NeBuLA, sCoRE, etc.) are NOT cloned — they aren't needed for the OS install and would waste time/bandwidth during firstboot. The user can run the full Collective bootstrap later to expand.

**Why not clone just RaBbLE-OS?** The Collective is the canonical entry point. Placing RaBbLE-OS inside `~/RaBbLE/` (not `~/RaBbLE-OS/`) means a later `bootstrap.sh` run won't conflict or create duplicates. The Grimoire is included because Bootstrap roles may reference palette or config docs.

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
cd ~/RaBbLE/RaBbLE-OS
sudo ./RaBbLE-OS-vmctl.sh cast-ks ISO/Fedora-Everything-netinst-x86_64-44-1.7.iso
```

### Bare Metal Path (future)

For bare metal, append the KS URL at GRUB boot:
```
inst.ks=https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS.ks
```

Before bare metal use: replace the plaintext password in the KS with a hash (`openssl passwd -6`), and remove `clearpart`/`autopart` lines to allow interactive partitioning.

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
