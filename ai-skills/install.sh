#!/usr/bin/env bash
set -euo pipefail

# ai-skills installer / updater
# Installs into .ai-skills/ (gitignored) — nothing tracked in project git
#
# Usage:
#   Install:  bash /path/to/ai-skills/install.sh
#   Install:  curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
#   Update:   bash .ai-skills/update.sh
#   Partial:  bash .ai-skills/update.sh --only workflows

REPO_URL="https://github.com/signordemola/prompts.git"
REPO_SSH="git@github.com:signordemola/prompts.git"
REPO_SUBDIR="ai-skills"
BRANCH="main"
TEMP_DIR=""
INSTALL_DIR=".ai-skills"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

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

# ── Parse args ───────────────────────────────────────────────────────────────

MODE="install"
ONLY=""
SOURCE_PATH=""

if [ -d "$INSTALL_DIR/docs" ]; then
  MODE="update"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      ONLY="$2"
      shift 2
      ;;
    --source)
      SOURCE_PATH="$2"
      shift 2
      ;;
    --help|-h)
      echo "AI-Skills Library Installer / Updater"
      echo ""
      echo "Usage:"
      echo "  bash install.sh                              Full install or update"
      echo "  bash install.sh --source /path/to/ai-skills  Install from local copy"
      echo "  bash install.sh --only workflows             Update only workflows"
      echo "  bash install.sh --only skills                Update only skills"
      echo "  bash install.sh --only domains               Update only domains"
      echo "  bash install.sh --only domains/booking       Update single domain"
      echo "  bash install.sh --only skills/stripe-payments  Update single skill"
      echo "  bash install.sh --only references            Update only references"
      echo "  bash install.sh --only router                Update just ROUTER.md"
      exit 0
      ;;
    *)
      err "Unknown argument: $1. Use --help for usage."
      ;;
  esac
done

# ── Resolve source ───────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
if [ -z "$SOURCE_PATH" ] && [ -f "$SCRIPT_DIR/AGENTS.md" ] && [ -d "$SCRIPT_DIR/docs" ]; then
  SOURCE_PATH="$SCRIPT_DIR"
fi

if [ -n "$SOURCE_PATH" ]; then
  info "Using local source: $SOURCE_PATH"
  SOURCE="$SOURCE_PATH"
  if [ ! -d "$SOURCE/docs" ]; then
    err "Expected docs/ directory not found in $SOURCE"
  fi
else
  info "Fetching latest from GitHub..."
  TEMP_DIR=$(mktemp -d)
  CLONE_SUCCESS=false

  if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    info "Using GitHub CLI (authenticated)..."
    gh repo clone signordemola/prompts "$TEMP_DIR" -- --depth 1 --branch "$BRANCH" --single-branch --quiet 2>/dev/null && CLONE_SUCCESS=true
  fi

  if [ "$CLONE_SUCCESS" = false ]; then
    git clone --depth 1 --branch "$BRANCH" --single-branch --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null && CLONE_SUCCESS=true
  fi

  if [ "$CLONE_SUCCESS" = false ]; then
    info "HTTPS failed, trying SSH..."
    git clone --depth 1 --branch "$BRANCH" --single-branch --quiet "$REPO_SSH" "$TEMP_DIR" 2>/dev/null && CLONE_SUCCESS=true
  fi

  if [ "$CLONE_SUCCESS" = false ]; then
    err "Could not clone repo. Try: bash install.sh --source /path/to/ai-skills"
  fi

  SOURCE="$TEMP_DIR/$REPO_SUBDIR"
  if [ ! -d "$SOURCE/docs" ]; then
    err "Expected docs/ directory not found in $SOURCE"
  fi
fi

# ── Install functions ────────────────────────────────────────────────────────

install_gitignore() {
  # Add .ai-skills/ and root config files to .gitignore
  local entries=(".ai-skills/" "AGENTS.md" "CLAUDE.md" ".cursorrules")
  
  touch .gitignore
  for entry in "${entries[@]}"; do
    if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
      echo "$entry" >> .gitignore
    fi
  done
  log ".gitignore updated"
}

