---
name: plan
description: "Use when you have a spec or requirements for a multi-step task, before touching code"
---

# Writing Plans

Write comprehensive implementation plans assuming the engineer has zero context and questionable taste. Document everything: which files to touch, code patterns, how to test. Bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the plan workflow to create the implementation plan."

## The Iron Law

```
NO CODE WITHOUT A PLAN FOR NON-TRIVIAL WORK
```

<HARD-GATE>
Do not write implementation code until the plan is written and the user has approved it. Trivial changes (typo fix, config tweak) are exempt. Everything else gets a plan.
</HARD-GATE>

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Step 1: File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for.

- Design units with clear boundaries and well-defined interfaces
- Each file should have one clear responsibility
- Prefer smaller, focused files over large ones
- Files that change together should live together
- In existing codebases, follow established patterns

This structure informs the task decomposition. Each task should produce self-contained changes.

## Step 2: Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**

<Good>
- "Write the failing test for slot validation" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step
</Good>

<Bad>
- "Implement the booking system" — too big
- "Write tests and implementation" — two things
- "Set up the database, models, and API" — three things
</Bad>

## Step 3: Plan Document Format

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use subagent-driven-development (if subagents available)
> or executing-plans to implement this plan task-by-task.

## File Structure
[Which files will be created/modified and why]

## Tasks

### Task 1: [Name]
- [ ] Step 1: Write failing test for X
- [ ] Step 2: Run test, confirm it fails
- [ ] Step 3: Implement minimal code
- [ ] Step 4: Run tests, confirm pass
- [ ] Step 5: Commit

### Task 2: [Name]
...
```

## Step 4: Save and Review

- Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`
- Present to user for approval
- If feedback changes scope, update the plan

## Step 5: Hand Off

After user approves:
- Invoke `subagent-driven-development` workflow (if subagents available)
- OR invoke `executing-plans` workflow (if no subagents)

**Load the appropriate domain skill** (`/booking`, `/ecom`, `/chat`) for domain-specific patterns.
**Load the appropriate framework skill** (`/next`, `/nest`, `/fastapi`) for framework-specific patterns.
