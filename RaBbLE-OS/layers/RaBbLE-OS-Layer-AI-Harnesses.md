# RaBbLE-OS Layer — AI Harnesses

> Ansible layer tag: `ai-harnesses`
> layerctl: `bash RaBbLE-OS-layerctl.sh apply ai-harnesses`
> Individual harnesses: `claude-code`, `free-claude-code`, `codex`, `opencode`, `aider`, `gemini-cli`, `ollama`, `vllm`, `builder-skills`

The AI Harnesses layer installs the coding agents and LLM CLI tools that sCoRE wraps for the RaBbLE desktop. These are the execution backends — the hands RaBbLE reaches through to take action.

---

## Current State (EP1, 2026-06)

All harnesses install to **user-level** (`~/.local/`) and run as the logged-in user. The Ansible play uses `become: false`.

| Harness | Install method | Binary | Service |
|---|---|---|---|
| claude-code | npm global → `~/.local` | `~/.local/bin/claude` | — |
| free-claude-code | uv + git clone → `~/.local/share/rabble/fcc` | via uv run | systemd user service `:8082` |
| codex | npm global → `~/.local` | `~/.local/bin/codex` | — |
| opencode | npm global → `~/.local` | `~/.local/bin/opencode` | — |
| aider | pipx → `~/.local` | `~/.local/bin/aider` | — |
| gemini-cli | npm global → `~/.local` | `~/.local/bin/gemini` | — |
| ollama | system package (rpm) | `/usr/bin/ollama` | systemd system service |
| vllm | uv venv → `~/.venv/vllm` | `~/.local/bin/vllm` (wrapper) | — (manual serve) |
| builder-skills | npx → `~/.claude/commands/` | slash commands | — |

**Python note:** `uv` manages its own Python runtimes under `~/.local/share/uv/python/` — fully isolated from system Python. free-claude-code requires Python 3.14.0 (uv downloads it on first install).

### Known EP1 fragility

- **npm globals disappear** on Node.js upgrades or npm prefix changes. Fixed for opencode with `state: latest`; the same fragility exists for claude-code, codex, gemini-cli. Running `layerctl apply <harness>` reinstalls.
- **User-service fcc** won't start until `loginctl enable-linger` is set or a user session is active.
- `ansible_env` is unavailable in this play (local connection, become: false) — all home-path references use `lookup('env', 'HOME')`.

---

## Post-EP1 Migration Plan — System-Wide Hardening

**Motivation:** RaBbLE-OS is an Agentic-OS. AI tooling is not user software — it is system infrastructure. Agents spawned by sCoRE as system services, daemons, or future multi-user contexts need these binaries in PATH unconditionally. User-level installs are first casualty of a Node upgrade and invisible to system services.

### Target architecture

| Category | Current | Target |
|---|---|---|
| npm CLIs (claude-code, opencode, codex, gemini-cli) | `~/.local/bin` via npm prefix | `/usr/local/bin` via npm, `become: true` |
| Python CLIs (aider) | `~/.local/bin` via pipx | `/usr/local/bin` via pipx system install |
| free-claude-code | systemd **user** service | systemd **system** service, runs as dedicated `rabble-fcc` user |
| vllm | user venv | system venv at `/opt/rabble/vllm` |
| ollama | already system service | no change |

### Migration scope

1. **Split the Ansible play** — `become: true` for package installs, `become: false` only for user-config (`.claude/`, `.config/rabble/`) that genuinely lives in HOME.
2. **npm CLIs → system prefix**
   - Set `NPM_CONFIG_PREFIX=/usr/local` in the install tasks (with `become: true`)
   - Remove `ai_harnesses_node_prefix` default or repurpose it
   - Verify no conflict with dnf-managed node packages (keep Node itself from dnf, globals from npm)
3. **aider → system pipx**
   - `pipx install --global aider-chat` (pipx ≥ 1.4 supports `--global`)
4. **free-claude-code → system service**
   - Create `rabble-fcc` system user (no login shell, no HOME)
   - Clone repo to `/opt/rabble/free-claude-code`
   - Run uv as that user; service `User=rabble-fcc`
   - `fcc.env` → `/etc/rabble/fcc.env` (root-owned, 0640, group `rabble-fcc`)
   - `fcc-ctl` spell updated to use `systemctl` (not `systemctl --user`)
5. **vllm → /opt**
   - Venv at `/opt/rabble/vllm/`
   - Wrapper at `/usr/local/bin/vllm`
6. **Update layerctl verify commands** — verify against `/usr/local/bin` not `~/.local/bin`
7. **Update sCoRE provider subprocess paths** if hardcoded

### Session cold-start checklist

```
cat RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md   # this doc
cat RaBbLE-OS/RaBbLE-OS-Roadmap.md                     # EP1 gate status
# Files to touch:
# ansible/roles/ai-harnesses/tasks/main.yml            # become split
# ansible/roles/ai-harnesses/tasks/{each harness}.yml  # path + become updates
# ansible/roles/ai-harnesses/defaults/main.yml         # node_prefix removal
# ansible/site.yml                                      # split play become
# config/rabble/fcc.env.example                        # path update comment
# RaBbLE-Grimoire/spells/fcc-ctl.sh                    # systemctl --user → systemctl
# RaBbLE-OS-layerctl.sh                                # verify commands
```

### Defer until

- EP1 has aired (this is post-EP1 hardening, not a gate)
- sCoRE's subprocess dispatch is stable enough to verify harness paths against
- Cyberdeck / aarch64 target is considered (system paths must work on Pi too)

---

## Quick Reference

```bash
# Apply all harnesses
bash RaBbLE-OS-layerctl.sh apply ai-harnesses

# Apply / repair a single harness
bash RaBbLE-OS-layerctl.sh apply free-claude-code
bash RaBbLE-OS-layerctl.sh apply opencode   # reinstalls if missing

# Health check
bash RaBbLE-OS-layerctl.sh verify free-claude-code

# fcc management
fcc-ctl status
fcc-ctl key NVIDIA_NIM_API_KEY <value>   # nvidia_nim provider (upstream var; sCoRE uses NVIDIA_API_KEY)
fcc-ctl model sonnet nvidia_nim:qwen/qwen2.5-coder-32b-instruct
fcc-ctl logs
```
