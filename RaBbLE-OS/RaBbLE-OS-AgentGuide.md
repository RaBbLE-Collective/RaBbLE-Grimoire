# RaBbLE-OS-AgentGuide.md — Map

Ansible-driven Fedora 43 + Hyprland desktop. The entity's body.
Active branch: `RaBbLE-OS-New-Horizons`. Key tools: `layerctl.sh` · `dotctl.sh` · `vmctl.sh`.

> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [OS Roadmap](RaBbLE-OS-Roadmap.md) · [Integration Map](../RaBbLE-Agent/RaBbLE-Integration-Map.md)

---

## Directory Tree

```
layers/         Ansible layer docs — what each layer is and its current state
hardware/       Hardware profiles — ProArt P16, generic x64, adding targets
ops/            Operational tools — layerctl, dotctl, vmctl, bootstrap, config flow, install
fix/            Active bugs and open fix branches — known issues, nvidia, boot chain, suspend
verify/         Verification — session checklist, power testing, layer state table
desktop/        Deep desktop reference — Hyprland guide, shell guide, theming, boot flow detail
historical/     Stale docs — KDE-spin era installs, branch diffs, implementation plans
```

## Navigation

| I need to... | Read |
|---|---|
| Understand the layer model | `layers/RaBbLE-OS-Layers.md` |
| Know what's broken right now | `fix/RaBbLE-OS-KnownIssues.md` |
| See current Phase 1 blockers | `RaBbLE-OS-Roadmap.md` |
| Run layerctl / dotctl commands | `ops/RaBbLE-OS-Ops-Layerctl.md` or `ops/RaBbLE-OS-Ops-Dotctl.md` |
| Work on a specific layer | `layers/RaBbLE-OS-Layer-<name>.md` |
| Work on boot chain | `layers/RaBbLE-OS-Layer-Boot.md` → `fix/RaBbLE-OS-Fix-BootChain.md` |
| Work on NVIDIA / GPU | `fix/RaBbLE-OS-Fix-Nvidia.md` |
| Work on Hyprland config | `desktop/RaBbLE-OS-Desktop-Hyprland.md` |
| Work on theming | `desktop/RaBbLE-OS-Desktop-Theming.md` |
| Understand config flow | `ops/RaBbLE-OS-Ops-ConfigFlow.md` |
| Install on a machine | `ops/RaBbLE-OS-Ops-Install.md` |
| Test in a VM | `ops/RaBbLE-OS-Ops-Vmctl.md` |
| Verify a bootstrap | `verify/RaBbLE-OS-Verify-Checklist.md` |
| Check layer state | `verify/RaBbLE-OS-Verify-LayerState.md` |
| Add new hardware target | `hardware/RaBbLE-OS-Hardware-AddingTargets.md` |

## Rules

- Colors: `RaBbLE-Agent/RaBbLE-Palette.md` only — never invent hex values
- Config changes: `config/` → deploy via `dotctl`, never edit `~/.config/` directly
- System changes: Ansible only, never manual package installs
- Commits: Pulse Protocol — `[impulse] ~ [organ] >> [revelation] // %STATE%`
