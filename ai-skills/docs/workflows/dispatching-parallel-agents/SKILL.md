---
name: dispatching-parallel-agents
description: "Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies. Don't use when failures might be related or agents would edit the same files."
---

# Dispatching Parallel Agents

When you have multiple unrelated problems, investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Announce at start:** "I'm using the dispatching-parallel-agents workflow to solve these independently."

## The Iron Law

```
NO PARALLEL DISPATCH WITHOUT VERIFIED INDEPENDENCE
```

<HARD-GATE>
**⛔ MANDATORY GATE — VERIFY INDEPENDENCE BEFORE DISPATCHING.**
Each agent MUST work on different files. If two agents would touch the same file, they are NOT independent — combine them into one sequential task.
</HARD-GATE>

## When to Use

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures might be related (fix one might fix others)
- Need to understand full system state first
- Agents would edit the same files

## The Process

### Step 1: Identify Independent Domains

Group failures by what's broken:
- File A tests: Authentication flow
- File B tests: Payment processing
- File C tests: Email notifications

Each domain is independent — fixing auth doesn't affect email tests.

### Step 2: Declare File Boundaries

Before dispatching, explicitly list which files each agent owns:

```
Agent 1: OWNS src/auth/*, tests/auth/*
Agent 2: OWNS src/payments/*, tests/payments/*
Agent 3: OWNS src/email/*, tests/email/*
SHARED (read-only): src/config/*, src/types/*
```

<Good>
```
Agent 1 scope: "Fix auth tests. You may ONLY modify files in src/auth/ and tests/auth/. 
Read but do NOT modify shared config files."
```
</Good>

<Bad>
```
Agent 1 scope: "Fix the auth stuff"
— No file boundaries, agent might refactor shared code
```
</Bad>

### Step 3: Dispatch with Structured Prompts

Each agent gets this template:

```
You are a focused debugging agent. Your ONLY task:

## Objective
{what to fix — be specific}

## Your File Scope
MODIFY: {list of files/dirs this agent may change}
READ ONLY: {shared files it may read but not edit}

## Context
{relevant background — errors, recent changes, architecture notes}

## Success Criteria
- All tests in {test files} pass
- No changes outside your file scope
- Summary of root cause and fix

## Constraints
- Do NOT modify files outside your scope
- Do NOT refactor code unrelated to the fix
- If you discover the issue is in a shared file, STOP and report back
```

### Step 4: Collect and Merge

After all agents complete:

```bash
# Check for file conflicts
git diff --name-only agent-1..main
git diff --name-only agent-2..main
# If overlap → resolve manually before merging
```

- Review each agent's changes for conflicts
- Run **full** test suite (not just each agent's tests)
- If conflicts exist: resolve manually, don't re-dispatch
- If all clean: merge and verify

### Step 5: Handle Failures

| Scenario | Action |
|----------|--------|
| Agent fails, issue is in its scope | Retry with more context |
| Agent fails, issue is in shared code | Pull back, investigate sequentially |
| Two agents' fixes conflict | Combine into one sequential task |
| Agent succeeds but breaks other tests | Its fix has side effects — investigate dependency |
