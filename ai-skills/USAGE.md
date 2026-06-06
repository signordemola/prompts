# AI-Skills Library — Usage Guide

## What This Is

A portable knowledge base you install into any project so AI coding agents follow your engineering workflows, domain patterns, and framework conventions. **Nothing is tracked in your project's git** — the library lives in `.ai-skills/` (gitignored).

## Quick Start

### Install into a project

**From your terminal (has GitHub credentials):**
```bash
curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
```

**From an AI agent terminal (no credentials):**
```bash
bash /path/to/ai-skills/install.sh
```
Auto-detects the local repo and copies from it.

**With explicit source path:**
```bash
bash /path/to/ai-skills/install.sh --source /path/to/ai-skills
```

### What gets installed

```
your-project/
├── .gitignore              ← Updated (adds .ai-skills/, AGENTS.md, etc.)
├── AGENTS.md               ← 11 rules, all agents read this (gitignored)
├── CLAUDE.md → AGENTS.md   ← Symlink for Claude Code (gitignored)
├── .cursorrules → AGENTS.md ← Symlink for Cursor (gitignored)
└── .ai-skills/             ← The library (gitignored)
    ├── docs/
    │   ├── ROUTER.md       ← Central index
    │   ├── workflows/ (12) ← HOW to work
    │   ├── skills/ (17)    ← WHAT tools to use
    │   ├── domains/ (3)    ← WHAT to build
    │   └── references/     ← Deep reference docs
    ├── update.sh           ← Update from GitHub
    └── push-lessons.sh     ← Push lessons to GitHub
```

**Nothing is tracked in git.** Only `.gitignore` is committed.

---

## How It Works

### The Chain

```
Agent opens project
  → Reads AGENTS.md (11 rules)
  → Rule 0: "Read .ai-skills/docs/ROUTER.md"
  → ROUTER.md matches task → loads the right workflow
  → Workflow enforces behavior via HARD-GATEs
  → Workflow loads relevant skills (Prisma, Next.js, etc.)
  → If agent makes a mistake → Rule 8 logs to .ai-skills/LESSONS.md
```

### The Three Layers

| Layer | Path | Purpose | When Loaded |
|-------|------|---------|-------------|
| **Workflows** | `.ai-skills/docs/workflows/` | Engineering process (brainstorm → plan → build → verify → ship) | When task matches trigger |
| **Skills** | `.ai-skills/docs/skills/` | Framework & library patterns (Next.js, NestJS, Prisma, Stripe, etc.) | When project uses that tech |
| **Domains** | `.ai-skills/docs/domains/` | Business logic (booking, ecommerce, chatbot) | When project is in that vertical |

### Context Loading (Tiered)

Agents don't read everything. They use tiered loading:

| Tier | When | Example |
|------|------|---------|
| **Always** | Rule 0 | ROUTER.md |
| **Match task** | Task matches a workflow | "Fix this bug" → debug |
| **Match project** | Project uses this stack | Next.js → nextjs-app-router |
| **On reference** | Skill says "read this" | debug → root-cause-tracing.md |

---

## Updating

### Full update (from GitHub)

```bash
bash .ai-skills/update.sh
```

### Partial updates

```bash
bash .ai-skills/update.sh --only workflows
bash .ai-skills/update.sh --only skills
bash .ai-skills/update.sh --only domains
bash .ai-skills/update.sh --only domains/booking
bash .ai-skills/update.sh --only skills/stripe-payments
bash .ai-skills/update.sh --only references
bash .ai-skills/update.sh --only router
```

### After cloning a project

Every developer must install once after cloning:
```bash
curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
```

---

## The Learning Loop

### During work (automatic)

When the agent makes a mistake or discovers a gap, Rule 8 fires and it logs to `.ai-skills/LESSONS.md`:

```markdown
## 2026-06-06 — PATTERN-GAP
**What happened:** Used wrong timezone function
**Root cause:** timezone-safety skill doesn't cover Luxon
**Which skill:** timezone-safety
**Severity:** CRITICAL
```

