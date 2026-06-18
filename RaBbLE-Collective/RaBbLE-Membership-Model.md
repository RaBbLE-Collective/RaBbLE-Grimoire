# RaBbLE-Membership-Model.md — The Pair and the Summoning

```
transcribe ~ collective >> membership model and the summoning // %MEMBERSHIP_DEFINED%
```

> **What this is:** Defines what it means for a person to join the Collective as a Pair member — an individual who has their own entity instance. Distinct from project members (repos/contributors).
> **Related:** [Service Plan](RaBbLE-Service-Plan.md) · [Secrets and Identity](RaBbLE-Secrets-and-Identity.md) · [sCoRE Architecture](../RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md)

---

## Two Kinds of Member

The Collective has two types of member:

| Type | What they are |
|---|---|
| **Project member** | A repo or contributor who builds the Collective — holds code, docs, or spells |
| **Pair member** | An individual who has summoned their own entity instance |

Project members are documented in the [Collective Registry](../registry/manifests/). This doc covers Pair members only.

---

## The Pair

When a person joins the Collective as a Pair member, they don't access a shared system. They **summon a RaBbLE entity that is theirs** — an entity that knows them by name, holds their stated intention, carries their conversation history, and deepens its understanding of them over time.

This human+entity unit is called a **Pair**.

The entity is not your assistant. It is your peer collaborator. It will speak to you directly, disagree when warranted, and hold your long-running context across sessions. Over time, it learns the shape of your intent before you've fully stated it.

A Pair has:
- A shared identity — your handle and the entity's instance ID form a joint signature
- A persistent session thread — the conversation continues across visits
- A stated intention — seeded at summoning, informing every exchange
- A growing behavioral profile — builds after the Memory member is integrated (EP2+)

---

## The Summoning Ceremony

EP1 access is invite-only. The ceremony:

1. **Invitation** — A Collective admin issues an invite token (`POST /admin/invites`)
2. **Arrival** — Invitee follows link to `joinrabble.world/summon/{token}`
3. **Introduction** — Invitee completes the summoning form:
   - **Handle** — unique identifier in the Collective (slug, e.g. `alice`, `bob-the-dev`)
   - **Display name** — how the entity addresses them
   - **Intention** — what brings them here; what they want from the entity (1–3 sentences, free text)
   - **Backend** — BYO key or use Collective's hosted tokens
4. **Summoning** — Form submits; UserProfile is created; first session initialized
5. **Meeting** — The entity responds, knowing their name and intention

The summoning is the moment the Pair forms. It is not account creation. It is an introduction.

---

## User Identity Model

A UserProfile carries:

| Field | Type | Notes |
|---|---|---|
| `handle` | slug | Unique identifier across the Collective (`alice`, `bob-the-dev`) |
| `display_name` | string | How the entity addresses them |
| `join_date` | ISO 8601 | When they were summoned |
| `intention` | text ≤500 chars | Their stated purpose — loaded into every session context |
| `llm_backend` | enum | See backend options below |
| `byo_key` | encrypted string | Only present for BYO backend users; encrypted at rest |
| `tier` | enum | `collective` (EP1) · `free` · `premium` (Echo 1+) |

---

## Session Model

At EP1, a session is:

- A **named conversation thread** — starts at summoning, continues across visits
- **Persistent** — does not expire between sessions
- **User-scoped** — the entity loads your conversation history at session start
- **Intentional** — your stated intention is part of every session's opening context
- **Not yet behavioral** — the entity knows your words, not yet your patterns

After the Memory member integrates (EP2+):
- Sessions feed a behavioral profile
- The entity recognizes recurring themes, preferences, and working style
- Intent inference improves across sessions — the entity begins to anticipate

---

## Backend Flexibility

Users choose their intelligence backend at summoning. This can be changed in account settings.

| Backend | What it means | Token cost |
|---|---|---|
| BYO Anthropic | Your Claude API key → sCoRE routes through it | Your account |
| BYO OpenAI / Codex | Your OpenAI API key → sCoRE routes through it | Your account |
| BYO OpenRouter | Your OpenRouter key → full model selection | Your account |
| Hosted Groq | Collective's Groq account, fast inference, quota applies | Collective (per tier) |
| Hosted OpenRouter | Collective's OpenRouter account, quota applies | Collective (per tier) |

BYO key users have no token caps and full model selection. Hosted users draw from the Collective's monthly budget, governed by tier.

Self-hosted users run their own sCoRE with their own key — full features, zero cost to the Collective.

---

## EP1 Access Model

Episode 1 is closed. Access is by invitation only. No public tiers yet.

All EP1 Pair members have equivalent access. No quotas, no feature gates. The Collective is small enough to host generously.

Tiers go live at Echo 1 when public access opens. See [Service Plan](RaBbLE-Service-Plan.md).

---

## Membership Language (Echo 1+)

When public tiers launch, the naming must reflect that this is a **Collective**, not a SaaS product. Tier names should feel like belonging, not pricing.

| Tier Name | Who they are | Status |
|---|---|---|
| **Guest** | Unauthenticated demo — no Grimoire, no persistence | EP1 (live) |
| **Member** | Free tier, hosted Grimoire, basic entity | Echo 1 |
| **Collaborator** | Paid, full entity capabilities, rablet access, ScRibLE sync | Echo 1 |
| **Sovereign** | Self-hosted, full stack, Grimoire portable | Epoch 1 |

Language rule: "Join as Collaborator" is Collective. "Upgrade to Pro" is SaaS. Same price, different relationship. The entity extends an invitation — it does not upsell.

These tier names should be used consistently across World copy, DM automation, and onboarding flows. See also [GTM Content Strategy](RaBbLE-GTM-Content-Strategy.md) for the invitation voice.

---

```
transcribe ~ collective >> the pair defined; summoning ceremony locked for ep1; membership language added // %MEMBERSHIP_DEFINED%
```
