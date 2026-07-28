#!/usr/bin/env python3
"""
Grimoire -> flat KB bundler.

Concatenates the canonical RaBbLE-Grimoire docs into ~16 self-contained
Markdown files suitable for uploading to a Claude.ai project knowledge base.

Each bundle gets:
  - a header describing the bundle
  - a table of contents
  - every source doc, separated by a clear delimiter showing its repo path

Invoked by spells/build-kb.sh — do not run directly unless iterating on the
bundle map below.
"""
import os
import sys
import textwrap

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GRIMOIRE_ROOT = os.path.dirname(SCRIPT_DIR)          # spells/ -> Grimoire root

SRC = GRIMOIRE_ROOT
OUT = os.path.join(GRIMOIRE_ROOT, "generated", "grimoire-kb")

GEN_NOTE = (
    "> Generated from RaBbLE-Grimoire as a flat knowledge-base bundle. "
    "Each section below is one source document, shown with its original repo path. "
    "Canonical source remains the Grimoire repo; regenerate with `bash spells/build-kb.sh`."
)

# Each bundle: (out_filename, Title, one-line purpose, [sources])
# A source is either a path string, or a tuple:
#   ("path", "head", N)   -> only first N lines
#   ("path", "yaml")      -> wrap content in a ```yaml fence
BUNDLES = [
    ("00-Orientation-and-Index.md", "Orientation & Index",
     "Start here — what the Grimoire is, how to read it, and the full document index.",
     [
        "README.md", "AGENT.md", "CONTEXT.md",
        "gist/RaBbLE-Gist-Overview.md",
        "gist/RaBbLE-Identity-gist.md",
        "gist/RaBbLE-Collective-gist.md",
        "gist/RaBbLE-Collective-Overview-gist.md",
        "gist/RaBbLE-Integration-Map-gist.md",
        "gist/RaBbLE-Roadmap-gist.md",
        "gist/RaBbLE-Episode1-gist.md",
        "gist/RaBbLE-Versioning-gist.md",
        "gist/RaBbLE-CommitStyle-gist.md",
        "gist/RaBbLE-Palette-gist.md",
        "RaBbLE-Agent/RaBbLE-Overview.md",
        "RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md",
        "RaBbLE-Agent/RaBbLE-References.md",
        "INDEX.md",
     ]),

    ("01-Identity-Ethos-and-Voice.md", "Identity, Ethos & Voice",
     "Who RaBbLE is — manifesto, character, voices, behavioral rules, philosophy, palette.",
     [
        "RaBbLE-Agent/RaBbLE-Identity.md",
        "RaBbLE/RaBbLE-Overview.md",
        "RaBbLE/Ethos/RaBbLE-Ethos-Overview.md",
        "RaBbLE/Ethos/RaBbLE-Ethos.md",
        "RaBbLE-Agent/RaBbLE-Palette.md",
     ]),

    ("02-Vision-PRD-and-Worldbuilding.md", "Vision, PRD & Worldbuilding",
     "What RaBbLE is as a product and a world — PRD, the Epoch arc, stakeholder brief, aesthetic.",
     [
        "RaBbLE/RaBbLE-PRD.md",
        "RaBbLE/RaBbLE-Vision-Arc.md",
        "RaBbLE/RaBbLE-Stakeholder-Brief.md",
        "RaBbLE/Worldbuilding/RaBbLE-Worldbuilding-Overview.md",
        "RaBbLE/Worldbuilding/RaBbLE-Aesthetic.md",
        "RaBbLE/Genesis/RaBbLE-Genesis-Overview.md",
        "RaBbLE/Genesis/RaBbLE-Genesis-Visual-Catalog.md",
     ]),

    ("03-Collective-Architecture-and-Integration.md", "Collective Architecture & Integration",
     "The ecosystem map — members, three-layer architecture, cross-member data flow, deployment topology.",
     [
        "RaBbLE-Agent/RaBbLE-Collective.md",
        "RaBbLE-Agent/RaBbLE-Integration-Map.md",
        "RaBbLE-Collective/RaBbLE-Collective-Plan.md",
        "RaBbLE-Collective/RaBbLE-Collective-Episode-1-Overview.md",
        "RaBbLE-Collective/RaBbLE-Deployment-Architecture.md",
        "RaBbLE-Agent/RaBbLE-Collective-KnownIssues.md",
     ]),

    ("04-Conventions-Versioning-and-Methodology.md", "Conventions, Versioning & Methodology",
     "How work is done — the Five Es, Pulse Protocol commits, branch strategy, doc templates, agent protocols, dev methodology, captures.",
     [
        "RaBbLE-Versioning.md",
        "RaBbLE-Agent/RaBbLE-CommitStyle.md",
        "RaBbLE-Agent/RaBbLE-BranchStrategy.md",
        "RaBbLE-Agent/RaBbLE-DocTemplates.md",
        "RaBbLE-Agent/RaBbLE-Agent-Protocols.md",
        "RaBbLE-Agent/RaBbLE-Development-Methodology.md",
        "RaBbLE-Agent/RaBbLE-Captures-System.md",
     ]),

    ("05-Roadmap-and-Episode-1.md", "Roadmap & Episode 1 Release",
     "Where it's going — unified roadmap, post-EP1 map, and the canonical Episode 1 scope / RC experience / air gate.",
     [
        "RaBbLE-Agent/RaBbLE-Roadmap.md",
        "RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md",
        "RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md",
        "RaBbLE-Collective/RaBbLE-Episode-1-RC-Scope.md",
        "RaBbLE-Collective/RaBbLE-RC1-Experience.md",
        "RaBbLE-Collective/RaBbLE-Episode-1-Release-Brief.md",
        "log/EP1-AIR-CHECKLIST.md",
        "log/episodes/EPISODE-1-RELEASE.md",
     ]),

    ("06-Deployment-Ops-and-Secrets.md", "Deployment, Ops & Secrets",
     "How it ships — Cloudflare/R2 + Render, the EP1 deploy runbook, CI/CD plan, the secrets/identity model, and the Grimoire MCP concept.",
     [
        "RaBbLE-Collective/RaBbLE-Cloudflare-Integration.md",
        "RaBbLE-Collective/RaBbLE-Episode-1-Deployment-Runbook.md",
        "RaBbLE-Collective/RaBbLE-CICD-Plan.md",
        "RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md",
        "RaBbLE-Collective/RaBbLE-Grimoire-MCP.md",
     ]),

    ("07-GTM-Business-and-Cosmos.md", "GTM, Business & Future Cosmos",
     "How it grows and sustains — GTM content strategy, income model, shop, social layer, membership, and the EP2+ Personal Cosmos / mesh.",
     [
        "RaBbLE-Collective/RaBbLE-GTM-Content-Strategy.md",
        "RaBbLE-Collective/RaBbLE-Income-Model.md",
        "RaBbLE-Collective/RaBbLE-Shop.md",
        "RaBbLE-Collective/RaBbLE-Social-and-Aesthetic.md",
        "RaBbLE-Collective/RaBbLE-Membership-Model.md",
        "RaBbLE-Collective/RaBbLE-Service-Plan.md",
        "RaBbLE-Collective/RaBbLE-Personal-Cosmos.md",
        "RaBbLE-Collective/RaBbLE-Attachments-and-Mesh.md",
        "RaBbLE-Collective/RaBbLE-Integration-Ethos-Plan.md",
     ]),

    ("08-sCoRE-Engine.md", "sCoRE — Coordination Engine",
     "The first iteration of RaBbLE itself — architecture, roadmap, membership/grimoire APIs, local AI layer, agent-framework research.",
     [
        "RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md",
        "RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md",
        "RaBbLE-sCoRE/RaBbLE-sCoRE-Membership-API.md",
        "RaBbLE-sCoRE/RaBbLE-sCoRE-Grimoire-API.md",
        "RaBbLE-sCoRE/sCoRE-Local-AI-Layer.md",
        "RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-Framework-Research.md",
        "RaBbLE-sCoRE/RaBbLE-sCoRE-DataCrawler-RFC.md",
     ]),

    ("09-World-Surface.md", "World — Living Surface",
     "joinrabble.world — roadmap, architecture, page template, EP1 unification, the RC1 emergence rebuild, grimoire browser, maintenance.",
     [
        "RaBbLE-World/RaBbLE-World-README.md",
        "RaBbLE-World/RaBbLE-World-Roadmap.md",
        "RaBbLE-World/RaBbLE-World-Architecture.md",
        "RaBbLE-World/RaBbLE-World-Page-Template.md",
        "RaBbLE-World/RaBbLE-World-EP1-Unification.md",
        "RaBbLE-World/RaBbLE-World-RC1-Emergence-Plan.md",
        "RaBbLE-World/RaBbLE-Grimoire-Browser-Plan.md",
        "RaBbLE-World/RaBbLE-World-MAINTAINING.md",
     ]),

    ("10-NeBuLA-Renderer.md", "NeBuLA — Renderer & Effects",
     "The entity's visual body — roadmap, architecture, identity, public API, rearchitecture plan, FlatChaos, ideas, backlog.",
     [
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Architecture.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Identity.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Rearchitecture.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Plan.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-FlatChaos.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Ideas.md",
        "RaBbLE-NeBuLA/RaBbLE-NeBuLA-Refinement-Backlog.md",
     ]),

    ("11-Aether-Design-System.md", "Aether — Design System",
     "The design engine — roadmap, architecture, build/CDN pipeline, design guide, system prompt, effects bank.",
     [
        "RaBbLE-Aether/RaBbLE-Aether-Roadmap.md",
        "RaBbLE-Aether/RaBbLE-Aether-Architecture.md",
        "RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md",
        "RaBbLE-Aether/RaBbLE-Aether-Design-Guide.md",
        "RaBbLE-Aether/SYSTEM-PROMPT.md",
        "RaBbLE-Aether/RaBbLE-Aether-Effects-Bank.md",
     ]),

    ("12-RaBbLE-OS-Part1-Guide-Layers-Ops-Hardware.md", "RaBbLE-OS · Part 1 — Guide, Layers, Ops, Hardware",
     "The OS member (Fedora 43 / Hyprland) — agent guide, roadmap, rough edges, layer model, ops controllers, hardware targets.",
     [
        "RaBbLE-OS/RaBbLE-OS-AgentGuide.md",
        "RaBbLE-OS/RaBbLE-OS-Roadmap.md",
        "RaBbLE-OS/RaBbLE-OS-KnownRoughEdges.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layers.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-Core.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-Hardware.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot-Plymouth-EP1.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-Desktop.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-Apps.md",
        "RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md",
        "RaBbLE-OS/ops/RaBbLE-OS-Ops-Layerctl.md",
        "RaBbLE-OS/ops/RaBbLE-OS-Ops-Dotctl.md",
        "RaBbLE-OS/ops/RaBbLE-OS-Ops-Bootstrap.md",
        "RaBbLE-OS/ops/RaBbLE-OS-Ops-ConfigFlow.md",
        "RaBbLE-OS/ops/RaBbLE-OS-Ops-Install.md",
        "RaBbLE-OS/ops/RaBbLE-OS-Ops-Vmctl.md",
        "RaBbLE-OS/hardware/RaBbLE-OS-Hardware-GenericX64.md",
        "RaBbLE-OS/hardware/RaBbLE-OS-Hardware-ProArtP16.md",
        "RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Cyberdeck.md",
        "RaBbLE-OS/hardware/RaBbLE-OS-Hardware-NPU-XDNA2.md",
        "RaBbLE-OS/hardware/RaBbLE-OS-Hardware-AddingTargets.md",
        "RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Partitions.md",
     ]),

    ("13-RaBbLE-OS-Part2-Desktop-Fixes-Verify-History.md", "RaBbLE-OS · Part 2 — Desktop, Fixes, Verify, History",
     "The OS member continued — desktop/theming, known issues & fixes, verification runbooks, dev history.",
     [
        "RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Hyprland.md",
        "RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Shell.md",
        "RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md",
        "RaBbLE-OS/desktop/RaBbLE-OS-Desktop-BootFlow.md",
        "RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Fastfetch.md",
        "RaBbLE-OS/desktop/RaBbLE-OS-Desktop-sCoRE-UsageTracker.md",
        "RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md",
        "RaBbLE-OS/fix/RaBbLE-OS-Fix-BootChain.md",
        "RaBbLE-OS/fix/RaBbLE-OS-Fix-Nvidia.md",
        "RaBbLE-OS/fix/RaBbLE-OS-Fix-Suspend.md",
        "RaBbLE-OS/fix/RaBbLE-OS-Fix-FastFlowLM.md",
        "RaBbLE-OS/fix/RaBbLE-OS-Fix-LlamaCpp.md",
        "RaBbLE-OS/verify/RaBbLE-OS-Verify-PreviewFloor.md",
        "RaBbLE-OS/verify/RaBbLE-OS-Verify-Checklist.md",
        "RaBbLE-OS/verify/RaBbLE-OS-Verify-LayerState.md",
        "RaBbLE-OS/verify/RaBbLE-OS-Verify-PowerTesting.md",
        "RaBbLE-OS/RaBbLE-OS-DevHistory.md",
     ]),

    ("14-Members-Registry-and-Spells.md", "Minor Members, Registry & Spells",
     "BaBbLE / Chrysalis / Xperimental / ScRibLE overviews, the member registry + epoch definition + manifests, and the spell system.",
     [
        "RaBbLE-BaBbLE/RaBbLE-BaBbLE-Overview.md",
        "RaBbLE-Chrysalis/RaBbLE-Chrysalis-Overview.md",
        "RaBbLE-Xperimental/RaBbLE-Xperimental-Overview.md",
        "RaBbLE-ScRibLE/RaBbLE-ScRibLE-Overview.md",
        "registry/RaBbLE-Collective-Registry.md",
        "registry/CONTEXT.md",
        ("registry/epochs/current.epoch.yml", "yaml"),
        ("registry/manifests/RaBbLE-Collective.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-sCoRE.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-OS.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-World.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-NeBuLA.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-Aether.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-BaBbLE.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-Chrysalis.manifest.yml", "yaml"),
        ("registry/manifests/RaBbLE-Xperimental.manifest.yml", "yaml"),
        "SPELLS.md",
     ]),

    ("15-History-Decisions-Ideas-and-Lore.md", "History, Decisions, Ideas & Lore",
     "The Collective's memory — development history, decisions log, audits, novel ideas, the entropy archive, the Fable gap, current session state, and the origin story.",
     [
        "log/RaBbLE-Development-History.md",
        "log/DECISIONS.md",
        "log/AUDITS.md",
        "RaBbLE-Agent/RaBbLE-NovelIdeas.md",
        "RaBbLE-Agent/RaBbLE-DistilledNonZense.md",
        "log/archive/FABLE-GAP-ANALYSIS-S57.md",
        ("log/SESSION-LOG.md", "head", 60),
        "RaBbLE-Mythos/Summoned/Summoned-v5.md",
     ]),
]


