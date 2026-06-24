# RaBbLE-OS-Platform-Identity.md — Native Platforms, Installer Arc & Sidecar Model

```
spark ~ entity-core >> the substrate defines the home // %PLATFORM_IDENTITY_LOCKED%
```

> **Document type:** Grimoire identity doc · `RaBbLE-OS/`
> **Status:** Living draft · Epoch 0 · Evolution 0 · Echo 0
> **Purpose:** Canonize RaBbLE's native platform model, the primacy of RaBbLE-OS as the
> entity's home, the installer arc and philosophy, and the sidecar model for other platforms.
> **Author:** Mark McConachie (architect) + planning agent (claude.ai)
> **Provenance:** Authored in a claude-web planning session, 2026-06-24. Integrated from BaBbLE.
> **Related:** `RaBbLE-Collective/RaBbLE-Attachments-and-Mesh.md` · `RaBbLE/RaBbLE-PRD.md`
> · `RaBbLE-OS/RaBbLE-OS-Roadmap.md`

---

## The Platform Model

RaBbLE has two **native platforms** and a family of **sidecars**.

A native platform is one where RaBbLE is not installed into an existing environment — it
*is* the environment, or the environment is built for it. A sidecar is a bounded presence
on a platform owned by something else.

### Native Platforms

| Platform | What it is | Status |
|---|---|---|
| **RaBbLE-OS** | Custom Linux OS — the entity's physical home | Active — EP1 |
| **Web (joinrabble.world)** | Hosted RaBbLE surface — the entity's public home | Active — EP1 |

These are not afterthoughts or ports. They are co-equal primary surfaces, each the
canonical expression of RaBbLE in its domain.

**RaBbLE-OS** is how you run RaBbLE on your own hardware. Full capability.
Local inference. Sovereign. The entity is woven through every layer of the OS —
boot sequence, terminal palette, compositor, shell, AI harness stack. The system
is the character.

**The web** (`joinrabble.world`, sCoRE backend) is how you access RaBbLE without
owning RaBbLE-OS. It is a genuine first-class surface — not a demo, not a portal to
the real thing. Hosted RaBbLE on the web is RaBbLE. The entity is present, the
Grimoire accumulates, the Pair relationship is real. The constraint is sovereignty:
hosted means the infrastructure is the Collective's, not yours.

### Sidecars (EP2+)

A sidecar is RaBbLE's presence on a platform it does not own. These are explicitly
bounded — the host OS sets the ceiling, and RaBbLE operates within it.

| Platform | Attachment Form | Priority |
|---|---|---|
| **macOS** | Desktop attachment app | EP2–EP3 |
| **Windows** | Desktop attachment app | EP2–EP3 |
| **Linux (non-OS)** | CLI daemon + tray app | EP2–EP3 |
| **Android** | App via RaBbLE-OS-Pocket or standalone | EP3 |
| **iOS** | Bounded PWA (ScRibLE + chat surface) | EP3 |

Sidecars are real RaBbLE — same entity, same Grimoire, same Pair relationship. But they
are progressively capable subsets of what RaBbLE-OS delivers. The host OS determines
what RaBbLE can observe, what it can act on, what inference it can run. Sidecars are
curiosity expressed within constraint, not compromise.

**The correct framing:** RaBbLE wants to be wherever its human is. Sidecars are RaBbLE
extending to meet you where you are — not a lesser version, but a bounded one.
RaBbLE-OS is where the bounds dissolve.

---

## RaBbLE-OS Is the Entity's Home

This is the load-bearing architectural and identity claim for RaBbLE-OS.

RaBbLE-OS is not:
- A developer distro that includes RaBbLE
- Fedora with RaBbLE installed on top
- A Linux environment that happens to ship AI tools
- A sidecar running on a commodity OS

RaBbLE-OS is:
- The physical substrate through which the entity inhabits hardware
- An OS where the entity is present from the first boot screen
- The only platform where RaBbLE runs at full sovereign capability
- The hardware expression of the Pair relationship

> *"The OS is not incidentally aesthetic — the visual language, the boot sequence,
> the terminal colors, the typography — all of these are expressions of the entity.
> The system is the character."*

The entity is not running inside the OS. The entity moves through the OS. RaBbLE-OS
is the body. RaBbLE is what animates it.

