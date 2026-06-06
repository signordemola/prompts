#!/usr/bin/env bash
set -euo pipefail

# ai-skills installer / updater
# Usage:
#   Public repo:   curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
#   Private repo:  gh repo clone signordemola/prompts /tmp/_ai_skills -- --depth 1 && bash /tmp/_ai_skills/ai-skills/install.sh
#   Update:        bash scripts/ai-skills-update.sh
#   Partial:       bash scripts/ai-skills-update.sh --only workflows
#                  bash scripts/ai-skills-update.sh --only domains/booking
#                  bash scripts/ai-skills-update.sh --only skills/stripe-payments
#                  bash scripts/ai-skills-update.sh --only references

REPO_URL="https://github.com/signordemola/prompts.git"
REPO_SSH="git@github.com:signordemola/prompts.git"
REPO_SUBDIR="ai-skills"
BRANCH="main"
TEMP_DIR=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }
err()   { echo -e "${RED}❌ $1${NC}"; exit 1; }

cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

# ── Detect mode ──────────────────────────────────────────────────────────────

MODE="install"
ONLY=""

if [ -f "docs/ROUTER.md" ]; then
  MODE="update"
fi

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      ONLY="$2"
      shift 2
      ;;
    --help|-h)
      echo "AI-Skills Library Installer / Updater"
      echo ""
      echo "Usage:"
      echo "  bash install.sh              Full install or update"
      echo "  bash install.sh --only X     Update only a subset:"
      echo "    --only workflows           All workflow skills"
      echo "    --only skills              All framework/library skills"
      echo "    --only domains             All domain knowledge"
      echo "    --only domains/booking     Single domain"
      echo "    --only skills/stripe-payments  Single skill"
      echo "    --only references          All reference docs"
      echo "    --only router              Just ROUTER.md"
      echo "    --only agents              Just AGENTS.md + symlinks"
      exit 0
      ;;
    *)
      err "Unknown argument: $1. Use --help for usage."
      ;;
  esac
done

# ── Fetch latest from GitHub ─────────────────────────────────────────────────

info "Fetching latest ai-skills from GitHub..."
TEMP_DIR=$(mktemp -d)
CLONE_SUCCESS=false

# Strategy 1: gh CLI (works with private repos if logged in)
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  info "Using GitHub CLI (authenticated)..."
  if gh repo clone signordemola/prompts "$TEMP_DIR" -- --depth 1 --branch "$BRANCH" --single-branch --quiet 2>/dev/null; then
    CLONE_SUCCESS=true
  fi
fi

# Strategy 2: HTTPS with credential helper (works if git credentials stored)
if [ "$CLONE_SUCCESS" = false ]; then
  if git clone --depth 1 --branch "$BRANCH" --single-branch --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    CLONE_SUCCESS=true
  fi
fi

# Strategy 3: SSH (works if SSH key is set up)
if [ "$CLONE_SUCCESS" = false ]; then
  info "HTTPS failed, trying SSH..."
  if git clone --depth 1 --branch "$BRANCH" --single-branch --quiet "$REPO_SSH" "$TEMP_DIR" 2>/dev/null; then
    CLONE_SUCCESS=true
  fi
fi

if [ "$CLONE_SUCCESS" = false ]; then
  echo ""
  err "Could not clone repo. For private repos, run: gh auth login"
fi

SOURCE="$TEMP_DIR/$REPO_SUBDIR"

if [ ! -d "$SOURCE/docs" ]; then
  err "Expected docs/ directory not found in $SOURCE. Is the repo structure correct?"
fi

# ── Count what's there before ────────────────────────────────────────────────

BEFORE_COUNT=0
if [ -d "docs" ]; then
  BEFORE_COUNT=$(find docs/ -name '*.md' -type f 2>/dev/null | wc -l)
fi

# ── Install / Update ─────────────────────────────────────────────────────────

install_agents() {
  cp "$SOURCE/AGENTS.md" ./AGENTS.md
  
  # Create symlinks for tool compatibility
  ln -sf AGENTS.md CLAUDE.md
  
  # Optional: other tools
  if [ ! -f ".cursorrules" ]; then
    ln -sf AGENTS.md .cursorrules 2>/dev/null || true
  fi
  
  log "AGENTS.md installed + symlinks created (CLAUDE.md → AGENTS.md)"
}