def read_source(entry):
    """Return (relpath, mode, content). mode in {'md','yaml'}."""
    mode = "md"
    head_n = None
    if isinstance(entry, tuple):
        rel = entry[0]
        if entry[1] == "yaml":
            mode = "yaml"
        elif entry[1] == "head":
            head_n = entry[2]
    else:
        rel = entry
    path = os.path.join(SRC, rel)
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    if head_n is not None:
        lines = content.splitlines()
        content = "\n".join(lines[:head_n])
        content += (
            "\n\n*(… truncated — only the current-state header of SESSION-LOG.md is "
            "included; the full running log lives in the Grimoire repo.)*\n"
        )
    return rel, mode, content


def slugify(rel):
    return rel.replace("/", "_").replace(".md", "").replace(".yml", "")


def build_bundle(fname, title, purpose, sources):
    parts = []
    parts.append(f"# {title}\n")
    parts.append(f"*{purpose}*\n")
    parts.append(GEN_NOTE + "\n")
    # TOC
    parts.append("## Contents of this bundle\n")
    resolved = []
    for entry in sources:
        rel, mode, content = read_source(entry)
        resolved.append((rel, mode, content))
        anchor = slugify(rel)
        parts.append(f"- [`{rel}`](#{anchor})")
    parts.append("")
    parts.append("---\n")
    # Bodies
    for rel, mode, content in resolved:
        anchor = slugify(rel)
        parts.append(f'<a id="{anchor}"></a>')
        parts.append(f"# ═══ SOURCE: `{rel}` ═══\n")
        if mode == "yaml":
            parts.append("```yaml")
            parts.append(content.rstrip())
            parts.append("```")
        else:
            parts.append(content.rstrip())
        parts.append("\n\n---\n")
    out_path = os.path.join(OUT, fname)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(parts) + "\n")
    size = os.path.getsize(out_path)
    nfiles = len(resolved)
    return size, nfiles


