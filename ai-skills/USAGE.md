# AI-Skills Library — Usage Guide

## What This Is

A portable knowledge base you copy into client projects so AI coding agents (Antigravity, Claude Code, OpenCode, CommandCode, Codex) immediately follow your engineering workflows, know your domain patterns, and use the right framework conventions.

## Quick Start

### Option A: Install script (recommended)

```bash
# From your project root
curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh | bash
```

This will:
- Copy `docs/`, `AGENTS.md`, `USAGE.md` into your project
- Create symlinks (`CLAUDE.md → AGENTS.md`, `.cursorrules → AGENTS.md`)
- Save an update script to `scripts/ai-skills-update.sh`

### Option B: npx skills (if using skills CLI)

```bash
npx skills add https://github.com/signordemola/prompts/tree/main/ai-skills
```

### Option C: Manual copy

```bash
git clone https://github.com/signordemola/prompts.git /tmp/prompts
cp -r /tmp/prompts/ai-skills/docs ./docs
cp /tmp/prompts/ai-skills/AGENTS.md ./AGENTS.md
ln -s AGENTS.md CLAUDE.md
rm -rf /tmp/prompts
```

### Result

Your project should now have:
```
your-project/
├── AGENTS.md          ← All agents read this (rules + "read ROUTER.md")
├── CLAUDE.md          ← Symlink → AGENTS.md (for Claude Code)
├── docs/
│   ├── ROUTER.md      ← Central index — agents read this first
│   ├── workflows/     ← HOW to work (11 workflow skills)
│   ├── skills/        ← WHAT tools to use (17 framework/library skills)
│   ├── domains/       ← WHAT to build (3 domain knowledge bases)
│   └── references/    ← Deep reference docs
├── scripts/
│   └── ai-skills-update.sh  ← Run this to update later
└── ... your code
```

When any AI agent opens the project, the chain is:
```
Agent reads AGENTS.md
  → Rule 0: "Read docs/ROUTER.md"
    → ROUTER.md: "Match task to workflow skill, load it"
      → Skill enforces behavior
```

---

## How It Works

### The Three Layers

| Layer | Path | Purpose | When Loaded |
|-------|------|---------|-------------|
| **Workflows** | `docs/workflows/` | Engineering process (brainstorm → plan → build → verify → ship) | When task matches trigger |
| **Skills** | `docs/skills/` | Framework & library patterns (Next.js, NestJS, Prisma, Stripe, etc.) | When project uses that tech |
| **Domains** | `docs/domains/` | Business logic (booking, ecommerce, chatbot) | When project is in that vertical |

### The Workflow Pipeline

Every non-trivial task follows this pipeline:

```
brainstorming → plan → executing-plans (or SDD) → verification → finishing-branch
```

- **brainstorming** — design before code
- **plan** — decompose into tasks
- **executing-plans** — implement task by task (single agent)
- **subagent-driven-development** — implement with subagents (multi-agent)
- **tdd** — red-green-refactor per task
- **verification** — prove it works with evidence
- **finishing-branch** — merge/PR/cleanup

Supporting workflows: `debug`, `requesting-review`, `receiving-review`, `dispatching-parallel-agents`

### Context Loading (Tiered)

Agents don't read everything — they use tiered loading to avoid context overload:

| Tier | When | Example |
|------|------|---------|
| **Always** | Loaded by Rule 0 | ROUTER.md |
| **Match task** | Task matches a workflow trigger | "Fix this bug" → debug workflow |
| **Match project** | Project uses this stack/domain | Next.js project → nextjs-app-router skill |
| **On reference** | Skill says "read this reference" | debug → references/root-cause-tracing.md |

---

## Directory Reference

### Workflows (11)

| Skill | Trigger |
|-------|---------|
| `brainstorming/` | Starting any new feature or creative work |
| `plan/` | Decomposing spec into implementation tasks |
| `executing-plans/` | Executing a plan task-by-task (no subagents) |
| `subagent-driven-development/` | Executing with subagents |
| `tdd/` | Implementing any feature or bugfix |
| `debug/` | Any bug, test failure, or unexpected behavior |
| `verification/` | About to claim work is complete |
| `finishing-branch/` | Ready to merge/PR |
| `requesting-review/` | Need code review |
| `receiving-review/` | Got review feedback |
| `dispatching-parallel-agents/` | 2+ independent problems to solve |

### Skills (17)

| Skill | What |
|-------|------|
| `nextjs-app-router/` | Next.js App Router patterns |
| `nestjs/` | NestJS modular backend |
| `fastapi/` | FastAPI Python backend |
| `turborepo/` | Turborepo monorepo setup |
| `prisma-database/` | Prisma ORM patterns |
| `drizzle-database/` | Drizzle ORM patterns |
| `stripe-payments/` | Stripe checkout, webhooks, refunds |
| `error-handling/` | Error handling across frameworks |
| `input-validation/` | Validation patterns (Zod, class-validator, Pydantic) |
| `data-fetching/` | Data fetching patterns |
| `state-management/` | Client state management |
| `email-notifications/` | Transactional email |
| `security-hardening/` | Security best practices |
| `seo-performance/` | SEO and performance optimization |
| `mobile-ux/` | Mobile UX patterns |
| `timezone-safety/` | Timezone handling |
| `deployment-vercel/` | Vercel deployment |