install_docs() {
  local target="$1"  # e.g., "docs/workflows" or "docs/domains/booking"
  local source_path="$SOURCE/$target"
  
  if [ ! -d "$source_path" ] && [ ! -f "$source_path" ]; then
    err "Source path not found: $target"
  fi
  
  # Create parent dirs if needed
  mkdir -p "$(dirname "$target")"
  
  # Remove old and copy new
  rm -rf "$target"
  cp -r "$source_path" "$target"
}

install_usage() {
  if [ -f "$SOURCE/USAGE.md" ]; then
    cp "$SOURCE/USAGE.md" ./USAGE.md
    log "USAGE.md installed"
  fi
}

install_update_script() {
  mkdir -p scripts
  cp "$SOURCE/install.sh" scripts/ai-skills-update.sh 2>/dev/null || \
    cp "$0" scripts/ai-skills-update.sh 2>/dev/null || true
  chmod +x scripts/ai-skills-update.sh 2>/dev/null || true
  log "Update script saved to scripts/ai-skills-update.sh"
}

if [ -n "$ONLY" ]; then
  # ── Partial update ───────────────────────────────────────────────────────
  info "Partial update: --only $ONLY"
  
  case "$ONLY" in
    workflows)     install_docs "docs/workflows" ;;
    skills)        install_docs "docs/skills" ;;
    domains)       install_docs "docs/domains" ;;
    references)    install_docs "docs/references" ;;
    router)        cp "$SOURCE/docs/ROUTER.md" docs/ROUTER.md ;;
    agents)        install_agents ;;
    domains/*|skills/*|workflows/*)
      install_docs "docs/$ONLY"
      ;;
    *)
      err "Unknown target: $ONLY. Use --help to see available targets."
      ;;
  esac
  
  log "Partial update complete: $ONLY"
  
else
  # ── Full install/update ──────────────────────────────────────────────────
  
  if [ "$MODE" = "update" ]; then
    info "Updating existing ai-skills library..."
    
    # Back up any local customizations to AGENTS.md
    if [ -f "AGENTS.md" ] && ! [ -L "AGENTS.md" ]; then
      if ! diff -q "AGENTS.md" "$SOURCE/AGENTS.md" >/dev/null 2>&1; then
        cp AGENTS.md AGENTS.md.backup
        warn "Your AGENTS.md differs from upstream — backup saved to AGENTS.md.backup"
      fi
    fi
  else
    info "Fresh install of ai-skills library..."
  fi
  
  # Install everything
  install_agents
  install_docs "docs"
  install_usage
  install_update_script
  
  log "Full $MODE complete!"
fi

# ── Report ───────────────────────────────────────────────────────────────────

AFTER_COUNT=$(find docs/ -name '*.md' -type f 2>/dev/null | wc -l)
TOTAL_LINES=$(find docs/ -name '*.md' -exec cat {} + 2>/dev/null | wc -l)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}AI-Skills Library — $MODE complete${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Files:  $AFTER_COUNT markdown files"
echo "  Lines:  $TOTAL_LINES total lines"
echo "  Source: $REPO_URL ($BRANCH)"
echo ""

if [ "$MODE" = "install" ]; then
  echo "Installed files:"
  echo "  AGENTS.md        ← Rules for all AI agents"
  echo "  CLAUDE.md        ← Symlink → AGENTS.md"
  echo "  docs/ROUTER.md   ← Skill index (agents read this first)"
  echo "  docs/workflows/  ← 11 workflow skills"
  echo "  docs/skills/     ← 17 framework/library skills"
  echo "  docs/domains/    ← 3 domain knowledge bases"
  echo "  docs/references/ ← 5 reference docs"
  echo "  USAGE.md         ← Usage guide"
  echo ""
  echo "To update later:"
  echo "  bash scripts/ai-skills-update.sh"
  echo "  bash scripts/ai-skills-update.sh --only workflows"
fi

echo ""
