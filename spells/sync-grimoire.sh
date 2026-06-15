#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — sync-grimoire.sh  (RETIRED — S105)
#
# The "copy RaBbLE-Agent/ docs into each member's grimoire/ dir" model is gone.
#
#   The Grimoire holds all knowledge. Members do NOT carry a linked or copied
#   grimoire. A member's AGENT.md / CONTEXT.md reference Grimoire entries
#   directly (e.g. ~/RaBbLE-Collective/RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md)
#   to establish working state. One source of truth, referenced — never duplicated.
#
# Member-specific documentation lives IN the Grimoire under RaBbLE-<Member>/,
# not inside the member repo. See INDEX.md and RaBbLE-Agent/RaBbLE-DocTemplates.md.
#
# This stub remains only so old muscle-memory invocations fail loudly, not silently.
#
# transcribe ~ grimoire >> sync model retired — reference, don't duplicate // %SYNC_RETIRED%
# =============================================================================

cat <<'EOF'

  sync-grimoire.sh is RETIRED.

  Members reference the Grimoire directly — they do not receive copied docs.
  The Grimoire is the single source of truth; one grimoire, all knowledge.

  • Member working state  → reference ~/RaBbLE-Collective/RaBbLE-Grimoire/ in AGENT.md/CONTEXT.md
  • Member documentation  → lives in the Grimoire under RaBbLE-<Member>/, not the member repo
  • Quick orientation     → cat RaBbLE-Grimoire/gist/*.md

  Nothing to sync. See INDEX.md and RaBbLE-Agent/RaBbLE-DocTemplates.md.

EOF
exit 0