def main():
    os.makedirs(OUT, exist_ok=True)
    total_size = 0
    total_files = 0
    index_rows = []
    for fname, title, purpose, sources in BUNDLES:
        size, nfiles = build_bundle(fname, title, purpose, sources)
        total_size += size
        total_files += nfiles
        index_rows.append((fname, title, purpose, nfiles, size))
        print(f"  {fname:60s} {nfiles:3d} docs  {size/1024:7.1f} KB")
    print(f"\n  TOTAL: {len(BUNDLES)} bundles, {total_files} source docs, {total_size/1024:.1f} KB")
    write_readme(index_rows, total_files, total_size)


def write_readme(index_rows, total_files, total_size):
    lines = []
    lines.append("# RaBbLE Grimoire — Knowledge Base Bundle\n")
    lines.append(
        "A flat, browsable Markdown archive of the **RaBbLE-Grimoire** — the canonical "
        "source of truth for the RaBbLE Collective. Built for upload to a Claude.ai "
        "project knowledge base so Claude on the web has full ecosystem context for "
        "planning and conversational research.\n")
    lines.append(
        f"**{len(index_rows)} bundles** consolidating **{total_files} source documents** "
        f"(~{total_size/1024:.0f} KB total). Upload all `*.md` files in this folder to "
        "your Claude project.\n")
    lines.append("## Bundles\n")
    lines.append("| # | File | Contents | Docs |")
    lines.append("|---|---|---|---|")
    for i, (fname, title, purpose, nfiles, size) in enumerate(index_rows):
        lines.append(f"| {i:02d} | `{fname}` | **{title}** — {purpose} | {nfiles} |")
    lines.append("")
    lines.append("## How it was built\n")
    lines.append(
        "Generated by `spells/build-kb.sh` (a Grimoire spell — `spells/build-kb.py` does the "
        "work) from the Grimoire repo. Each bundle starts with a table of contents and "
        "concatenates its source docs, each prefixed with its original repo path "
        "(`═══ SOURCE: path ═══`) so provenance is preserved. This folder is generated output "
        "— gitignored, not canonical. Re-run `bash spells/build-kb.sh` after Grimoire changes "
        "to refresh.\n")
    lines.append("## Deliberately excluded\n")
    lines.append(
        "To keep the KB focused and within upload limits, these were left out (all still "
        "live in the Grimoire repo):\n")
    lines.append(
        "- **Raw transcripts / story drafts** — `RaBbLE-Mythos/Summoned/Summoned-Transcript.md` "
        "(~530 KB) and drafts v0–v4 (only the final `Summoned-v5.md` is included).\n"
        "- **Full session log** — `log/SESSION-LOG.md` (~330 KB); only its current-state "
        "header is included (in bundle 15). The distilled `RaBbLE-Development-History.md` "
        "carries the narrative.\n"
        "- **Ephemeral / superseded** — debug logs (`DEBUG-SESSION-*`, `REGRESSION-AUDIT-*`), "
        "one-off handoff/dispatch docs (`log/HANDOFF-*`, `EP1-Dispatch-State`, "
        "`EP1-READINESS-AUDIT-S103`, `S104-*`, `RC1-Entity-Correspondence`), per-session "
        "`log/lessons/*`, the `grimoire-graph.*` link-graph, and superseded NeBuLA perf docs "
        "(`Perf-Fix-Plan`, `Perf-Handoff`, `Canvas2D-Perf`, `RABL`, archived `RBCNS`).\n"
        "- **Standalone Hyprland reference** — `RaBbLE-OS/Hyprland-0.55-Reference.md` "
        "(upstream reference, not RaBbLE canon).\n")
    lines.append(
        "Add any of these back by editing the `BUNDLES` list in `spells/build-kb.py` and "
        "re-running `bash spells/build-kb.sh`.\n")
    with open(os.path.join(OUT, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