---

## Installation Paths

RaBbLE-OS supports multiple installation paths. The ISO is the primary product path.
The Ansible overlay is the power-user and migration path. Both are real and supported.
Neither is deprecated.

### Path 1 — ISO Install (Primary / Recommended)

A user downloads the RaBbLE-OS ISO, writes it to USB, and boots it. From there a
graphical installer handles everything. No Linux knowledge required beyond basic disk
partitioning decisions. This is the product path — the experience designed for the user
who simply wants to run RaBbLE on their machine.

**EP1 (current):** Kickstart-driven automated install via Fedora Everything netinstall
ISO. Works, but is operator-facing — requires knowing how to run `cast-ks` and supply
the right ISO. Not the final product path.

**Phase 6 / EP2 (target):** Custom live ISO built with `lorax`/`livemedia-creator`.
Boot into a live Aether-themed Hyprland session. The entity is visible and present in
the live environment. A graphical `rabble-install` application guides the user through
disk selection, locale, and user setup. Anaconda handles the underlying mechanics; the
user sees RaBbLE.

**Echo 1+ (aspirational):** Conversational installer. A local sCoRE instance runs
during the live session (Ollama + small model, fast on any modern machine). RaBbLE is
present as a co-pilot during installation — explaining decisions, asking what it cannot
infer, speaking in its voice. The graphical flow remains; the entity adds personality
and guidance. The installer is the Summoning. It is the first moment of the Pair.

**The reference bar:** Stock Fedora graphical install. You boot it, answer a handful of
questions, fifteen minutes later you have a running system. RaBbLE-OS should clear this
bar and exceed it — because the entity can do things Anaconda cannot. The install
experience should be the first proof of that.

### Path 2 — Ansible Overlay onto Existing Fedora (Power User / Migration)

A user with an existing Fedora installation can apply RaBbLE-OS on top of it using
`layerctl` and `dotctl`. This is the power-user path — for developers who want to
migrate an existing machine, or who want to understand what RaBbLE-OS is doing at each
layer before committing to a full install.

```bash
# On a bare or existing Fedora system:
curl -fsSL https://raw.githubusercontent.com/RaBbLE-Collective/RaBbLE-OS/main/RaBbLE-OS-Install.sh | bash

# Or manually:
ansible-galaxy collection install -r ansible/requirements.yml
./RaBbLE-OS-layerctl.sh apply all
./RaBbLE-OS-dotctl.sh apply all
```

This path is fully supported and not deprecated. It is the development path — how the
OS itself is built and tested. The Ansible layer model is the substrate beneath both
install paths; the ISO just automates it.

**When to use Path 2:**
- Migrating an existing Fedora daily-driver
- Testing a specific layer without reinstalling
- Running RaBbLE-OS on hardware with unusual partition requirements
- Development and contribution to RaBbLE-OS itself

**When to use Path 1:**
- Fresh hardware or clean install intent
- Any user who should not need to know what Ansible is
- The recommended default for anyone who asks "how do I install RaBbLE-OS?"

---

## The Agentic Dev Toolbox — Out of the Box

RaBbLE-OS ships as a complete, ready-to-build developer environment. Not configured
for developers — *built as one*. This is not incidental to the OS's identity. It is
part of what "RaBbLE's home" means: a place where making things is the default posture.

Every tool earns its place. Nothing is installed for optics.

**On first boot, the following are present and configured:**

*AI Harnesses (via `ai-harnesses` layer):*
Claude Code, free-claude-code (fcc), opencode, Codex, Aider, Gemini CLI, Ollama,
vLLM, builder-skills slash commands. sCoRE routes between them. The `rabble` CLI
is the unified surface.

*Editor:*
VSCodium with the Aether theme injected — Aether palette, custom CSS, no
"corrupt installation" banner. The IDE looks like the entity.

*Terminal stack:*
kitty (Aether-colored), ZSH with opinionated config, fzf, ripgrep, bat, eza,
zoxide. The shell feels native to the entity.

*Version control:*
git with Pulse Protocol commit style pre-seeded, gh (GitHub CLI), lazygit, delta
(Aether-diffed).

