# RaBbLE-OS Layer — Containers

> Ansible layer tag: `containers` (also responds to `layer`)
> layerctl: `bash RaBbLE-OS-layerctl.sh apply containers`
> Opt-in var: `rabble_enable_containers` (default `false` — see `ansible/roles/layer/containers/defaults/main.yml`)
> Role: `ansible/roles/layer/containers/`

Installs Docker CE and Podman side by side. Both are container runtimes with
different tradeoffs — Docker CE is a rootful daemon (`dockerd`), the safer
default for tooling/compose files written assuming real Docker; Podman is
rootless and daemonless, closer to RaBbLE-OS's local-first ethos. Neither
replaces the other here; pick per-project. `podman-docker` (the package that
aliases `/usr/bin/docker` to podman) is deliberately **not** installed —
it would fight the real `docker-ce-cli` binary this layer installs.

Second reference implementation of the `layer/*` optional-feature-group
pattern (see `RaBbLE-OS-Layer-Bottles.md` for the first). Neither `apply all`
nor `upgrade` installs this layer — only an explicit `apply containers`
(layerctl flips `rabble_enable_containers` automatically via its
`LAYER_EXTRA_VARS` map).

---

## What the layer installs

| Step | What | Why |
|---|---|---|
| `docker-ce-stable` repo | `yum_repository`, `download.docker.com/linux/fedora` | Docker CE isn't in Fedora's own repos |
| `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` | Docker CE + Compose v2 + Buildx | Full Docker CLI/daemon stack |
| `podman`, `podman-compose` | Podman + Compose compat | Rootless alternative |
| `docker` group | `rabble_user` appended | CLI access to the daemon without `sudo` — **requires a new login session to take effect** |
| `docker.socket` | enabled + started, `docker.service` left un-enabled | Socket-activated: the daemon only spins up on first connection, not an always-on boot service |

---

## Verify

```bash
bash RaBbLE-OS-layerctl.sh verify containers   # docker --version && podman --version
docker run --rm hello-world
podman run --rm hello-world
```

If `docker` commands fail with a permission error right after first `apply`,
log out and back in — the `docker` group membership hasn't taken effect in
your current session yet.

→ `RaBbLE-OS-Layer-Bottles.md` — the `layer/*` pattern this follows
→ `../../RaBbLE-OS/ansible/packages/manifest.yml` — package declarations (`layer.containers` category)