install_root_agents() {
  # Copy AGENTS.md to project root with path rewritten for .ai-skills/
  sed 's|docs/ROUTER\.md|.ai-skills/docs/ROUTER.md|g; s|docs/workflows/|.ai-skills/docs/workflows/|g; s|docs/LESSONS\.md|.ai-skills/LESSONS.md|g' \
    "$SOURCE/AGENTS.md" > ./AGENTS.md

  ln -sf AGENTS.md CLAUDE.md
  ln -sf AGENTS.md .cursorrules 2>/dev/null || true
  log "AGENTS.md + symlinks installed at project root (gitignored)"
}

install_docs() {
  local target="$1"
  local source_path="$SOURCE/$target"

  if [ ! -d "$source_path" ] && [ ! -f "$source_path" ]; then
    err "Source path not found: $target"
  fi

  mkdir -p "$INSTALL_DIR/$(dirname "$target")"
  rm -rf "$INSTALL_DIR/$target"
  cp -r "$source_path" "$INSTALL_DIR/$target"
}

install_scripts() {
  # Copy update script
  cp "$SOURCE/install.sh" "$INSTALL_DIR/update.sh" 2>/dev/null || \
    cp "${BASH_SOURCE[0]:-$0}" "$INSTALL_DIR/update.sh" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/update.sh" 2>/dev/null || true

  # Copy push-lessons script
  if [ -f "$SOURCE/push-lessons.sh" ]; then
    cp "$SOURCE/push-lessons.sh" "$INSTALL_DIR/push-lessons.sh"
    chmod +x "$INSTALL_DIR/push-lessons.sh" 2>/dev/null || true
  fi

  log "Scripts installed to $INSTALL_DIR/"
}

install_usage() {
  if [ -f "$SOURCE/USAGE.md" ]; then
    cp "$SOURCE/USAGE.md" "$INSTALL_DIR/USAGE.md"
  fi
}

# ── Execute ──────────────────────────────────────────────────────────────────

if [ -n "$ONLY" ]; then
  info "Partial update: --only $ONLY"
  case "$ONLY" in
    workflows)     install_docs "docs/workflows" ;;
    skills)        install_docs "docs/skills" ;;
    domains)       install_docs "docs/domains" ;;
    references)    install_docs "docs/references" ;;
    router)        cp "$SOURCE/docs/ROUTER.md" "$INSTALL_DIR/docs/ROUTER.md" ;;
    domains/*|skills/*|workflows/*)
      install_docs "docs/$ONLY"
      ;;
    *)
      err "Unknown target: $ONLY. Use --help for options."
      ;;
  esac
  install_root_agents
  log "Partial update complete: $ONLY"
else
  if [ "$MODE" = "update" ]; then
    info "Updating ai-skills library..."
  else
    info "Fresh install of ai-skills library..."
  fi

  mkdir -p "$INSTALL_DIR"
  install_gitignore
  install_root_agents
  install_docs "docs"
  install_scripts
  install_usage

  # Preserve LESSONS.md across updates
  # (don't overwrite if it already exists)

  log "Full $MODE complete!"
fi

# ── Report ───────────────────────────────────────────────────────────────────

AFTER_COUNT=$(find "$INSTALL_DIR/docs/" -name '*.md' -type f 2>/dev/null | wc -l)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}AI-Skills Library — $MODE complete${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Location:  $INSTALL_DIR/ (gitignored)"
echo "  Files:     $AFTER_COUNT markdown files"
echo ""

if [ "$MODE" = "install" ]; then
  echo "Installed:"
  echo "  AGENTS.md          ← Project root (gitignored)"
  echo "  CLAUDE.md          ← Symlink → AGENTS.md (gitignored)"
  echo "  $INSTALL_DIR/docs/   ← Skills library"
  echo ""
  echo "Commands:"
  echo "  bash $INSTALL_DIR/update.sh                  Update from GitHub"
  echo "  bash $INSTALL_DIR/update.sh --only workflows Partial update"
  echo "  bash $INSTALL_DIR/push-lessons.sh            Push lessons to GitHub"
fi

echo ""
