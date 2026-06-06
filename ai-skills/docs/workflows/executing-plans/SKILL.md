---
name: executing-plans
description: "Use when executing an implementation plan task-by-task without subagents. The single-agent counterpart to subagent-driven-development."
---

# Executing Plans (Single Agent)

Execute an approved implementation plan yourself, task by task, with the same quality bar as subagent-driven-development.

**Announce at start:** "I'm using the executing-plans workflow to implement this plan."

## The Iron Law

```
NO TASK SKIPPING — COMPLETE EACH TASK BEFORE STARTING THE NEXT
```

<HARD-GATE>
**⛔ MANDATORY GATE — DO NOT SKIP TASKS OR REORDER WITHOUT EXPLICIT USER APPROVAL.**
Each task must be implemented, tested, self-reviewed, and committed before moving to the next. "I'll come back to it" is not acceptable.
</HARD-GATE>

## When to Use

- You have an approved implementation plan with ordered tasks
- Subagents are NOT available (use `subagent-driven-development` if they are)
- Same plan, same quality bar — you just do it yourself

## The Process

### Step 1: Load and Prepare

1. Read the plan file completely
2. Extract ALL tasks with their full descriptions
3. Create a progress checklist
4. Load the relevant domain skill (`/booking`, `/ecom`, `/chat`) and framework skill (`/next`, `/nest`, `/fastapi`)

### Step 2: Per-Task Cycle

For EACH task in the plan:

**2a. Implement**
- Read the task description fully
- Follow TDD: write failing test → minimal code → refactor
- If the plan specifies TDD, invoke the `tdd` workflow

**2b. Self-Review Checklist**

Since you don't have a reviewer subagent, you MUST self-review honestly:

<Good>
```
✅ Spec compliance: Does my code do exactly what the task asked?
✅ Edge cases: Did I handle the edge cases mentioned in the spec?
✅ Test coverage: Do my tests verify real behavior (not mocks)?
✅ Code quality: Clean separation, proper error handling, DRY?
✅ No extras: Did I add anything NOT in the spec? Remove it.
```
</Good>

<Bad>
```
❌ "Looks good to me" — without checking each item
❌ "Tests pass so it's fine" — passing tests ≠ correct implementation
❌ "I'll clean it up later" — later never comes
```
</Bad>

**2c. Commit**

```bash
git add -A && git commit -m "feat: [task name] — [what was implemented]"
```

**2d. Mark Done**

Update your progress checklist. Move to next task without pausing.

<HARD-GATE>
**⛔ MANDATORY — DO NOT ASK "Should I continue?" BETWEEN TASKS.**
The user asked you to execute the plan. Execute it. The only reasons to stop: BLOCKED status, genuine ambiguity, or all tasks complete.
</HARD-GATE>

### Step 3: Final Verification

After ALL tasks are complete:

1. Run the full test suite — not just individual task tests
2. Invoke the `verification` workflow
3. Invoke the `finishing-branch` workflow

## Framework-Specific Test Commands

| Framework | Run tests | Lint / Typecheck |
|-----------|----------|-----------------|
| **Next.js** | `npx vitest run` | `npx -y react-doctor@latest .` |
| **NestJS** | `npx jest --passWithNoTests` | `npx tsc --noEmit` |
| **FastAPI** | `uv run pytest -xvs` | `uv run ruff check . && uv run pyright app` |

## vs. Subagent-Driven Development

| | Executing Plans | SDD |
|---|---|---|
| **Agent count** | 1 (you) | Multiple subagents |
| **Review** | Self-review checklist | Dedicated reviewer subagents |
| **Context** | Accumulates across tasks | Fresh per task |
| **Speed** | Sequential | Parallel possible |
| **Quality bar** | Same | Same |

Use SDD when subagents are available. Use this when they're not. Never lower the quality bar.