### Domains (3)

| Domain | Sub-skills | What |
|--------|-----------|------|
| `booking/` | 6 sub-skills + references | Appointment/service booking (beauty, wellness, events) |
| `ecommerce/` | 6 sub-skills + references | Online store (products, cart, checkout, orders) |
| `chatbot/` | 6 sub-skills + references | AI chatbot (LLM, RAG, tool calling, conversation) |

### References (5)

| Reference | What |
|-----------|------|
| `root-cause-tracing.md` | Backward tracing for debugging |
| `testing-anti-patterns.md` | Mock traps and test quality |
| `defense-in-depth.md` | Multi-layer validation patterns |
| `migration-patterns.md` | Database migration workflows |
| `api-design.md` | REST conventions across frameworks |

---

## How to Update

### Update everything (from GitHub)

```bash
bash scripts/ai-skills-update.sh
```

This fetches the latest from GitHub, replaces `docs/`, updates `AGENTS.md`, and backs up any local customizations.

### Partial updates

Update only what you need:

```bash
# All workflow skills
bash scripts/ai-skills-update.sh --only workflows

# All framework/library skills
bash scripts/ai-skills-update.sh --only skills

# All domain knowledge
bash scripts/ai-skills-update.sh --only domains

# Single domain
bash scripts/ai-skills-update.sh --only domains/booking

# Single skill
bash scripts/ai-skills-update.sh --only skills/stripe-payments

# Just the references
bash scripts/ai-skills-update.sh --only references

# Just ROUTER.md
bash scripts/ai-skills-update.sh --only router

# Just AGENTS.md + symlinks
bash scripts/ai-skills-update.sh --only agents
```

### Re-install the update script itself

If you lose `scripts/ai-skills-update.sh`:

```bash
curl -sSL https://raw.githubusercontent.com/signordemola/prompts/main/ai-skills/install.sh \
  -o scripts/ai-skills-update.sh && chmod +x scripts/ai-skills-update.sh
```

---

## How to Add New Content

### Add a new workflow skill

1. Create `docs/workflows/my-skill/SKILL.md`
2. Add YAML frontmatter with `name` and `description` (include trigger conditions)
3. Add Iron Law + `<HARD-GATE>` with dual enforcement (XML + bold ⛔ text)
4. Add `announce at start` pattern
5. Add the skill to `docs/ROUTER.md` workflow table
6. Keep under 500 lines

### Add a new framework/library skill

1. Create `docs/skills/my-skill/SKILL.md`
2. Add YAML frontmatter — include negative triggers (when NOT to use)
3. Add to `docs/ROUTER.md` invocable skills table
4. Keep under 500 lines — move deep docs to `references/`

### Add a new domain

1. Create `docs/domains/my-domain/SKILL.md` (orchestrator)
2. Create sub-skills in `docs/domains/my-domain/skills/`
3. Create references in `docs/domains/my-domain/references/`
4. Add prerequisites (database + framework skill loading)
5. Add to `docs/ROUTER.md` domain commands table

### Add a new reference

1. Create `docs/references/my-reference.md`
2. No YAML frontmatter needed (references aren't skills)
3. Add to `docs/ROUTER.md` companion references list
4. Link from relevant skills

---

## How to Fix Mistakes

When an agent does something wrong despite the library:

1. **Identify which skill should have caught it** — was there a relevant workflow/domain skill?
2. **If the skill exists but wasn't followed** — check the `description` field in YAML frontmatter. The trigger conditions might not match the task. Refine them.
3. **If the skill exists but is wrong** — update the specific pattern, code example, or rule. Add a `NEVER` entry if the mistake is common.
4. **If no skill covers it** — create a new skill or add a `NEVER` section to the closest existing skill.
5. **If the agent never read ROUTER.md** — check that `AGENTS.md` is at the project root and the agent tool recognizes it.

**Golden rule:** Every mistake the agent makes should result in a library update. Don't just fix the code — fix the instruction that would have prevented it.

---

## Compatibility

| Tool | Reads From | Status |
|------|-----------|--------|
| **Antigravity** | `AGENTS.md` | ✅ Native |
| **Claude Code** | `CLAUDE.md` → symlink → `AGENTS.md` | ✅ Via symlink |
| **OpenCode** | `AGENTS.md` | ✅ Native |
| **CommandCode** | `AGENTS.md` | ✅ Native |
| **Codex (OpenAI)** | `AGENTS.md` | ✅ Native |
| **Cursor** | `.cursorrules` | ⚠️ Create symlink: `ln -s AGENTS.md .cursorrules` |
| **GitHub Copilot** | `.github/copilot-instructions.md` | ⚠️ Create symlink |
| **Aider** | `read: AGENTS.md` in `.aider.conf.yml` | ⚠️ Needs config |

### Cross-Model Enforcement

The library uses dual enforcement to work across different AI models:

```markdown
<HARD-GATE>
**⛔ MANDATORY GATE — THE NATURAL LANGUAGE VERSION.**
The detailed instruction that all models can understand.
</HARD-GATE>
```

- **Claude-family models** respond to `<HARD-GATE>` XML tags as strong directives
- **Other models** (GPT, Gemini) respond to the bold ⛔ natural language inside
- Both get the message regardless of which signal they're tuned to
