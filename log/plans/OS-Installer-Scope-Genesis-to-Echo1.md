# RaBbLE-OS install: Genesis `0.1.0` and the Echo 1 installer (scope)

```
spark ~ os/install >> genesis proves the two paths we have; echo 1 ships an installer // %S323_SCOPE%
```

> **Status:** scope only (S323, 2026-11-11). Ruled by Mark: at Genesis the bootstrap and Kickstart processes are **documented and tested**; the **first Echo targets an actual installer** that installs RaBbLE-OS without major headache. The compositor decision is deferred (`log/DECISIONS.md`, S323).
> **Builds on, does not replace:** the Ansible audit (`log/plans/Collective-Coherency-Audit-S318/audit-ansible.md`: 1 critical, 10 high, 15 medium), the repair order O1 to O5 (`Collective-Context-Diet-S322.md` section 8.1), `OS-Install-Editions-Plan.md`, `OS-VM-Dev-Flow.md`, and the runbook `RaBbLE-OS/verify/RaBbLE-OS-Verify-PreviewFloor.md`.

## 1. What exists today

| Piece | State |
|---|---|
| **Bootstrap path:** Fedora 44 Sway spin, then `RaBbLE-OS-Install.sh` (curl) to `RaBbLE-OS-Bootstrap.sh` to Ansible `site.yml` | runs on Mark's laptop; the curl URL fetches from `main`, which is 346 commits stale until Genesis lands |
| **Kickstart path:** Fedora netinst ISO + `RaBbLE-OS.ks`, firstboot runs Ansible | VM install S236, bare metal S238; not rerun since the S318 audit |
| **Custom ISO:** `spells/build-iso.sh`, last output `ISO/RaBbLE-OS-new-horizons.iso` (2026-09-27) | builds; it is the netinst with the Kickstart embedded, so it still needs network and has no questions |
| **VM tooling:** `RaBbLE-OS-vmctl.sh cast-ks` / `recast` | works |
| **Roles:** 11 roles, `manifest.yml` (1,848 lines) | only proven on the ProArt; audit findings open |

## 2. Genesis `0.1.0`: the two paths, documented and tested

OS is released at Genesis when all of G1 to G5 are true. Until then its `release/0.1.0` branch stays open; other members do not wait for it.

| # | Done when |
|---|---|
| G1 | **Static check** (O1): `ansible-playbook --syntax-check`, `ansible-lint`, and the manifest check run from one spell and pass |
| G2 | **Install-breaking findings fixed** (O2): C1 RPM Fusion, H3 root's HOME under `become`, H1 `uv` ordering, H5 llama.cpp, H4 `layerctl remove`; H2 finished by deriving the path from `rabble_repo_root` (O3) |
| G3 | **Kickstart path tested:** `vmctl recast` on a clean generic x86_64 VM reaches the desktop with no manual step. Follow the PreviewFloor runbook (F1, F2, F4); record the date, commit and result in it |
| G4 | **Bootstrap path tested:** a clean Fedora 44 Sway VM, the curl line from the README, reaches the same desktop. Recorded the same way |
| G5 | **Documented:** `RaBbLE-OS/ops/RaBbLE-OS-Ops-Install.md` and `-Bootstrap.md` match what G3 and G4 actually did; the OS `README.md` carries both install lines and the known limits (network required, single user, hardware it was tested on) |

Not in Genesis: editions, the medium findings, a new compositor, any installer UI.

## 3. Echo 1: an actual installer

**Outcome:** someone who is not Mark writes one ISO to a USB stick, boots it, answers a few questions, and lands on the RaBbLE-OS desktop. No Kickstart editing, no SSH keys, no terminal.

| Slice | What it is | Draws on |
|---|---|---|
| I1 | **Questions, not edits:** user name, password, hostname, disk, edition. Today the user is fixed in the Kickstart | idea: GUI installer with custom user names; `OS-Install-Editions-Plan.md` |
| I2 | **Hardware picked by detection:** the hardware group comes from DMI facts, not a hand-edited inventory; unknown hardware falls back to `generic_x64` | audit H7, H8; `group_vars/` |
| I3 | **Desktop as a variable:** one `rabble_desktop` value selects the compositor role, so the installer and the later compositor decision do not need a rewrite | `roles/desktop/*`, `roles/layer/gnome` |
| I4 | **Manifest is the source:** every package a role installs is in `manifest.yml` with its edition; the 51 task-installed strays are folded in | audit M1, M2, appendix |
| I5 | **Safe to rerun:** the playbook is idempotent; a failed install can be resumed; `layerctl` add and remove work | audit H4, M6 to M8 |
| I6 | **Trustworthy:** pinned and checksummed third-party downloads, no permanent passwordless root, no root `curl \| sh` by default | audit H9, H10, M3 to M5 |
| I7 | **One reproducible ISO:** `build-iso.sh` records the input ISO checksum and the OS version and commit; the ISO boots with RaBbLE branding | `spells/build-iso.sh`, Plymouth chain |
| I8 | **Test matrix, recorded:** generic UEFI VM, a VM with a second disk, the ProArt on metal. Echo 1 needs all three green | `vmctl`, PreviewFloor runbook |

## 4. Decisions for Mark (Echo 1, none block Genesis)

| # | Decision | Recommendation |
|---|---|---|
| D1 | Installer form | **Anaconda with a generated Kickstart**: keep Fedora's installer for disk and user questions, add the edition choice, run Ansible at firstboot. Lowest risk; reuses everything tested at Genesis. A custom installer UI is a later Echo |
| D2 | Network at install | Keep network required for Echo 1 (netinst base). An offline ISO with the packages on it is a later step; say so in the README |
| D3 | Editions at Echo 1 | Ship `core` and one fuller edition only; add the rest after |
| D4 | Compositor | Decide before I3 is built, since the installer exposes it. Deferred for now |

## 5. Order

G1, G2, G3, G4, G5 (Genesis for OS), then I3 and I4 (they unblock the rest), I1, I2, I5, I6, I7, I8.
