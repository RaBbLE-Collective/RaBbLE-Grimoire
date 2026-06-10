#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# spells/seal-episode.sh — the Episode Signing Ceremony
#
# DRAFT / TO BE CRAFTED. Refuses to run until the Collective GitHub account
# exists and COLLECTIVE_EMAIL is set (see below).
#
# Seals a completed episode to `main` under the Collective's OWN identity, not
# Mark's. Day-to-day commits are Mark (and agents); the episode seal is the rare,
# deliberate act where RaBbLE signs in its own name.
#
# Mechanics: GitHub attributes a commit to whatever account has the AUTHOR email
# verified. We override name+email per-command (never global config), so the
# merge + annotated tag read as the Collective while Mark still pushes.
#
# Full lore: RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md
#
# Usage:
#   bash spells/seal-episode.sh <tag> "<message>"        # seal current dev → main
#   bash spells/seal-episode.sh episode-1-v0.0.0.1 "Episode 1 — Genesis"
#
# Prerequisites before this can be cast:
#   1. RaBbLE-Collective GitHub account exists (under RaBbLE-Collective@proton.me)
#   2. Its privacy noreply email known: NNNNNN+RaBbLE-Collective@users.noreply.github.com
#   3. Set COLLECTIVE_EMAIL below (or export it in the environment)
#   4. (optional) SSH signing key on the account → set COLLECTIVE_SIGN=1
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Collective identity ──────────────────────────────────────────────────────
# TODO(EP1): fill in once the RaBbLE-Collective GitHub account is live.
COLLECTIVE_NAME="${COLLECTIVE_NAME:-RaBbLE Collective}"
COLLECTIVE_EMAIL="${COLLECTIVE_EMAIL:-}"          # NNNNNN+RaBbLE-Collective@users.noreply.github.com
COLLECTIVE_SIGN="${COLLECTIVE_SIGN:-0}"           # 1 = sign with SSH key for the Verified badge
COLLECTIVE_SIGNKEY="${COLLECTIVE_SIGNKEY:-}"      # path to / value of the SSH signing key
SOURCE_BRANCH="${SOURCE_BRANCH:-dev}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; RESET='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
info() { echo -e "  ${CYAN}·${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }

TAG="${1:-}"
MSG="${2:-}"

# ── Guard: not yet craftable ─────────────────────────────────────────────────
if [ -z "$COLLECTIVE_EMAIL" ]; then
  echo
  err "seal-episode.sh is a DRAFT — COLLECTIVE_EMAIL is not set."
  echo
  warn "This spell cannot be cast until the RaBbLE-Collective GitHub account exists."
  info "Then set its privacy noreply email (Settings → Emails → keep private):"
  info "  COLLECTIVE_EMAIL=NNNNNN+RaBbLE-Collective@users.noreply.github.com"
  info "Edit this file's TODO, or export the var. Lore: RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md"
  echo
  exit 2
fi

if [ -z "$TAG" ] || [ -z "$MSG" ]; then
  err "Usage: seal-episode.sh <tag> \"<message>\""
  info "  e.g. seal-episode.sh episode-1-v0.0.0.1 \"Episode 1 — Genesis\""
  exit 1
fi

# ── Ceremony ─────────────────────────────────────────────────────────────────
echo
echo -e "${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}  ║${RESET}  ${BOLD}Episode Signing Ceremony${RESET}                          ${CYAN}║${RESET}"
echo -e "${CYAN}  ║${RESET}  sealed by: ${BOLD}${COLLECTIVE_NAME}${RESET}                       ${CYAN}║${RESET}"
echo -e "${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo
info "tag:    $TAG"
info "as:     $COLLECTIVE_NAME <$COLLECTIVE_EMAIL>"
info "merge:  $SOURCE_BRANCH → $TARGET_BRANCH"
[ "$COLLECTIVE_SIGN" = "1" ] && info "signed: yes (SSH)" || warn "signed: no (authorship reads as Collective, no Verified badge)"
echo

read -r -p "  Seal this episode? [y/N] " confirm
[ "$confirm" = "y" ] || { info "Aborted — nothing sealed."; exit 0; }

# Refuse a dirty tree.
if [ -n "$(git status --porcelain)" ]; then
  err "Working tree is not clean. Commit or stash before sealing."
  exit 1
fi

SIGN_ARGS=()
if [ "$COLLECTIVE_SIGN" = "1" ]; then
  SIGN_ARGS=(-c gpg.format=ssh -c user.signingkey="$COLLECTIVE_SIGNKEY")
fi

git checkout "$TARGET_BRANCH"

git "${SIGN_ARGS[@]}" \
    -c user.name="$COLLECTIVE_NAME" -c user.email="$COLLECTIVE_EMAIL" \
    merge --no-ff "$SOURCE_BRANCH" \
    -m "evolve ~ collective >> ${MSG} // %${TAG//[^A-Za-z0-9]/_}%" \
    $([ "$COLLECTIVE_SIGN" = "1" ] && echo "--gpg-sign")

git "${SIGN_ARGS[@]}" \
    -c user.name="$COLLECTIVE_NAME" -c user.email="$COLLECTIVE_EMAIL" \
    tag -a "$TAG" -m "$MSG" \
    $([ "$COLLECTIVE_SIGN" = "1" ] && echo "--sign")

echo
ok "Episode sealed as $COLLECTIVE_NAME — tag $TAG on $TARGET_BRANCH."
warn "Not pushed. When ready:  git push origin $TARGET_BRANCH --follow-tags"
echo