### End of project (you say "reflect")

The agent generates two files:
- `.ai-skills/REFLECTION.md` — what worked, what didn't, new patterns
- `.ai-skills/PROPOSED-CHANGES.md` — specific diffs for each skill to update

### Push lessons to GitHub

```bash
bash .ai-skills/push-lessons.sh
```

This creates a GitHub issue in the master repo with your reflection. You review on GitHub.

### Apply approved changes

Open the master repo with a good model (Opus 4.6) and say:
```
Apply approved lessons from issue #N
```

The model edits the skills, you review and push. All future projects get the fix.

---

## Directory Reference

### Workflows (12)

| Skill | Trigger |
|-------|---------|
| `brainstorming/` | Starting any creative work |
| `plan/` | Decomposing spec into tasks |
| `executing-plans/` | Executing task-by-task (no subagents) |
| `subagent-driven-development/` | Executing with subagents |
| `tdd/` | Implementing any feature or bugfix |
| `debug/` | Any bug, test failure, or unexpected behavior |
| `verification/` | About to claim work is complete |
| `finishing-branch/` | Ready to merge/PR |
| `requesting-review/` | Need code review |
| `receiving-review/` | Got review feedback |
| `dispatching-parallel-agents/` | 2+ independent problems to solve |
| `self-improvement/` | Agent made a mistake, or user says "reflect" |

### Skills (17)

| Skill | What |
|-------|------|
| `nextjs-app-router/` | Next.js App Router |
| `nestjs/` | NestJS modular backend |
| `fastapi/` | FastAPI Python backend |
| `turborepo/` | Turborepo monorepo |
| `prisma-database/` | Prisma ORM |
| `drizzle-database/` | Drizzle ORM |
| `stripe-payments/` | Stripe checkout, webhooks, refunds |
| `error-handling/` | Error handling across frameworks |
| `input-validation/` | Validation (Zod, class-validator, Pydantic) |
| `data-fetching/` | Data fetching patterns |
| `state-management/` | Client state management |
| `email-notifications/` | Transactional email |
| `security-hardening/` | Security best practices |
| `seo-performance/` | SEO and performance |
| `mobile-ux/` | Mobile UX patterns |
| `timezone-safety/` | Timezone handling |
| `deployment-vercel/` | Vercel deployment |

### Domains (3)

| Domain | Sub-skills | What |
|--------|-----------|------|
| `booking/` | 6 + refs | Appointment/service booking |
| `ecommerce/` | 6 + refs | Online store |
| `chatbot/` | 6 + refs | AI chatbot (LLM, RAG, tools) |

---

## Adding New Content

### New workflow skill
1. Create `.ai-skills/docs/workflows/my-skill/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Add `<HARD-GATE>` with dual enforcement (XML + bold ⛔)
4. Add to `docs/ROUTER.md` workflow table
5. Keep under 500 lines

### New framework skill
1. Create `.ai-skills/docs/skills/my-skill/SKILL.md`
2. Add YAML frontmatter with negative triggers
3. Add to `docs/ROUTER.md` skills table
4. Keep under 500 lines

### New domain
1. Create `.ai-skills/docs/domains/my-domain/SKILL.md` (orchestrator)
2. Create sub-skills in `skills/` subdirectory
3. Add to `docs/ROUTER.md` domain commands table

---

## Compatibility

| Agent | How | Status |
|-------|-----|--------|
| **Antigravity** | Reads `AGENTS.md` at root | ✅ |
| **Claude Code** | Reads `CLAUDE.md` → symlink → `AGENTS.md` | ✅ |
| **OpenCode** | Reads `AGENTS.md` | ✅ |
| **Codex** | Reads `AGENTS.md` | ✅ |
| **Cursor** | Reads `.cursorrules` → symlink → `AGENTS.md` | ✅ |

All HARD-GATEs use dual enforcement (`<HARD-GATE>` XML + bold ⛔ text) for cross-model compatibility.
