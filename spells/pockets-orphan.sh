#!/usr/bin/env bash
# spells/pockets-orphan.sh: orphan every Pocket on the live sCoRE, so each one must be re-flashed or paired.
#
# Run it yourself in a real terminal:   bash RaBbLE-Grimoire/spells/pockets-orphan.sh [--dry-run]
#
# A Pocket can reach sCoRE three ways today, and this closes all three:
#   1. its per-device guest key        -> tools/revoke_guests.py deletes every guest account (step 4)
#   2. the shared BEAM_DEVICE_TOKEN    -> rotated to a fresh random value on Render (step 1)
#   3. minting a new guest at flash    -> GUEST_ISSUE_SECRET rotated, so /users/guest answers 403 (step 1)
# The new values are random, never printed and not stored anywhere: nothing can reopen these doors but a
# deliberate new value. Pairing (a member-minted device key) is the way back in; it is not built yet
# (log/plans/Accounts-Architect-and-Entity-Roadmap.md R6), so until it is, no Pocket can talk to sCoRE.
# The Pocket web flasher mints guests with the old secret, so it will fail until pairing replaces it.
#
# Not touched: members, the Architect, the entity account, the website chat (guests there are demo mode).
# Undo: set the two env vars back to the old values (the flasher's copy of GUEST_ISSUE_SECRET is in
# ~/.config/rabble/pocket-companion.secrets if it was kept there) and redeploy; deleted guests stay deleted.
#
# spark ~ grimoire >> orphan all Pockets: rotate the shared token and guest secret, revoke guests // %S346_ORPHAN%

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
S="$ROOT/RaBbLE-sCoRE"
API="${SCORE_URL:-https://score.joinrabble.world}"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
say() { c "0;36" "· $*"; }  ok() { c "0;32" "✓ $*"; }  die() { c "0;31" "✗ $*" >&2; exit 1; }
run() { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

[ -t 0 ] || die "run this in a terminal (it asks for confirmation)"
[ -d "$S/server/tools" ] && [ -x "$HERE/render-ctl.sh" -o -f "$HERE/render-ctl.sh" ] || die "expected $S and render-ctl.sh"
command -v openssl >/dev/null || die "openssl is needed to make the random values"

say "This will end access for EVERY Pocket (yours, your dad's, all guests) on the live sCoRE."
say "Each Pocket must be re-flashed or paired afterwards. Pairing is not built yet, so none can connect until it is."
read -r -p "Type ORPHAN to continue: " a
[ "$a" = "ORPHAN" ] || die "not confirmed; nothing changed"

echo; say "Step 1: rotate GUEST_ISSUE_SECRET and BEAM_DEVICE_TOKEN on Render (values stay hidden)"
for k in GUEST_ISSUE_SECRET BEAM_DEVICE_TOKEN; do
  if [ "$DRY" = 1 ]; then echo "  [dry-run] env-set $k <random>"; else bash "$HERE/render-ctl.sh" env-set "$k" "$(openssl rand -hex 32)" >/dev/null; ok "$k rotated"; fi
done

echo; say "Step 2: redeploy so Render picks them up (a few minutes)"
run bash "$HERE/render-ctl.sh" deploy --wait

echo; say "Step 3: check guest minting is closed"
if [ "$DRY" = 0 ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/api/v1/users/guest" -H 'X-Guest-Secret: not-the-secret' -H 'content-type: application/json' -d '{}' || true)
  [ "$code" = "403" ] && ok "minting refused (403)" || echo "  expected 403, got $code: check the deploy finished"
fi

echo; say "Step 4: delete every guest account (lists them, asks you to type REVOKE)"
if [ "$DRY" = 1 ]; then echo "  [dry-run] revoke_guests.py"; else
  ( set -a; . "$S/.env.local"; set +a; cd "$S/server" && "$S/.venv/bin/python" tools/revoke_guests.py )
fi

echo; ok "Done. Every Pocket is orphaned. Next: pairing (R6), then each Pocket is re-flashed on its owner's account."
