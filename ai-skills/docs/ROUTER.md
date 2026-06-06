---
name: using-workflows
description: "Use when starting any conversation - establishes how to find and use workflow skills, requiring skill invocation before ANY response"
---

# Using Workflows

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
**⛔ MANDATORY: If a workflow skill matches your current task, you MUST read and follow it.**

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## Priority Order

1. **User's explicit instructions** (AGENTS.md, direct requests) — highest priority
2. **Workflow skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

If AGENTS.md says "don't use TDD" and a skill says "always use TDD," follow the user's instructions.

## Skill Index

> **Path note:** All paths below are relative to this file's directory. If this file is at `docs/ai-skills/ROUTER.md`, then `workflows/tdd/SKILL.md` means `docs/ai-skills/workflows/tdd/SKILL.md`.

### Workflow Skills (HOW you work)

| Skill | Location | Use When |
|-------|----------|----------|
| **brainstorming** | `workflows/brainstorming/SKILL.md` | Starting any creative work — features, components, functionality |
| **plan** | `workflows/plan/SKILL.md` | You have a spec and need to decompose into tasks |
| **tdd** | `workflows/tdd/SKILL.md` | Implementing any feature or bugfix |
| **debug** | `workflows/debug/SKILL.md` | Any bug, test failure, or unexpected behavior |
| **executing-plans** | `workflows/executing-plans/SKILL.md` | Executing plans task-by-task (no subagents) |
| **subagent-driven-development** | `workflows/subagent-driven-development/SKILL.md` | Executing plans with independent tasks (subagents available) |
| **verification** | `workflows/verification/SKILL.md` | About to claim work is complete or passing |
| **finishing-branch** | `workflows/finishing-branch/SKILL.md` | Implementation complete, ready to integrate |
| **requesting-review** | `workflows/requesting-review/SKILL.md` | Completed a task or feature, need review |
| **receiving-review** | `workflows/receiving-review/SKILL.md` | Got review feedback, before implementing |
| **dispatching-parallel-agents** | `workflows/dispatching-parallel-agents/SKILL.md` | 2+ independent problems to solve concurrently |
| **self-improvement** | `workflows/self-improvement/SKILL.md` | Agent made a mistake, hit a gap, or discovered a new pattern |
| **recovery** | `workflows/recovery/SKILL.md` | Something went wrong — diagnose failure mode before fixing |

### Domain Skills (WHAT you're building)

| Command | Skill | Use When |
|---------|-------|----------|
| `/booking` | `domains/booking/SKILL.md` | Appointments, slots, availability, deposits |
| `/ecom` | `domains/ecommerce/SKILL.md` | Products, carts, checkout, inventory |
| `/chat` | `domains/chatbot/SKILL.md` | Conversational AI, knowledge bases, RAG |

### Framework Skills (HOW you build it)

| Command | Skill | Use When |
|---------|-------|----------|
| `/next` | `skills/nextjs-app-router/SKILL.md` | Next.js App Router projects |
| `/style` | `skills/code-style/SKILL.md` | Writing or editing project source code |
| `/nest` | `skills/nestjs/SKILL.md` | NestJS modular backend |
| `/fastapi` | `skills/fastapi/SKILL.md` | FastAPI Python backend |
| `/turbo` | `skills/turborepo/SKILL.md` | Turborepo monorepo setup |
| `/drizzle` | `skills/drizzle-database/SKILL.md` | Drizzle ORM (alternative to Prisma) |
| `/invoice` | `skills/invoicing/SKILL.md` | Invoice generation, PDF, deposits, tax |
| `/subdomain` | `skills/subdomain-architecture/SKILL.md` | Subdomain booking systems, multi-tenant, white-label |
| `/files` | `skills/client-file-delivery/SKILL.md` | Secure file delivery, signed URLs, R2/S3, galleries |
| `/ui-check` | `skills/ui-consistency/SKILL.md` | After building UI — capture patterns to ui-registry.md |
| `/tailwind` | `skills/tailwind-css/SKILL.md` | Tailwind CSS v4 — @theme, CSS-first config |
| `/shadcn` | `skills/shadcn-ui/SKILL.md` | shadcn/ui components, presets, theming |
| `/form` | `skills/react-hook-form/SKILL.md` | Forms with React Hook Form + Zod |
| `/upload` | `skills/uploadthing/SKILL.md` | File uploads with Uploadthing v7 |
| `/e2e` | `skills/playwright/SKILL.md` | E2E testing with Playwright |
| `/hono` | `skills/hono/SKILL.md` | Hono API framework — edge, multi-runtime |
| `/scripts` | `skills/project-scripts/SKILL.md` | predev, prebuild, Husky, lint, typecheck, CI |

## The Workflow Pipeline

```
User request
    ↓
brainstorming (refine requirements, write spec)
    ↓
plan (decompose into bite-sized tasks)
    ↓
┌─────────────────────────────────────────┐
│  IF subagents available:                │
│    subagent-driven-development          │
│      ├── tdd (per task)                 │
│      ├── requesting-review (per task)   │
│      └── receiving-review (per task)    │
│  ELSE:                                  │
│    executing-plans                      │
│      └── tdd (per task, self-review)    │
└─────────────────────────────────────────┘
    ↓
verification (prove it works with evidence)
    ↓
finishing-branch (merge/PR/cleanup)
```

## Context Loading Rules

**Read and follow relevant skills BEFORE any response or action.** Use this tiered approach to avoid context overload:

| Tier | When to load | Examples |
|------|-------------|----------|
| **Always** | Loaded via AGENTS.md Rule 0 | This file (ROUTER.md) |
| **Match task** | Task clearly matches a workflow trigger | brainstorming, plan, tdd, debug |
| **Match project** | Project uses this domain/framework | booking, ecom, Next.js, NestJS |
| **On reference** | A skill explicitly tells you to read it | references/root-cause-tracing.md |

## Companion References

Deep reference files live in `references/`:
- `root-cause-tracing.md` — backward tracing for debugging
- `testing-anti-patterns.md` — mock traps and test quality
- `defense-in-depth.md` — multi-layer validation patterns
- `migration-patterns.md` — database migration workflows
- `api-design.md` — REST conventions across frameworks

Deep domain knowledge lives in `domains/booking/references/`, `domains/ecommerce/references/`, `domains/chatbot/references/`.
