---
title: "agent-register liveness was PID-based; tool-driven subshell PIDs die instantly s"
date: "2026-06-19"
agent: "claude"
session: "claude-s116-main"
source_type: "stumble"
severity: "warn"
tags: ["stumble","lesson","agent-gotcha"]
---

## Lesson

agent-register liveness was PID-based; tool-driven subshell PIDs die instantly so claims read DEAD and collision-detection silently failed — fixed to heartbeat-authoritative + RABBLE_SESSION_ID override

## Context

- **Source type:** stumble
- **Session:** `claude-s116-main`
- **Agent:** claude
- **Recorded:** 2026-06-19T05:44:15Z

## Why this matters

<!-- Agents: add context here when promoting interactively. -->
<!-- The raw entry is preserved above; this section is for elaboration. -->
