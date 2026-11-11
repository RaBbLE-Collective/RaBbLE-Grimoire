# RaBbLE-OS-Ops-Layerctl.md — layerctl Reference

`RaBbLE-OS-layerctl.sh` — primary tool for day-to-day layer management.

## Commands

```bash
./RaBbLE-OS-layerctl.sh status                       # show all layer states
./RaBbLE-OS-layerctl.sh apply all                    # full system deploy
./RaBbLE-OS-layerctl.sh apply <layer>                # one layer
./RaBbLE-OS-layerctl.sh apply <layer> --packages     # packages only
./RaBbLE-OS-layerctl.sh apply <layer> --config       # config only
./RaBbLE-OS-layerctl.sh apply <layer> --check        # dry-run
./RaBbLE-OS-layerctl.sh diff <layer>                 # show what would change
./RaBbLE-OS-layerctl.sh verify <layer>               # run health checks
./RaBbLE-OS-layerctl.sh remove <layer>               # teardown
./RaBbLE-OS-layerctl.sh dotfiles                     # re-link ~/.config entries
```

Layer names: `base` · `hardware` · `boot` · `desktop` · `apps` · `virtualization` · `monitoring` · `snapper`

## Tags (Ansible pass-through)

Tags compound with scope modifiers:
```bash
# packages only for hardware layer
ansible-playbook ... -K --tags "hardware,packages"
# config only for desktop
ansible-playbook ... -K --tags "desktop,config"
```

## Hardware Profile Override

```bash
RABBLE_HARDWARE=generic_x64 ./RaBbLE-OS-layerctl.sh apply hardware
```

## State Files

Layer state tracked in `~/.local/state/rabble/layer_<name>.state`.
Format: `<state>:<ISO8601-timestamp>`. States: `applied`, `verified`, `degraded`, `removed`, `unknown`.

→ `verify/RaBbLE-OS-Verify-LayerState.md` — current layer state per role
→ `ops/RaBbLE-OS-Ops-Dotctl.md` — dotfile deploy commands
