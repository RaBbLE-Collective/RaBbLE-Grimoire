#!/usr/bin/env bash
# spells/score-cutover.sh: put sCoRE accounts live on Render, then create the Architect.
#
# Run it yourself in a real terminal:   bash RaBbLE-Grimoire/spells/score-cutover.sh [--dry-run | --architect-only]
#
# What it does, in order (it asks before each step that changes production):
#   0. Preflight: release/0.1.0 contains new-horizons, working tree is clean, gitleaks finds nothing.
#   1. Render env: SIGNUP_INVITE_ONLY=true, CORS_ORIGINS, clear R2_ALLOW_FRESH_START (B-31). Nothing redeploys yet.
#   2. git push origin release/0.1.0: Render auto-deploys it and runs the accounts migration on Neon.
#   3. Waits until the new code answers (POST /api/v1/auth/login returns 422, not 404) and /health is OK.
#   4. Read-only Neon check: accounts tables exist, the two Pocket guests are still there. Counts only.
#   5. Optionally runs tools/make_architect.py (hidden password input; no secret goes anywhere but the database).
#
# Secrets: DATABASE_URL and the R2 keys are read from files inside this script and never printed.
# Rollback: Render dashboard > the service > Deploys > redeploy the previous deploy. The accounts tables
# are additive, so the old code keeps working against the migrated database.
#
# spark ~ grimoire >> one script for the sCoRE accounts cutover // %S346_CUTOVER%

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"      # from this file, never from env: RABBLE_ROOT means other things in some shells
G="$ROOT/RaBbLE-Grimoire"
S="$ROOT/RaBbLE-sCoRE"
API="${SCORE_URL:-https://score.joinrabble.world}"
CORS="https://joinrabble.world,https://dev.joinrabble.world"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
ONLY_ARCHITECT=0; [ "${1:-}" = "--architect-only" ] && ONLY_ARCHITECT=1

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
say()  { c "0;36" "· $*"; }
ok()   { c "0;32" "✓ $*"; }
warn() { c "1;33" "! $*"; }
die()  { c "0;31" "✗ $*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
ask()  { local a; read -r -p "$1 [y/N] " a; [[ "$a" =~ ^[Yy]$ ]]; }

[ -t 0 ] || die "run this in a terminal (it asks questions)"
[ -d "$S/.git" ] && [ -d "$G/spells" ] || die "expected $S and $G"

if [ "$ONLY_ARCHITECT" = 1 ]; then
  say "Creating the Architect only (RaBbLE-Architect). It asks for the email and a hidden password."
  ( set -a; . "$S/.env.local"; set +a; cd "$S/server" && exec "$S/.venv/bin/python" tools/make_architect.py )
  exit $?
fi

# ── 0. Preflight ────────────────────────────────────────────────────────────────
say "Preflight"
cd "$S"
git fetch -q origin
git rev-parse --verify -q release/0.1.0 >/dev/null || die "no local release/0.1.0"
git merge-base --is-ancestor new-horizons release/0.1.0 || die "release/0.1.0 does not contain new-horizons: merge it first"
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then die "tracked files have uncommitted changes in sCoRE"; fi
AHEAD=$(git rev-list --count origin/release/0.1.0..release/0.1.0)
[ "$AHEAD" -gt 0 ] || warn "release/0.1.0 has nothing new to push (already pushed?)"
if command -v gitleaks >/dev/null; then
  gitleaks detect --source . --log-opts="origin/release/0.1.0..release/0.1.0" --no-banner --redact >/dev/null 2>&1 \
    && ok "gitleaks: no secrets in the $AHEAD commits to push" || die "gitleaks found something: do not push"
else
  warn "gitleaks not installed; skipping the secret scan"
fi
ok "release/0.1.0 ($(git rev-parse --short release/0.1.0)) contains new-horizons, $AHEAD commits ahead of origin"

# ── 1. Render env ───────────────────────────────────────────────────────────────
echo
say "Step 1: Render environment (SIGNUP_INVITE_ONLY=true, CORS_ORIGINS=$CORS, clear R2_ALLOW_FRESH_START)"
ask "Set these on the live Render service now?" || die "stopped before changing Render"
cd "$G"
run bash spells/render-ctl.sh env-set SIGNUP_INVITE_ONLY true >/dev/null && ok "SIGNUP_INVITE_ONLY=true"
run bash spells/render-ctl.sh env-set CORS_ORIGINS "$CORS" >/dev/null && ok "CORS_ORIGINS set"
run bash spells/render-set-r2.sh --clear-fresh-start >/dev/null && ok "R2_ALLOW_FRESH_START cleared (B-31)"

# ── 2. Push = deploy ────────────────────────────────────────────────────────────
echo
say "Step 2: push release/0.1.0. Render tracks this branch and deploys it automatically."
ask "Push to production now?" || die "stopped before the push (env vars are staged; nothing is deployed)"
cd "$S"
run git push origin release/0.1.0
ok "pushed"

# ── 3. Wait for the new code ────────────────────────────────────────────────────
echo
say "Step 3: waiting for the new deploy (free-plan builds take a few minutes)"
if [ "$DRY" = 0 ]; then
  for i in $(seq 1 60); do
    code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/api/v1/auth/login" -H 'content-type: application/json' -d '{}' || true)
    health=$(curl -s -o /dev/null -w '%{http_code}' "$API/health" || true)
    if [ "$code" = "422" ] && [ "$health" = "200" ]; then ok "new code is live (login route answers 422, /health 200)"; break; fi
    printf '  attempt %s/60: login=%s health=%s\n' "$i" "$code" "$health"
    [ "$i" = 60 ] && die "no new code after 15 minutes: check the Render dashboard (bash spells/render-ctl.sh logs 200)"
    sleep 15
  done
  curl -s "$API/health"; echo
  # sCoRE connects to the database on its first real request, which is what runs the migration: make one.
  curl -s -o /dev/null -X POST "$API/api/v1/auth/forgot-password" -H 'content-type: application/json' -d '{"email":"warmup@example.com"}' || true
  sleep 5
fi

# ── 4. Neon check (read-only, counts only) ──────────────────────────────────────
echo
say "Step 4: Neon check (read-only)"
if [ "$DRY" = 0 ]; then
  (
    set -a; . "$S/.env.local"; set +a
    "$S/.venv/bin/python" - <<'PY'
import os, psycopg
url = os.environ.get("DATABASE_URL_UNPOOLED") or os.environ["DATABASE_URL"]
with psycopg.connect(url) as c:
    q = lambda s: c.execute(s).fetchone()[0]
    print("  accounts table:", "present" if q("select to_regclass('public.accounts') is not null") else "MISSING")
    print("  users total:", q("select count(*) from users"), "| guests:", q("select count(*) from users where tier = 'guest'"),
          "| accounts:", q("select count(*) from accounts"), "| invites:", q("select count(*) from invites"))
PY
  ) || warn "Neon check failed: look at it before going on"
  echo "  Expect: accounts present, guests 2 (your two Pocket guests), accounts 0 before the Architect exists."
fi

# ── 5. The Architect ────────────────────────────────────────────────────────────
echo
say "Step 5: create the Architect (RaBbLE-Architect). It asks for the email and a hidden password."
if ask "Run make_architect.py against the live database now?"; then
  [ "$DRY" = 1 ] && echo "  [dry-run] make_architect.py" || (
    set -a; . "$S/.env.local"; set +a
    cd "$S/server" && "$S/.venv/bin/python" tools/make_architect.py
  )
else
  echo "  Later: cd $S/server && set -a && . ../.env.local && set +a && ../.venv/bin/python tools/make_architect.py"
fi

echo
ok "Done."
cat <<EOF

Next:
  - Sign in at the Architect page once World is published (push RaBbLE-World new-horizons -> dev.joinrabble.world/world/admin.html).
  - Mint an invite for your personal email, then sign up with it.
  - Check one Pocket still connects.
  - Then remove the shared admin key so the Architect is the only way in:
      bash $G/spells/render-ctl.sh env-set RABBLE_ADMIN_KEY ""   (and redeploy)
EOF
