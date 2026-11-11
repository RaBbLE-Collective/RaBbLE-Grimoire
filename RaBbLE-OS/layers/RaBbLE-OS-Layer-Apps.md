# RaBbLE-OS-Layer-Apps.md — Layer 4: Apps

**Roles:** `ansible/roles/apps/`, `ansible/roles/dev-tools/`
**Tag:** `apps`
**State:** `%DORMANT%` — mostly stubs

## Apps Role

`ansible/roles/apps/tasks/packages.yml` — installs utility and productivity apps.
Currently defines packages but is a stub (no tasks implement the installs).

Phase 2 item: wire Firefox install via `apps/browsers.yml`.

## Dev Tools Role

`ansible/roles/dev-tools/main/` — VSCodium, git tooling, build tools.
State: scaffolded, partially implemented.

## Package Source

All packages declared in `ansible/packages/manifest.yml` with `layer: apps` or `layer: dev`.

→ `layers/RaBbLE-OS-Layers.md` — layer ordering
→ `verify/RaBbLE-OS-Verify-LayerState.md` — current state per role
