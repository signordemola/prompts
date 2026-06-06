#!/usr/bin/env bash
set -euo pipefail

# Push lessons from a project to the master GitHub repo as an issue
# Usage: bash .ai-skills/push-lessons.sh

REPO="signordemola/prompts"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ── Preflight checks ────────────────────────────────────────────────────────

if ! command -v gh &>/dev/null; then
  err "GitHub CLI (gh) is required. Install: sudo apt install gh"
fi

if ! gh auth status &>/dev/null 2>&1; then
  err "Not logged in to GitHub. Run: gh auth login"
fi

# ── Find content to push ────────────────────────────────────────────────────

SKILLS_DIR=".ai-skills"
REFLECTION="$SKILLS_DIR/REFLECTION.md"
LESSONS="$SKILLS_DIR/LESSONS.md"

# Determine project name from directory
PROJECT_NAME=$(basename "$(pwd)")
TODAY=$(date +%Y-%m-%d)

if [ -f "$REFLECTION" ]; then
  SOURCE_FILE="$REFLECTION"
  info "Found REFLECTION.md — pushing reflection"
elif [ -f "$LESSONS" ]; then
  SOURCE_FILE="$LESSONS"
  info "No REFLECTION.md found — pushing raw LESSONS.md"
else
  err "No lessons to push. Run the reflect workflow first, or check that .ai-skills/LESSONS.md exists."
fi

# ── Show preview ─────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Preview of what will be posted:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$SOURCE_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Build issue body ─────────────────────────────────────────────────────────

ISSUE_TITLE="📝 Lessons — $PROJECT_NAME ($TODAY)"

# Combine reflection + proposed changes if both exist
BODY_FILE=$(mktemp)
cat "$SOURCE_FILE" >> "$BODY_FILE"

if [ -f "$SKILLS_DIR/PROPOSED-CHANGES.md" ] && [ "$SOURCE_FILE" != "$SKILLS_DIR/PROPOSED-CHANGES.md" ]; then
  echo "" >> "$BODY_FILE"
  echo "---" >> "$BODY_FILE"
  echo "" >> "$BODY_FILE"
  cat "$SKILLS_DIR/PROPOSED-CHANGES.md" >> "$BODY_FILE"
fi

# ── Confirm with user ───────────────────────────────────────────────────────

read -rp "Create issue in $REPO? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Cancelled."
  rm -f "$BODY_FILE"
  exit 0
fi

# ── Create GitHub issue ──────────────────────────────────────────────────────

ISSUE_URL=$(gh issue create \
  --repo "$REPO" \
  --title "$ISSUE_TITLE" \
  --body-file "$BODY_FILE" \
  --label "lessons" \
  2>&1)

rm -f "$BODY_FILE"

if [ $? -eq 0 ]; then
  log "Issue created: $ISSUE_URL"
  echo ""
  echo "Next steps:"
  echo "  1. Review the issue on GitHub"
  echo "  2. Open ~/Documents/prompts with a good model (Opus 4.6)"
  echo "  3. Say: 'Apply approved lessons from issue #N'"
  echo "  4. Review the skill changes and push"
else
  err "Failed to create issue: $ISSUE_URL"
fi
