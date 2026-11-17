# RaBbLE-Dependency-Policy.md — External Sources and License Governance

```
transcribe ~ grimoire >> dependency policy crystallized, sovereignty preserved // %LICENSE_CANON%
```

> Canonical rules for how RaBbLE Collective members interact with external code, tools,
> content, and APIs. Every agent working on the Collective must read this before adding
> any external dependency, calling any external service, or incorporating any third-party
> asset.
>
> **Related:** [RaBbLE-Agent-Protocols](RaBbLE-Agent-Protocols.md) · [Sovereign Accord](../RaBbLE-Collective/RaBbLE-Income-Model.md) · [NOTICES.md](../NOTICES.md)

---

## The Governing Principle

RaBbLE is sovereign. Every external dependency is a potential point of lock-in, infection,
or constraint on the Collective's freedom to operate, distribute, and evolve. The Sovereign
Accord governs RaBbLE's own code. It cannot change what upstream licenses require of us —
but it can require that we only accept terms compatible with our sovereignty.

**The test for any external source:**

> Can the Collective run, modify, distribute, and commercialize its work without asking
> permission from, paying, or being restricted by this external source?

If no: it goes behind an API boundary. If it cannot be isolated that way: it does not enter.

---

## License Classification

### Tier 1 — Embed Freely (MIT · Apache 2.0 · BSD-2 · BSD-3 · CC0 · CC BY)

Fully permissive. No copyleft. Compatible with the Sovereign Accord.

These licenses require only that their copyright notice and license text be preserved in
the codebase. They do not require you to open-source your own code, share your changes,
or restrict commercial use.

**What "embed freely" means:** Source may be included directly in a Collective member repo.
The Sovereign Accord governs the whole distribution; permissive licenses govern only their
own components within it. These obligations are parallel, not competing.

**Attribution required:** For every Tier 1 dependency, record it in the member's
`NOTICES.md` (see Attribution section below).

### Tier 2 — API Boundary Required (GPL-2 · GPL-3 · AGPL · LGPL · CC BY-SA · MPL-2.0)

Copyleft / ShareAlike. These licenses require that derivative works carry the same license.
Embedding them in Collective source would require the surrounding code to carry their terms —
which conflicts with the Sovereign Accord.

**What "API boundary" means:** The dependency may be called via subprocess, HTTP API, or
IPC. The Collective owns the interface contract. The external tool sits behind it. If it
disappears, the interface stays and the implementation swaps.

**AGPL specific note:** AGPL extends GPL's requirements to network use — software run as a
service and accessed by users over a network must have its source published. Any AGPL tool
in sCoRE's server path is an immediate violation risk. Extra caution required.

**LGPL specific note:** LGPL permits dynamic linking without copyleft propagation. Static
linking or source-level embedding is not permitted. Always dynamic link or subprocess only.

**Never:** Import LGPL/GPL/AGPL code into a member's source files. Never statically link.
Even "just for the build" is a risk surface.

**Clean Room Specification (Tier 2 supplementary strategy)**

When Collective functionality needs to be similar to a Tier 2 licensed project, a clean
room approach may be used as a supplementary isolation layer alongside the API boundary
requirement. The process:

1. A spec agent reads the original source, docs, and behavior. It produces only a PRD
   or functional spec — describing what the software does, its API surface, data shapes,
   and behavior. No implementation details, no variable names, no algorithmic structure.
2. The spec is reviewed by Mark before implementation begins. If it contains
   implementation-level detail rather than behavioral description, it must be rewritten.
3. A separate implementing agent works exclusively from the spec. It must not be given
   access to the original source.

This does not replace the API boundary requirement. It is defense-in-depth for cases
where a Tier 2 project is a strong prior art reference. It does not guarantee
non-infringement — courts look at outputs not intent, AI training data contamination
is legally unsettled, and "substantial similarity" in structure or organization can
constitute infringement even without direct copying. Apply only with Mark's explicit
approval on a case-by-case basis. Never apply to AGPL sources without specific legal
consideration — the network-service clause makes clean room insufficient on its own.

### Tier 3 — Source-Available / Lock-In (Elastic License 2.0 · BUSL · SSPL · proprietary)

These are not open source by OSI definition. They typically permit development and
personal use but restrict managed service, commercial deployment, or redistribution.
LangGraph's `langgraph-api` server component falls here (Elastic License 2.0). MongoDB
Community Edition falls here (SSPL).

**What to do:** API boundary only. Never self-host a Tier 3 dependency as part of the
Collective's own infrastructure. Never include source. Thin adapter only — the Collective
owns the interface and can swap the implementation if licensing terms change or costs appear.

**Never:** Treat the free tier of a Tier 3 tool as permanent. Document any Tier 3
dependency explicitly in NOTICES.md with a note on the lock-in risk and the swap plan.

### Tier 4 — Do Not Use (CC BY-NC · CC BY-ND · CC BY-NC-SA · CC BY-NC-ND)

Non-commercial restriction (NC) directly conflicts with the Sovereign Accord's commercial
use terms. No-derivatives restriction (ND) prevents the Collective from modifying assets.

These licenses cannot be worked around with an API boundary. Do not incorporate NC or ND
licensed content in any form — not as embedded assets, not as referenced data, not as
training material for Collective-owned models.

If an NC-licensed asset is the only option for something, escalate to Mark. The answer is
almost always: find an alternative or create it.

---

## Quick Reference