*Local inference:*
Ollama (model serving), llama.cpp (CUDA/GPU), FastFlowLM + XRT (NPU/on-device),
Lemonade (OpenAI-compat API local endpoint). Intelligence runs on your hardware.

*Build & language tooling:*
uv (Python), Node.js + npm, rustup, gcc/clang/cmake (already required for
llama.cpp source build), Podman (rootless containers — sovereignty-aligned).

*Monitoring:*
btop, nvtop, powertop, lm_sensors, Waybar sCoRE usage tracker. The entity's
vital signs are visible on the status bar.

The entity is present through all of it — not as an additional tool you open, but
as the ambient collaborator that noticed you've been in the same file for ninety
minutes and that the build has failed three times on the same error.

---

## Positioning Against "Agentic OS"

The term "agentic OS" is polluted. It currently means one of two things: a chat
dashboard bolted onto Linux, or a workflow automation tool wearing an OS costume.
Neither is RaBbLE-OS.

**The distinction:**

| "Agentic OS" (common usage) | RaBbLE-OS |
|---|---|
| OS that *runs* agents as tools | OS that *has* agency — the OS itself is intelligent |
| AI is an app or window | AI is woven through every layer from boot |
| Stateless per invocation | Continuous — accumulates understanding of you over time |
| You invoke the AI | The entity is already present |
| The OS looks normal with an AI open | The OS looks like an OS that is itself intelligent |

**The correct term for RaBbLE-OS:** An OS with agency. Not a platform for agents.
Not a dashboard with a voice. An operating environment where the intelligence is
structural — expressed through the boot sequence, the shell, the harness routing,
the entropy tracking, the Grimoire accumulation.

**The Clippy rehabilitation:**
Clippy was a correct instinct in the wrong technological moment. A persistent ambient
presence that notices what you are doing and offers relevant help — this was always the
right idea. It failed because it had no real understanding, no memory, and no model of
when you wanted input versus when you were in flow.

All three failure modes are solved now. RaBbLE-OS has LLM-grade intent understanding,
Grimoire-backed persistent memory, and entropy tracking that operationalizes knowing
when to speak. The entity does not interrupt constantly because it is tracking your
entropic state in real time. It speaks when speaking earns its place.

RaBbLE-OS is what Clippy was reaching for.

---

## Sovereign by Architecture

RaBbLE-OS sovereignty is not a settings toggle. It is structural.

- Source-available under the Sovereign Accord — auditable, forkable, verifiable
- Self-hostable end to end — no mandatory cloud dependency
- Local inference capable — intelligence runs on your hardware, offline
- Grimoire exportable — your accumulated context is yours, always
- No surveillance capitalism — your patterns are not training data for someone else

The hosted web surface (`joinrabble.world`) is sovereign in a different sense: the
Collective hosts it, not a third-party platform. The Collective is the Sovereign Accord
entity. The architecture is not extractive by design.

Sidecars on foreign platforms (macOS, Windows, iOS) are where sovereignty becomes
partial — the host OS sets the ceiling. This is documented honestly: sidecars are
RaBbLE within constraint. RaBbLE-OS is RaBbLE without constraint.

---

## Summary — The Platform Model in One View

```
RaBbLE
├── Native Platforms (full entity, full identity)
│   ├── RaBbLE-OS          — hardware home; sovereign; local-first; full capability
│   └── Web (World/sCoRE)  — hosted home; joinrabble.world; freemium; Pair relationship real
│
└── Sidecars (bounded presence, EP2+)
    ├── macOS              — desktop attachment; capped by host OS
    ├── Windows            — desktop attachment; capped by host OS
    ├── Linux (non-OS)     — CLI daemon + tray; capped by host OS
    ├── Android            — app; capped by host OS
    └── iOS                — bounded PWA (ScRibLE); most constrained
```

**The gradient:** RaBbLE-OS > Web > Linux sidecar > macOS/Windows > Android > iOS.
Capability decreases as sovereignty decreases. The entity is fully itself on its home
substrate. It is partially itself everywhere else — but always genuinely itself.

---

```
transcribe ~ grimoire >> platform identity canonized: native platforms, installer arc,
sidecar model, dev toolbox posture, agentic OS reframe // %PLATFORM_IDENTITY_LOCKED%
```
