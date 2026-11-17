> Recovered from the 2026-11-17 chat export: written during the chat "Local hardware requirements for Sonnet-level open models" (2026-08-15). Verbatim, not reconciled with current canon. Working notes, not a spec.

# RaBbLE Collective: Society-of-Agents Architecture Notes

*Working notes from an exploratory conversation, Aug 2026. Captures the reasoning chain and open questions for later refinement — not a finalized spec.*

## Core Concept

A hierarchical, heterogeneous multi-agent architecture: clusters of homogeneous agents (same model, cloned instances) nested under managers, with diverse cluster *types* available per task domain, coordinated by a general-purpose orchestration layer (sCoRE) that stays domain-agnostic. Domain-specific work (e.g. Incenergy) plugs in as a leaf/niche rather than living inside the orchestrator.

```
API-tier intelligence (Sonnet/Opus-class) — ambiguous judgment, escalation target
        |
sCoRE orchestrator — domain-agnostic routing, escalation policy, cluster management
        |
   Cluster managers — capable model directing a cluster, own decision rights
    /        |        \
Cluster A  Cluster B  Cluster C  — homogeneous groups (cloned same-model workers)
(Incenergy) (RaBbLE Pocket) (future niche)
        |
Edge nodes (1-3B) — classification/routing/simple extraction only, no multi-step reasoning
```

## Key Findings From Research (grounded, not speculative)

1. **Small multi-agent systems can beat larger single models** on tool-intensive tasks (retrieval, multi-hop QA, math) — but only when the *orchestrator* has strong reasoning capacity. Adding reasoning capacity to sub-agents gave limited or negative returns. System performance tracks orchestrator capacity, not sub-agent capacity. → Don't build a flat swarm of equal-capability agents; invest capability where judgment actually happens.

2. **Hierarchical (company-style) organization outperforms flat collaboration** for LLM multi-agent systems — in one study, +100%+ performance with ~75% less token usage vs. flat structure on a reasoning benchmark. Hierarchy helps most when tasks benefit from stable skill assignment, controlled information flow, and layered verification.

3. **Multi-agent failures are dominated by system design issues, not raw model capability.** A large empirical taxonomy (MAST, 1,600+ traces, 7 frameworks) found real-world MAS failure rates of 41-86.7%, clustered into three categories: specification/system-design issues, inter-agent misalignment, and task verification failures. Critically: *improving base model capability alone does not fix most of these.* This directly complicates the "just use stronger models everywhere" instinct — the fix is narrow task specification + verification layers, not uniformly frontier-level agents.

4. **KV-cache forking (not attention/embedding transfer) is the practical mechanism for cheap homogeneous cloning.** Compute a shared prefix's KV cache once, fork multiple same-model worker instances from it. Mature production tech (vLLM PagedAttention, SGLang RadixAttention, LMCache). Only works within identical model weights.