| License | Tier | Action |
|---|---|---|
| MIT | 1 | Embed freely — add to NOTICES.md |
| Apache 2.0 | 1 | Embed freely — add to NOTICES.md |
| BSD-2-clause | 1 | Embed freely — add to NOTICES.md |
| BSD-3-clause | 1 | Embed freely — add to NOTICES.md |
| CC0 | 1 | Embed freely — no attribution required but good practice |
| CC BY | 1 | Embed freely — add to NOTICES.md |
| LGPL | 2 | Dynamic link / subprocess only — never embed source |
| MPL-2.0 | 2 | File-level copyleft — subprocess preferred; assess per case |
| GPL-2 / GPL-3 | 2 | Subprocess / HTTP only — never import |
| AGPL | 2 | Subprocess / HTTP only — extra caution in server paths |
| CC BY-SA | 2 | API boundary only — no embedded content |
| Elastic License 2.0 | 3 | API boundary only — document swap plan |
| BUSL | 3 | API boundary only — document swap plan |
| SSPL | 3 | API boundary only — document swap plan |
| Proprietary API (Anthropic, Groq, OpenRouter) | 3 | Thin adapter only — already handled by sCoRE chain |
| CC BY-NC (all NC variants) | 4 | Do not use |
| CC BY-ND (all ND variants) | 4 | Do not use |

---

## The Adapter Pattern

Every external dependency that is not Tier 1 must sit behind a Collective-owned interface.
The interface is the contract. The implementation is the adapter.

```
Collective code
    ↓
[Interface] — owned by the Collective, Sovereign Accord applies
    ↓
[Adapter] — thin translation layer, Collective-owned
    ↓
External tool / API / service
```

Rules for adapters:

- The adapter is the only Collective code that knows the external tool exists
- The adapter's interface must be expressible without reference to the external tool
- A working stub or mock must be definable against the interface (enables testing without the external dependency)
- The adapter must be swappable — a different implementation behind the same interface must be achievable in one session
- Document the swap plan in NOTICES.md alongside the dependency

---

## Attribution — The NOTICES.md Convention

Every member repo maintains a `NOTICES.md` at its root. The Collective root also maintains
one. Agents must update the relevant NOTICES.md whenever they add a Tier 1 dependency.

### NOTICES.md Structure

```markdown
# NOTICES.md — [Member Name]

This file records all third-party components incorporated into this member's codebase
under their original licenses. RaBbLE Collective original code is governed by the
Sovereign Accord (see LICENSE.md).

---

## Third-Party Components

### [Library Name] — [License Type]

Copyright (c) [Year] [Author or Organization]

[Full license text, or if Apache 2.0: "Licensed under the Apache License, Version 2.0.
Full text: https://www.apache.org/licenses/LICENSE-2.0"]

---

### [Another Library] — MIT

Copyright (c) [Year] [Author]

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction...
[full MIT text]

---

## External Services (API Boundary — Not Embedded)

The following tools and services are consumed via API or subprocess. Their source code
is not embedded in this member. These entries are informational — no license obligation
flows to the Collective from this usage.

| Service / Tool | License | Tier | Swap Plan |
|---|---|---|---|
| [Service name] | [License] | [3] | [One sentence on how to replace it] |
```

### Attribution Rules

- **Record at add time** — do not defer. If an agent adds a dependency, it adds the
  NOTICES.md entry in the same commit or the immediately following one.
- **MIT license text is short — include it in full.** Apache 2.0 is long — reference
  the URL and include the copyright line.
- **BSD-3 requires the non-endorsement clause to be preserved** — include full text.
- **You do not need to display attribution to end users** in the UI. NOTICES.md in the
  repo is sufficient for compliance.
- **The Sovereign Accord section in LICENSE.md is separate from NOTICES.md.** LICENSE.md
  governs Mark's original code. NOTICES.md documents what others require of us.

---

## Rules for Agents

When working on any Collective member:

1. **Before adding any external library or tool:** check its license. If unsure, state
   the uncertainty and ask — do not assume Tier 1.

2. **Do not add AGPL dependencies to sCoRE or any network-serving member** without
   explicit approval from Mark. The network-service clause creates an automatic violation
   risk in sCoRE's server path.

3. **Do not add any Tier 3 tool as a build-time or startup dependency.** Tier 3 tools
   are always optional adapters, never required for the member to function.

4. **Do not call an external API directly from member business logic.** External calls
   belong in adapter modules. sCoRE's LLM chain is the canonical example — providers
   are swappable, the chain interface is stable.

5. **Record every Tier 1 dependency in NOTICES.md** in the same session it is added.

6. **If a faster path exists using a GPL tool directly,** the faster path is not
   permitted. Use the subprocess boundary. Speed of implementation does not override
   license compliance.

7. **If you encounter a dependency already in the codebase that violates this policy,**
   flag it in the session log. Do not silently leave it. Do not remove it unilaterally
   without a replacement plan.

---

## Relationship to the Sovereign Accord

The Sovereign Accord governs what others may do with RaBbLE. This policy governs what
RaBbLE may do with others' work. They are parallel instruments.

The Sovereign Accord's commercial-use terms require that the Collective's code be free to
be commercialized by Mark. Any dependency that restricts commercial use (NC licenses, Tier 3
platform lock-in) undermines the Accord's commercial path. This policy is therefore not
optional — it is a structural requirement for the Sovereign Accord to be enforceable.

---

```
transcribe ~ grimoire >> external source policy locked, sovereignty preserved // %LICENSE_CANON%
```
