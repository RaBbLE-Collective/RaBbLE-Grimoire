# RaBbLE-OS-Layers.md — Layer Model

## Numbered Layers

Ordered and dependent — each layer must be present before the next.
Layers 0–2 run on headless machines. Layer 3+ require a desktop session.

| Layer | Tag | Role path | What |
|-------|-----|-----------|------|
| 0 | `base` | `roles/core/` | Packages, repos, locale, timezone |
| 1 | `hardware` | `roles/hardware/x64/<machine>/` | Drivers, power, platform quirks |
| 2 | `boot` | `roles/boot/{grub2,plymouth,session_manager}/` | GRUB → Plymouth → SDDM |
| 3 | `desktop` | `roles/desktop/*` | Hyprland, Waybar, shell, terminal, fonts |
| 4 | `apps` | `roles/apps/` | Browsers, dev tools, IDE |

---

## Cross-Cutting Plays

Independent of layer order. Safe to run on any machine at any time.
Skip individually with `--skip-tags <tag>`.

| Tag | Role path | What | `become` |
|-----|-----------|------|---------|
| `runtime` | `roles/runtime/` | GPU/NPU userspace runtimes; llama.cpp CUDA source build | true |
| `monitoring` | `roles/monitoring/` | btop, htop, nvtop, powertop, lm_sensors | true |
| `snapper` | `roles/snapper/` | Btrfs snapshot management | true |
| `virtualization` | `roles/virtualization/` | QEMU/KVM host stack for OS dev VMs | true |
| `collective` | `roles/apps/rabble-collective/` | Node.js, wrangler, age, gh — Collective dev tooling | true |
| `ai-harnesses` | `roles/ai-harnesses/` | AI coding agents + local inference stack (see below) | false |
| `dotfiles` | multiple roles (dotfiles task only) | Symlink `~/.config` entries from `config/` | false |

---

## AI Harnesses — Layer Detail

`--tags ai-harnesses` installs the sCoRE local AI layer. All run as user (`become: false`).
Each sub-component is independently taggable.

| Tag | What | Default |
|-----|------|---------|
| `claude-code` | Claude Code CLI (`@anthropic-ai/claude-code` via npm) | enabled |
| `codex` | OpenAI Codex CLI (`@openai/codex` via npm) | enabled |
| `opencode` | opencode TUI AI coding assistant (`opencode-ai` via npm) | enabled |
| `aider` | aider AI pair programming (`aider-chat` via pipx) | enabled |
| `gemini-cli` | Google Gemini CLI (`@google/gemini-cli` via npm) | enabled |
| `ollama` | Ollama local LLM runtime (installs + pulls models) | enabled |
| `free-claude-code` | Local Anthropic API proxy — routes CC to free providers | enabled |
| `builder-skills` | BuilderIO/skills slash commands for Claude Code | enabled |
| `vllm` | vLLM high-throughput inference server (heavy — several GB) | **disabled** |

Toggle via `group_vars` or `host_vars`:
```yaml
ai_harnesses_vllm_enabled: true          # opt-in for multi-session inference
ai_harnesses_fcc_enabled: false          # disable proxy on machines with paid CC auth
```

---

## Runtime Layer Detail

`--tags runtime` runs cross-cutting compute substrate tasks.

| Tag | What | Condition |
|-----|------|-----------|
| `xrt` | XRT + XDNA2 userspace for AMD NPU | `npu.enabled: true` |
| `llama-cpp` | llama.cpp source build with CUDA (RTX 4060/Ada, `cmake -DGGML_CUDA=ON`) | `llama_cpp.enabled: true` (default) |

Override llama.cpp version or CUDA arch in `group_vars`:
```yaml
llama_cpp:
  version: "b4600"              # pin a release tag
  cuda_architectures: "native"  # auto-detect, or "89" for RTX 4060, "86" for RTX 30xx
```

---

## Run Commands

```bash
# Full deploy
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K

# Specific layer
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags desktop

# Cross-cutting
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags runtime
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml    --tags ai-harnesses

# Single harness
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml    --tags free-claude-code
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags llama-cpp

# Packages only (no config)
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags "desktop,packages"
```

---

## Layer Docs

- `RaBbLE-OS-Layer-Core.md` — Layer 0 detail + Phase 1 stub work
- `RaBbLE-OS-Layer-Hardware.md` — Layer 1 hardware targeting
- `RaBbLE-OS-Layer-Boot.md` — Layer 2 GRUB/Plymouth/SDDM
- `RaBbLE-OS-Layer-Desktop.md` — Layer 3 Hyprland, Waybar, shell
- `RaBbLE-OS-Layer-Apps.md` — Layer 4 browsers, dev tools
- `../RaBbLE-sCoRE/sCoRE-Local-AI-Layer.md` — AI harnesses + sCoRE provider registry (full detail)