5. **Cross-model (heterogeneous) attention/KV transfer is research-stage, not deployable.** Options that exist: closed-form linear mapping within a model *family* (e.g. Qwen3 14B→32B, requires shared KV head structure); learned neural projectors across genuinely different architectures (Cache-to-Cache, ICLR'26, ~8-10% accuracy gain but requires training a projector per model pair). For a genuinely heterogeneous swarm, the shared context-engineered KB (read/write via tool calls) is the more robust near-term answer — it sidesteps architecture mismatch entirely.

6. **Org theory (RACI, Mintzberg coordination, bounded authority) translates usefully but not wholesale.** Frameworks exist that treat classic organizational design as executable, swappable configuration for MAS. The translation isn't 1:1 — rigid escalation chains and information-filtering middle management (bad in human orgs for morale/political reasons) may still be fine or even good for agent systems; conversely, clear accountability and stable role assignment translate directly and are strongly evidenced to help.

## Design Implications for RaBbLE Collective

- **sCoRE stays domain-agnostic.** Task classification, tier routing, escalation policy, and cluster management logic should not encode anything Incenergy-specific (or specific to any single niche). The contract between sCoRE and a niche (tool schemas, confidence signals, escalation triggers, shared-KB read/write pattern) is the piece worth getting right first — it determines whether adding a new domain is cheap.
- **Incenergy becomes a leaf/niche**, not a sub-hierarchy. Its own escalation policy (e.g. "control-path writes always escalate to top tier") lives inside its plug-in contract, not in sCoRE core.
- **Escalation should be trigger-based, not positional.** Avoid climbing every tier sequentially for every task — route by confidence/task classification so cheap tasks resolve at the edge and hard/ambiguous ones jump straight to the capable tier.
- **Verification is a bigger lever than raw model swaps.** Given finding #3, prioritize building cheap verification/consistency checks at cluster boundaries over upgrading worker model size as the default fix for unreliability.
- **Concentrate judgment, not just parameters, at unverifiable decision points.** Ambiguous, novel, or high-stakes-and-hard-to-verify decisions (e.g. Incenergy control-path writes) belong at the top tier regardless of how good lower-tier models get — this is a structural argument, not just a capability one.

## Open Questions / Next Steps to Explore

1. **Define the sCoRE↔niche plugin contract explicitly** — what must a domain expose (tool schema format, confidence signal, escalation trigger, KB read/write pattern) to be pluggable without touching orchestrator code?
2. **Prototype KV-cache forking for a homogeneous cluster** (e.g. Qwen3.5-8B workers) using vLLM/SGLang prefix caching — measure actual latency/throughput win vs. re-processing text handoffs on your hardware (Strix Point laptop, DDR5 desktop).
3. **Read the MAST taxonomy in full** (Cemri et al., arXiv:2503.13657) and map its 14 failure modes against whatever collaboration protocol sCoRE ends up using — treat it as a pre-mortem checklist.
4. **Investigate the org-theory-as-executable-config framing** (IMACS-style separation of organization/coordination/collaboration-protocol as independently swappable layers) — could inform how sCoRE's cluster-manager assignment is structured.
5. **Evaluate whether a cross-model-family closed-form KV mapping is worth building** (e.g. if RaBbLE Collective standardizes on one model family across tiers, like all-Qwen3.x at different sizes) vs. relying purely on the shared KB for heterogeneous cases — this is a real design fork, not just an implementation detail.
6. **Look at hierarchical MAS research specifically in energy/operations domains** (cited in the taxonomy literature) as prior art closer to the Incenergy use case than generic multi-agent papers.
7. **Decide the escalation-trigger mechanism concretely**: confidence threshold from the model itself? A separate lightweight classifier? Task-type routing table? Each has different failure modes worth stress-testing before committing.
8. **Define what "verification at cluster boundaries" actually looks like for Incenergy specifically** — given the read/write split already established, what's the cheapest meaningful check on a write-path cluster's output before it executes?

## Key References

- Cemri et al., "Why Do Multi-Agent LLM Systems Fail?" — MAST failure taxonomy, arXiv:2503.13657
- "Can Small Agents Collaborate to Beat a Single Large Language Model?" — orchestrator-capacity finding, arXiv:2601.11327
- "OrgAgent: Organize Your Multi-Agent System like a Company" — hierarchy vs. flat structure benchmark
- "Beyond the Strongest LLM: Multi-Turn Multi-Agent Orchestration vs. Single LLMs" — herding/premature consensus in voting-based orchestration, arXiv:2509.23537
- "Cache-to-Cache" (ICLR'26) — heterogeneous cross-model KV cache fusion via learned projectors
- "Cross-Model KV Cache Transfer in LLM Families" — closed-form linear mapping within model family, arXiv:2608.03893
- "Toward an Organizational Science of Multi-Agent LLM Systems" — org-theory-as-config framework, arXiv:2607.25446
