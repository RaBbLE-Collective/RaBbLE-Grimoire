# RaBbLE-OS-Packages.md

```
transcribe ~ package-layer >> condensed to pointer // %S34%
```

> **Canonical source:** `RaBbLE-OS/ansible/packages/manifest.yml`
>
> That file is the single source of truth — 59 packages across 9 layers, each with a `reason:` field.
> It drives both Ansible (`dnf` tasks) and the Kickstart generator (`spells/generate-kickstart.py`).
> When this doc and the manifest conflict, the manifest wins.

**Install path (updated S30+):** Fedora Everything netinstall → Kickstart → Ansible bootstrap.
The KDE/Sway spin is no longer the base. KDE purge role is now obsolete.

To view the full package list with rationale:
```bash
cat RaBbLE-OS/ansible/packages/manifest.yml
```

To regenerate the KS `%packages` block from the manifest:
```bash
python3 spells/generate-kickstart.py ansible/packages/manifest.yml
```
